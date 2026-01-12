import streamlit as st
import mysql.connector
import pandas as pd
import psutil
import time
from datetime import datetime
from streamlit_autorefresh import st_autorefresh
import plotly.express as px

# ------------------ STREAMLIT CONFIG ------------------
st.set_page_config(
    page_title="MySQL InnoDB Cluster Monitor",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ------------------ DARK MODE CSS ------------------
st.markdown("""
<style>
body { background-color: #0e1117; color: white; }
[data-testid="metric-container"] {
    background-color: #1f2933;
    padding: 15px;
    border-radius: 10px;
}
</style>
""", unsafe_allow_html=True)

# ------------------ DB CONFIG ------------------
# Read-only monitoring user
DB_CONFIG = {
    "host": "172.18.163.65",
    "user": "monitor",
    "password": "M0n1t0r",
    "database": "performance_schema"
}

# Admin user for manual failover
FAILOVER_DB_CONFIG = {
    "host": "172.18.163.65",
    "user": "failover_admin",
    "password": "StrongPassword123!",
    "database": "performance_schema"
}

# ------------------ DB HELPERS ------------------
def get_connection():
    return mysql.connector.connect(**DB_CONFIG)

def run_query(query):
    conn = get_connection()
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# ------------------ CLUSTER ------------------
def get_cluster_members():
    query = """
    SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE
    FROM performance_schema.replication_group_members;
    """
    return run_query(query)

# ------------------ FAILOVER COMMAND ------------------
def manual_failover(target):
    try:
        conn = mysql.connector.connect(**FAILOVER_DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute(
            f"SELECT group_replication_set_as_primary('{target}')"
        )
        conn.commit()
        cursor.close()
        conn.close()
        return True
    except Exception as e:
        st.error(e)
        return False

# ------------------ SYSTEM USAGE (LOCAL NODE) ------------------
def get_system_usage():
    cpu = psutil.cpu_percent(interval=1)
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    return cpu, mem, disk

# ------------------ TPS ------------------
def get_tx_count():
    df = run_query("""
    SHOW GLOBAL STATUS
    WHERE Variable_name IN ('Com_commit','Com_rollback')
    """)
    return df["Value"].astype(int).sum()

# ------------------ SESSION STATE INIT ------------------
for k, v in {
    "last_primary": None,
    "failover_events": [],
    "last_tx": None,
    "last_time": None,
    "tps_data": []
}.items():
    if k not in st.session_state:
        st.session_state[k] = v

# ------------------ SIDEBAR ------------------
st.sidebar.title("⚙️ Controls")
refresh = st.sidebar.slider("Refresh Interval (sec)", 5, 30, 10)
st.sidebar.info("MySQL InnoDB Cluster\nMonitoring Dashboard")

# ------------------ AUTO REFRESH ------------------
st_autorefresh(interval=refresh * 1000, key="refresh")

# ------------------ DASHBOARD ------------------
st.title("🛡️ MySQL InnoDB Cluster Monitoring")

# ---------- CLUSTER MEMBERS ----------
members_df = get_cluster_members()
st.subheader("📡 Cluster Members")
st.dataframe(members_df, use_container_width=True)

# ---------- PRIMARY DETECTION ----------
primary_rows = members_df[members_df["MEMBER_ROLE"] == "PRIMARY"]
current_primary = primary_rows.iloc[0]["MEMBER_HOST"] if not primary_rows.empty else None

st.subheader("👑 Current PRIMARY")
if current_primary:
    st.success(f"PRIMARY → {current_primary}")
else:
    st.error("❌ No PRIMARY detected")

# ---------- FAILOVER DETECTION ----------
if st.session_state.last_primary and current_primary != st.session_state.last_primary:
    st.session_state.failover_events.append({
        "time": datetime.now(),
        "event": "PRIMARY_FAILOVER",
        "from": st.session_state.last_primary,
        "to": current_primary
    })
    st.balloons()

st.session_state.last_primary = current_primary

# Offline nodes
offline = members_df[members_df["MEMBER_STATE"] != "ONLINE"]
for _, r in offline.iterrows():
    event = {
        "time": datetime.now(),
        "event": "NODE_OFFLINE",
        "from": r["MEMBER_HOST"],
        "to": None
    }
    if event not in st.session_state.failover_events:
        st.session_state.failover_events.append(event)

# ---------- FAILOVER TIMELINE ----------
st.subheader("📊 Failover Timeline")

if st.session_state.failover_events:
    df = pd.DataFrame(st.session_state.failover_events)
    df["label"] = df.apply(
        lambda x: f"{x['event']}<br>{x['from']} → {x['to']}" if x["to"]
        else f"{x['event']}<br>{x['from']}",
        axis=1
    )
    df["y"] = 1

    fig = px.scatter(
        df, x="time", y="y",
        text="label", color="event"
    )
    fig.update_yaxes(visible=False)
    fig.update_traces(marker=dict(size=14), textposition="top center")
    st.plotly_chart(fig, use_container_width=True)
else:
    st.info("No failover events yet")

# ---------- RESOURCE USAGE ----------
st.subheader("🖥️ PRIMARY Node Resource Usage (Local)")
cpu, mem, disk = get_system_usage()
c1, c2, c3 = st.columns(3)
c1.metric("CPU", f"{cpu}%")
c2.metric("RAM", f"{mem.percent}%")
c3.metric("Disk", f"{disk.percent}%")

# ---------- SERVER MODES ----------
st.subheader("🔐 Server Modes")
for _, r in members_df.iterrows():
    if r["MEMBER_ROLE"] == "PRIMARY":
        st.success(f"{r['MEMBER_HOST']} → READ_WRITE")
    else:
        st.info(f"{r['MEMBER_HOST']} → READ_ONLY")

# ---------- TPS ----------
current_tx = get_tx_count()
now = time.time()

if st.session_state.last_tx:
    tps = round(
        (current_tx - st.session_state.last_tx) /
        (now - st.session_state.last_time), 2
    )
    st.session_state.tps_data.append(tps)

st.session_state.last_tx = current_tx
st.session_state.last_time = now
st.session_state.tps_data = st.session_state.tps_data[-50:]

st.subheader("📈 TPS")
if st.session_state.tps_data:
    st.line_chart(pd.DataFrame(st.session_state.tps_data, columns=["TPS"]))
else:
    st.info("Collecting TPS data…")

