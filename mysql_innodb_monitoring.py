import streamlit as st
import mysql.connector
import pandas as pd
from streamlit_autorefresh import st_autorefresh
import time

# ---------- DB CONNECTION ----------
def get_connection():
    return mysql.connector.connect(
        host="172.18.163.65",
        user="monitor",
        password="M0n1t0r",
        port=3306
    )

# ---------- QUERY RUNNER ----------
def run_query(query):
    conn = get_connection()
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# ----------- TPS Count----------
def get_tx_count():
    query = """
    SHOW GLOBAL STATUS
    WHERE Variable_name IN ('Com_commit','Com_rollback');
    """
    df = run_query(query)
    return df["Value"].astype(int).sum()

# ---------- UI ----------
st.set_page_config(page_title="InnoDB Cluster Monitor", layout="wide")
st.title("🛡️ MySQL InnoDB Cluster Monitoring")

# ---------- CLUSTER MEMBERS ----------
st.subheader("📡 Cluster Members")

members_query = """
SELECT MEMBER_HOST, MEMBER_PORT, MEMBER_STATE, MEMBER_ROLE
FROM performance_schema.replication_group_members;
"""

members_df = run_query(members_query)

st.dataframe(members_df, use_container_width=True)

# ---------- HEALTH STATUS ----------
online_nodes = members_df[members_df["MEMBER_STATE"] == "ONLINE"].shape[0]
total_nodes = members_df.shape[0]

st.metric("Online Nodes", online_nodes, f"/ {total_nodes}")

# ---------- PRIMARY NODE ----------
primary = members_df[members_df["MEMBER_ROLE"] == "PRIMARY"]["MEMBER_HOST"].values
if len(primary) > 0:
    st.success(f"PRIMARY Node: {primary[0]}")
else:
    st.error("No PRIMARY node detected!")

# ---------- AUTO REFRESH ----------
#st.caption("⏱ Auto-refresh every 10 seconds")
#st.experimental_rerun()

st.caption("⏱ Auto-refresh every 10 seconds")
st_autorefresh(interval=10000, key="innodb_refresh")
