
==========================================================
        MySQL Server Installation – Ubuntu 22.x
==========================================================

PREREQUISITES
-------------
Before installing MySQL Server, make sure:

1. You have sudo privileges.
2. Ubuntu is updated (22.04 / 22.10 / 22.2 all supported).
3. Internet connection is available.
4. Port 3306 is free (only needed for remote access).
5. System time and timezone are correctly configured.
   (sudo timedatectl set-timezone <your-timezone>)

----------------------------------------------------------
 STEP 1: Update Package List
----------------------------------------------------------

sudo apt update

----------------------------------------------------------
 STEP 2: Install MySQL Server
----------------------------------------------------------

sudo apt install mysql-server -y

This installs:
- MySQL Server (mysqld)
- MySQL Client (mysql)

----------------------------------------------------------
 STEP 3: Start and Enable MySQL Service
----------------------------------------------------------

sudo systemctl start mysql
sudo systemctl enable mysql

Check status:
systemctl status mysql

----------------------------------------------------------
 STEP 4: Run MySQL Secure Installation
----------------------------------------------------------

sudo mysql_secure_installation

Recommended answers:
- Validate password plugin?      -> Y
- Password strength level        -> 0 / 1 / 2 (choose)
- Remove anonymous users?        -> Y
- Disallow root remote login?    -> Y
- Remove test database?          -> Y
- Reload privileges table?       -> Y

----------------------------------------------------------
 STEP 5: Log in as MySQL Root User
----------------------------------------------------------

sudo mysql

(Optional) set root password manually:
ALTER USER 'root'@'localhost'
  IDENTIFIED WITH mysql_native_password BY 'YourPassword';
FLUSH PRIVILEGES;

Exit MySQL:
exit;

----------------------------------------------------------
 OPTIONAL: Allow Remote MySQL Connections (port 3306)
----------------------------------------------------------

Edit config:
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Change this line:
bind-address = 127.0.0.1
TO:
bind-address = 0.0.0.0

Save file and restart MySQL:
sudo systemctl restart mysql

Allow port in firewall:
sudo ufw allow 3306

----------------------------------------------------------
 OPTIONAL: Create Database and User
----------------------------------------------------------

Log into MySQL:
sudo mysql

Create database:
CREATE DATABASE mydb;

Create user:
CREATE USER 'myuser'@'%' IDENTIFIED BY 'MySecurePass';

Grant privileges:
GRANT ALL PRIVILEGES ON mydb.* TO 'myuser'@'%';
FLUSH PRIVILEGES;

Exit:
exit;

----------------------------------------------------------
 STEP 6: Verify Installation
----------------------------------------------------------

sudo systemctl status mysql
mysql --version
sudo mysql -e "SELECT VERSION();"

----------------------------------------------------------
 UNINSTALL MySQL (if needed)
----------------------------------------------------------

sudo systemctl stop mysql
sudo apt remove --purge mysql-server mysql-client mysql-common -y
sudo apt autoremove -y
sudo rm -rf /var/lib/mysql

==========================================================
            END OF MySQL INSTALLATION GUIDE
==========================================================

✅ Install MySQL 8.4 LTS on Ubuntu 22.x (Official MySQL Repo)

============================================================
      MySQL 8.4 LTS - Installation Guide for Ubuntu 22.x
============================================================

PREREQUISITES
-------------
1. Ubuntu 22.04 / 22.10 / 22.2 (64-bit)
2. sudo/root privileges
3. Internet connection
4. Port 3306 free (needed only for remote access)
5. System updated: sudo apt update

============================================================
 STEP 1 — Update the system
============================================================

sudo apt update

============================================================
 STEP 2 — Download MySQL APT Repository Package
============================================================

wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb

============================================================
 STEP 3 — Install MySQL APT Repository
============================================================

sudo dpkg -i mysql-apt-config_0.8.29-1_all.deb

A configuration screen appears.
Select:

  MySQL Server & Cluster -> mysql-8.4-lts

Then choose:
  OK  ->  Apply

If you want to reconfigure later:

sudo dpkg-reconfigure mysql-apt-config

============================================================
 STEP 4 — Update APT Again (Important)
============================================================

sudo apt update

============================================================
 STEP 5 — Install MySQL 8.4 LTS Server
============================================================

sudo apt install mysql-server -y

This installs:
- MySQL 8.4 LTS Server
- MySQL 8.4 Client
- mysqld service

============================================================
 STEP 6 — Start and Enable MySQL
============================================================

sudo systemctl start mysql
sudo systemctl enable mysql

Check status:

systemctl status mysql

============================================================
 STEP 7 — Secure MySQL Installation
============================================================

sudo mysql_secure_installation

Recommended answers:
- Validate password plugin?     -> Y
- Remove anonymous users?       -> Y
- Disallow remote root login?   -> Y
- Remove test database?         -> Y
- Reload privilege tables?      -> Y

============================================================
 STEP 8 — Verify Installed MySQL Version
============================================================

mysql --version

OR:

sudo mysql -e "SELECT VERSION();"

Expected output:
8.4.x

============================================================
 OPTIONAL — Allow Remote MySQL Access (3306)
============================================================

Edit MySQL config:

sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

Find line:
bind-address = 127.0.0.1

Change to:
bind-address = 0.0.0.0

Save -> Restart MySQL:

sudo systemctl restart mysql

Allow firewall:
sudo ufw allow 3306

============================================================
 OPTIONAL — Create Database and User
============================================================

sudo mysql

CREATE DATABASE mydb;

CREATE USER 'myuser'@'%' IDENTIFIED BY 'MyPassword123';

GRANT ALL PRIVILEGES ON mydb.* TO 'myuser'@'%';
FLUSH PRIVILEGES;

exit;

============================================================
 UNINSTALL / REMOVE MySQL (Optional)
============================================================

sudo systemctl stop mysql
sudo apt remove --purge mysql-server mysql-client mysql-common -y
sudo apt autoremove -y
sudo rm -rf /var/lib/mysql

============================================================
           END OF MySQL 8.4 LTS INSTALLATION GUIDE
============================================================

✔ MariaDB CAN do this, MySQL CANNOT

replicate-ignore-statements = delete


