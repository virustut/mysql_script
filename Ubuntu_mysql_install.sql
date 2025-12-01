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
