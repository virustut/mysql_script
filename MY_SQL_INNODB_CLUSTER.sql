Below is a complete, step-by-step guide (real-world DBA style) to build your 3-node MySQL InnoDB Cluster from scratch.

🧩 Overview
| Node   | Role         | Example Hostname     | Port |
| ------ | ------------ | -------------------- | ---- |
| Node 1 | Primary (RW) | `mysql1.example.com` | 3306 |
| Node 2 | Secondary    | `mysql2.example.com` | 3306 |
| Node 3 | Secondary    | `mysql3.example.com` | 3306 |


Components used:

MySQL Server (mysqld)

MySQL Shell (mysqlsh)

MySQL Router (optional, for automatic routing)

Group Replication for data sync

🧠 Prerequisites

✅ All servers should have:

MySQL 8.0 or later installed.

Same version across all 3 servers.

Proper network connectivity (each node can ping the others).

Unique server IDs in my.cnf.

Binary logging and GTIDs enabled.

A replication user that can be used by all nodes.


⚙️ Step 1: Configure Each MySQL Server

Edit /etc/my.cnf (or mysqld.cnf) on each server.

Example for mysql1:
[mysqld]
server_id=1
report_host=mysql1.example.com
datadir=/var/lib/mysql
log_bin=mysql-bin
binlog_format=ROW
enforce_gtid_consistency=ON
gtid_mode=ON
master_info_repository=TABLE
relay_log_info_repository=TABLE
transaction_write_set_extraction=XXHASH64
loose-group_replication_bootstrap_group=OFF
loose-group_replication_start_on_boot=OFF
loose-group_replication_local_address="mysql1.example.com:33061"
loose-group_replication_group_seeds="mysql1.example.com:33061,mysql2.example.com:33061,mysql3.example.com:33061"
loose-group_replication_group_name="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
loose-group_replication_ip_whitelist="mysql1.example.com,mysql2.example.com,mysql3.example.com"


Change server_id and loose-group_replication_local_address accordingly for each node:

Node 1 → server_id=1

Node 2 → server_id=2

Node 3 → server_id=3

Restart MySQL:

sudo systemctl restart mysql

⚙️ Step 2: Create a Cluster Administrator User (on Node 1)

Login to Node 1:
mysql -u root -p

Create a user for cluster operations:
CREATE USER 'clusterAdmin'@'%' IDENTIFIED BY 'StrongPassword';
GRANT ALL PRIVILEGES ON *.* TO 'clusterAdmin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

⚙️ Step 3: Open MySQL Shell and Connect to Node 1
mysqlsh clusterAdmin@mysql1.example.com:3306

Switch to JavaScript mode if not already:
\js

Create an instance configuration:
dba.configureInstance('clusterAdmin@mysql1.example.com:3306');

Then do the same on Node 2 and Node 3 (run from their hosts or remotely):
dba.configureInstance('clusterAdmin@mysql2.example.com:3306');
dba.configureInstance('clusterAdmin@mysql3.example.com:3306');

⚙️ Step 4: Create the Cluster

Still in MySQL Shell on Node 1:
var cluster = dba.createCluster('myCluster');

This initializes Group Replication and creates the first primary node.
⚙️ Step 5: Add the Other Nodes

Add Node 2:
cluster.addInstance('clusterAdmin@mysql2.example.com:3306');

Add Node 3:
cluster.addInstance('clusterAdmin@mysql3.example.com:3306');

Check status:
cluster.status();

✅ You should see all 3 nodes in ONLINE status — one PRIMARY, two SECONDARY.
⚙️ Step 6: Verify the Cluster
cluster.status({extended:true});

You should see something like:
Cluster name: myCluster
Status: OK
Cluster topology:
  mysql1.example.com:3306 (PRIMARY)
  mysql2.example.com:3306 (SECONDARY)
  mysql3.example.com:3306 (SECONDARY)

⚙️ Step 7: (Optional) Configure MySQL Router

Install MySQL Router on your application server (or on Node 1).

Bootstrap it to the cluster:
mysqlrouter --bootstrap clusterAdmin@mysql1.example.com:3306 --user=mysqlrouter

Start Router:
sudo systemctl start mysqlrouter

Now your application connects to:

localhost:6446 → Read/Write (Primary)

localhost:6447 → Read-Only (Replicas)

Router automatically reroutes if a node fails.

✅ Step 8: Test Failover

Stop MySQL on Node 1:
sudo systemctl stop mysql


Run cluster.status() in MySQL Shell — Node 2 should become PRIMARY automatically.
Restart Node 1, and it will rejoin as a SECONDARY.

🧱 Final Architecture
              +--------------------+
              |    MySQL Router    |
              +---------+----------+
                        |
         +--------------+---------------+
         |                              |
 +---------------+             +----------------+
 | mysql1 (RW)   |             | mysql2 (RO)    |
 | PRIMARY node  |<--sync-->   | SECONDARY node |
 +---------------+             +----------------+
                 \           /
                  \         /
                   +----------------+
                   | mysql3 (RO)    |
                   | SECONDARY node |
                   +----------------+


⚡ Bonus Commands
| Task                 | Command                                    |
| -------------------- | ------------------------------------------ |
| View cluster info    | `cluster.status()`                         |
| List cluster members | `cluster.listRouters()`                    |
| Remove a node        | `cluster.removeInstance('user@node:3306')` |
| Rejoin a node        | `cluster.rejoinInstance('user@node:3306')` |











