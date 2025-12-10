#!/bin/bash

# ----------------------------------
# SERVER DETAILS
# ----------------------------------
S1_IP="172.18.163.64"        # Original Master (to be MASTER again)
S2_IP="172.18.163.66"        # Current Master (to become SLAVE)

MYSQL_USER="root"
MYSQL_PASS="ROOT_PASSWORD"  # <<< PUT YOUR ROOT PASSWORD HERE

REPL_USER="repl_user"
REPL_PASS="Repl@1234"

# ----------------------------------
# STEP 1: BLOCK WRITES ON S1
# ----------------------------------
echo "🔒 Blocking writes on S1 (172.18.163.64)..."
mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
SET GLOBAL read_only = ON;
SET GLOBAL super_read_only = ON;
"

# ----------------------------------
# STEP 2: SYNC S1 FROM S2
# ----------------------------------
echo "🔄 Syncing S1 from current master S2..."
mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
STOP SLAVE;
RESET SLAVE ALL;

CHANGE MASTER TO
  MASTER_HOST='$S2_IP',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION = 1;

START SLAVE;
"

# ----------------------------------
# STEP 3: WAIT FOR S1 TO CATCH UP
# ----------------------------------
echo "⏳ Waiting for S1 to fully sync from S2..."

sleep 5

SBM=$(mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -Nse \
"SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master" | awk '{print $2}')

while [ "$SBM" != "0" ]; do
  echo "   Seconds_Behind_Master = $SBM — waiting..."
  sleep 5
  SBM=$(mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -Nse \
  "SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master" | awk '{print $2}')
done

echo "✅ S1 is now fully synced with S2"

# ----------------------------------
# STEP 4: BLOCK WRITES ON S2
# ----------------------------------
echo "🔒 Blocking writes on S2 (current master)..."
mysql -h$S2_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
SET GLOBAL read_only = ON;
SET GLOBAL super_read_only = ON;
"

# ----------------------------------
# STEP 5: PROMOTE S1 AS MASTER
# ----------------------------------
echo "🚀 Promoting S1 back as MASTER..."
mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
STOP SLAVE;
SET GLOBAL read_only = OFF;
SET GLOBAL super_read_only = OFF;
"

# ----------------------------------
# STEP 6: MAKE S2 SLAVE AGAIN
# ----------------------------------
echo "🔁 Converting S2 into SLAVE of S1..."
mysql -h$S2_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
STOP SLAVE;
RESET SLAVE ALL;

CHANGE MASTER TO
  MASTER_HOST='$S1_IP',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION = 1;

START SLAVE;
"

# ----------------------------------
# STEP 7: FINAL VERIFICATION
# ----------------------------------
echo "📊 Final Replication Status on S2:"
mysql -h$S2_IP -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW SLAVE STATUS\G"

echo "✅✅ FAILBACK SUCCESSFUL — S1 is MASTER, S2 is SLAVE ✅✅"



Note : Safety Check before running 
Confirm this on S2(current master) before running:
select @@Global.gtid_executed;
show processlist;

Ensure no heavy write workload during failback
Ensure S1 had no writes while it was down

Note : Do not run this script if 

S1 accepted writes while it was down
GTID is disable
log_slave_updates is OFF
