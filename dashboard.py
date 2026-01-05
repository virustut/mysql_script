import streamlit as st
import paramiko
import mysql.connector
import pandas as pd
import plotly.express as px
import time

# ----------------------------
# Server configuration
# ----------------------------
servers = {
    "192.168.0.30": {"host": "192.168.0.30", "mysql_user": "dba", "mysql_password": "appl!c@ti0n", "ssh_user": "root", "ssh_password": "Op3nSourc3@875"},
    "192.168.0.33": {"host": "192.168.0.33", "mysql_user": "dba", "mysql_password": "appl!c@ti0n", "ssh_user": "root", "ssh_password": "Op3nSourc3@875"},
    "172.24.11.82": {"host": "172.24.11.82", "mysql_user": "dba", "mysql_password": "Opo@1234", "ssh_user": "root", "ssh_password": "Op3nSourc3@875"},
 
}

# Central monitoring DB
logdb = mysql.connector.connect(
    host="172.24.11.82",
    user="monitoring",
    password="M0nit0r",
    database="monitoring"
)
log_cursor = logdb.cursor()

# ----------------------------
# Streamlit setup
# ----------------------------
st.set_page_config(page_title="MySQL Multi-Server Monitor", layout="wide")
st.title("🚀  MySQL Monitoring Dashboard")
selected_server = st.sidebar.selectbox("Select a Server", list(servers.keys()))
st.sidebar.info("Created BY Ajit Yadav")


# ----------------------------
# Containers for smooth updates
# ----------------------------
metric_container = st.empty()
chart_container = st.empty()

# ----------------------------
# SSH metrics function
# ----------------------------
def get_linux_metrics(host, user, password):
    try:
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(host, username=user, password=password)

        cpu = float(ssh.exec_command("top -bn1 | grep 'Cpu(s)' | awk '{print $2+$4}'")[1].read().decode().strip() or 0)
        ram = float(ssh.exec_command("free | awk '/Mem/ {printf(\"%.2f\", $3/$2*100)}'")[1].read().decode().strip() or 0)
        disk = float(ssh.exec_command("df -h / | tail -1 | awk '{print $5}' | tr -d '%'")[1].read().decode().strip() or 0)
        mysql_cpu = float(ssh.exec_command("ps -C mysqld -o %cpu= | awk '{sum+=$1} END {print sum}'")[1].read().decode().strip() or 0)
        mysql_ram = float(ssh.exec_command("ps -C mysqld -o %mem= | awk '{sum+=$1} END {print sum}'")[1].read().decode().strip() or 0)

        ssh.close()
        return cpu, ram, disk, mysql_cpu, mysql_ram
    except Exception as e:
        st.error(f"SSH Error ({host}): {e}")
        return 0,0,0,0,0

# ----------------------------
# Fetch metrics
# ----------------------------
def fetch_metrics():
    live = {}
    for srv_name, cfg in servers.items():
        try:
            cpu, ram, disk, mysql_cpu, mysql_ram = get_linux_metrics(cfg["host"], cfg["ssh_user"], cfg["ssh_password"])
            conn = mysql.connector.connect(host=cfg["host"], user=cfg["mysql_user"], password=cfg["mysql_password"], database="information_schema")
            cur = conn.cursor(dictionary=True)
            cur.execute("SHOW STATUS LIKE 'Threads_connected'")
            mysql_conn = int(cur.fetchone()["Value"])

            role = "Single Server"
            replication_status = "N/A"
            replication_lag = 0
            try:
                cur.execute("SHOW REPLICA STATUS")
                rep = cur.fetchone()
                if rep:
                    role = "Slave"
                    replication_lag = rep.get("Seconds_Behind_Replica",0)
                    replication_status = "🟢 OK" if rep.get("Replica_IO_Running")=="Yes" and rep.get("Replica_SQL_Running")=="Yes" else "Switch to Master"
                else:
                    cur.execute("SHOW MASTER STATUS")
                    if cur.fetchone():
                        role = "Master"
                        replication_status = "No Replication Configured"
            except:
                pass

            live[srv_name] = {"cpu":cpu,"ram":ram,"disk":disk,"mysql_cpu":mysql_cpu,"mysql_ram":mysql_ram,"mysql_conn":mysql_conn,
                              "role":role,"replication_status":replication_status,"replication_lag":replication_lag}

            # Insert metrics into central DB
            insert_query = """
                INSERT INTO system_metrics
                (server_name, cpu_usage, ram_usage, disk_usage, mysql_cpu, mysql_ram,
                 mysql_connection, role, replication_lag)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
            """
            log_cursor.execute(insert_query,(srv_name, cpu, ram, disk, mysql_cpu, mysql_ram, mysql_conn, role, replication_lag))
            logdb.commit()
            conn.close()
        except Exception as e:
            st.error(f"MySQL Error ({srv_name}): {e}")
    return live

# ----------------------------
# Fetch blocking queries
# ----------------------------
def fetch_blocking_queries(cfg):
    try:
        conn = mysql.connector.connect(host=cfg["host"], user=cfg["mysql_user"], password=cfg["mysql_password"], database="information_schema")
        cur = conn.cursor(dictionary=True)
        cur.execute("""
SELECT
    ID,
    USER,
    HOST,
    DB,
    TIME,
    STATE
FROM information_schema.PROCESSLIST
WHERE
    COMMAND NOT IN ('Sleep', 'Daemon')
    AND USER NOT IN ('system user', 'event_scheduler')
ORDER BY TIME DESC
LIMIT 30;

        """)
        df = pd.DataFrame(cur.fetchall(), columns=[desc[0] for desc in cur.description])
        conn.close()
        return df
    except Exception as e:
        st.error(f"Error fetching blocking queries: {e}")
        return pd.DataFrame()

# ----------------------------
# Main loop
# ----------------------------
while True:
    live_metrics = fetch_metrics()
    sel = live_metrics[selected_server]

    # ----------------------------
    # Metrics + Blocking Queries
    # ----------------------------
    with metric_container.container():
        st.subheader(f"🖥️ LIVE METRICS — {selected_server}")

        # Metrics
        c1,c2,c3,c4 = st.columns(4)
        c1.metric("CPU Usage (Server)", f"{sel['cpu']}%")
        c2.metric("RAM Usage (Server)", f"{sel['ram']}%")
        c3.metric("Disk Usage", f"{sel['disk']}%")
        c4.metric("MySQL Connections", sel["mysql_conn"])

        c5,c6 = st.columns(2)
        c5.metric("MySQL CPU", f"{sel['mysql_cpu']}%")
        c6.metric("MySQL RAM", f"{sel['mysql_ram']}%")

        c7,c8 = st.columns(2)
        c7.metric("Role", sel["role"])
        c8.metric("Replication", sel["replication_status"], f"Lag: {sel['replication_lag']} sec")

        # Blocking Queries (above charts)
        st.markdown("---")
        st.subheader("⚠️ Running Queries")
        blocking_df = fetch_blocking_queries(servers[selected_server])
        if not blocking_df.empty:
            st.dataframe(blocking_df)
        else:
            st.info("No blocking queries found.")

    # ----------------------------
    # Charts
    # ----------------------------
    df = pd.read_sql(f"""
        SELECT captured_at, cpu_usage, ram_usage, disk_usage, mysql_cpu, mysql_ram, mysql_connection, replication_lag
        FROM system_metrics
        WHERE server_name='{selected_server}'
        ORDER BY captured_at DESC
        LIMIT 200
    """, logdb).sort_values("captured_at")

    with chart_container.container():
        st.subheader("📈 Performance History")
        if not df.empty:
            st.plotly_chart(px.line(df, x="captured_at", y="cpu_usage", title="Server CPU Usage"), use_container_width=True)
            st.plotly_chart(px.line(df, x="captured_at", y="ram_usage", title="Server RAM Usage"), use_container_width=True)
            # st.plotly_chart(px.line(df, x="captured_at", y="mysql_cpu", title="MySQL CPU Usage"), use_container_width=True)
            # st.plotly_chart(px.line(df, x="captured_at", y="mysql_ram", title="MySQL RAM Usage"), use_container_width=True)

    # Sleep 10 sec
    time.sleep(20)
