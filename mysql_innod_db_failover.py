import streamlit as st
import pandas as pd
import time
from datetime import datetime
from streamlit_autorefresh import st_autorefresh
import mysql.connector

# ---------- DB CONNECTION ----------
def get_connection():
    return mysql.connector.connect(
        host="172.18.163.65",
        user="monitor",
        password="M0n1t0r",
        port=3306
    )

def run_query(query):
    conn = get_connection()
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# ---------- Cluster & TPS Helpers ----------
def get_cluster_members():
    query = """
    SELECT MEMBER_HOST, MEMBER_STATE, MEMBER_ROLE
    FROM performance_schema.replication_group_members;
    """
    return run_query(query)

def get_tx_count():
    query = """
    SHOW GLOBAL STATUS
    WHERE Variable_name IN ('Com_commit','Com_rollback');
    """
    df = run_query(query)
    return df["Value"].astype(int).sum()

# ---------- SESSION STATE ----------
if "tps_data" not in st.session_state:
    st.session_state.tps_data = []

if "last_tx" not in st.session_state:
    st.session_state.last_tx = None

if "last_time" not in st.session_state:
    st.session_state.last_time = None

if "last_primary" not in st.session_state:
    st.session_state.last_primary = None

if "failover_events" not in st.session_state:
    st.session_state.failover_events = []

# ---------- AUTO-REFRESH ----------
st_autorefresh(interval=5000, key="refresh")  # every 5 sec

# ---------- STREAMLIT UI ----------
st.set_page_config(page_title="InnoDB Cluster Monitor", layout="wide")
st.title("🛡️ MySQL InnoDB Cluster Monitoring")

# ---------- CLUSTER MEMBERS ----------
members_df = get_cluster_members()
st.subheader("📡 Cluster Members")
st.dataframe(members_df, use_container_width=True)

# ---------- FAILOVER DETECTION ----------
current_primary = None
primary_rows = members_df[members_df["MEMBER_ROLE"] == "PRIMARY"]
if not primary_rows.empty:
    current_primary = primary_rows.iloc[0]["MEMBER_HOST"]

# Failover detection
if st.session_state.last_primary and current_primary != st.session_state.last_primary:
    event = {
        "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "Event": "PRIMARY FAILOVER",
        "Details": f"{st.session_state.last_primary} → {current_primary}"
    }
    st.session_state.failover_events.append(event)

st.session_state.last_primary = current_primary

# Offline nodes
offline_nodes = members_df[members_df["MEMBER_STATE"] != "ONLINE"]
for _, row in offline_nodes.iterrows():
    event = {
        "Time": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "Event": "NODE OFFLINE",
        "Details": row["MEMBER_HOST"]
    }
    if event not in st.session_state.failover_events:
        st.session_state.failover_events.append(event)

# Health Banner
st.subheader("🚨 Cluster Health")
if offline_nodes.empty:
    st.success("✅ All nodes ONLINE")
else:
    st.error("❌ One or more nodes are OFFLINE")

# Current PRIMARY
st.subheader("👑 Current PRIMARY")
if current_primary:
    st.success(f"PRIMARY Node: {current_primary}")
else:
    st.error("🚨 No PRIMARY detected!")

# Failover / Incident History
st.subheader("📜 Failover & Incident History")
if st.session_state.failover_events:
    st.dataframe(pd.DataFrame(st.session_state.failover_events), use_container_width=True)
else:
    st.info("No failover events detected yet.")

# ---------- TPS CALCULATION ----------
current_tx = get_tx_count()
current_time = time.time()

if st.session_state.last_tx is not None:
    tx_diff = current_tx - st.session_state.last_tx
    time_diff = current_time - st.session_state.last_time
    tps = round(tx_diff / time_diff, 2) if time_diff > 0 else 0
    st.session_state.tps_data.append({
        "Time": pd.to_datetime(current_time, unit="s"),
        "TPS": tps
    })

st.session_state.last_tx = current_tx
st.session_state.last_time = current_time

# Keep last 50 points
MAX_POINTS = 50
st.session_state.tps_data = st.session_state.tps_data[-MAX_POINTS:]

# TPS Chart
st.subheader("📈 Transactions Per Second (TPS)")
if len(st.session_state.tps_data) > 1:
    tps_df = pd.DataFrame(st.session_state.tps_data)
    st.line_chart(tps_df.set_index("Time"))
else:
    st.info("Collecting TPS data…")
