#!/bin/bash

# -------------------------------
# USER CONFIGURATION
# -------------------------------
S1_IP="192.168.1.10"        # Original Master (to become MASTER again)
S2_IP="192.168.1.20"        # Current Master (to become SLAVE)
MYSQL_USER="root"
MYSQL_PASS="rootpassword"
REPL_USER="repl"
REPL_PASS="repl_password"

# -------------------------------
# STEP 1: BLOCK WRITES ON S1
# -------------------------------
echo "Blocking writes on S1..."
mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
SET GLOBAL read_only = ON;
SET GLOBAL super_read_only = ON;
"

# -------------------------------
# STEP 2: SYNC S1 FROM S2
# -------------------------------
echo "Syncing S1 from S2..."
mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST='$S2_IP',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION=1;
START SLAVE;
"

# -------------------------------
# STEP 3: WAIT FOR SYNC COMPLETION
# -------------------------------
echo "Waiting for S1 to catch up..."
sleep 5

SBM=$(mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -Nse \
"SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master" | awk '{print $2}')

while [ "$SBM" != "0" ]; do
  echo "Seconds_Behind_Master = $SBM — waiting..."
  sleep 5
  SBM=$(mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -Nse \
  "SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master" | awk '{print $2}')
done

echo "S1 is fully synced with S2 ✅"

# -------------------------------
# STEP 4: BLOCK WRITES ON S2
# -------------------------------
echo "Blocking writes on S2..."
mysql -h$S2_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
SET GLOBAL read_only = ON;
SET GLOBAL super_read_only = ON;
"

# -------------------------------
# STEP 5: PROMOTE S1 AS MASTER
# -------------------------------
echo "Promoting S1 back as MASTER..."
mysql -h$S1_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
STOP SLAVE;
SET GLOBAL read_only = OFF;
SET GLOBAL super_read_only = OFF;
"

# -------------------------------
# STEP 6: MAKE S2 SLAVE AGAIN
# -------------------------------
echo "Reconfiguring S2 as SLAVE of S1..."
mysql -h$S2_IP -u$MYSQL_USER -p$MYSQL_PASS -e "
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
  MASTER_HOST='$S1_IP',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION=1;
START SLAVE;
"

# -------------------------------
# STEP 7: FINAL STATUS CHECK
# -------------------------------
echo "Final replication status on S2:"
mysql -h$S2_IP -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW SLAVE STATUS\G"

echo "✅ FAILBACK COMPLETED SUCCESSFULLY"
