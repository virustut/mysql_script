create database TEST2;
use TEST2;

SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW BINARY LOGS;
CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    salary INT
);


INSERT INTO employees (name, salary) VALUES
('Alice', 50000),
('Bob', 60000),
('Charlie', 55000);

SELECT * FROM employees;

--  step 3 Take the logical backup of database 
# mysqldump -u root -p --databases testdb > testdb_backup.sql  Done at 18:16

-- Step 4: Perform an accidental TRUNCATE TABLE
TRUNCATE TABLE TEST2.employees;

SELECT * FROM TEST2.employees;
-- should return 0 rows

-- Step 5: Recover data from binary logs and backup
-- Restore backup to a separate database or server
-- create database testdb;
# mysql -u root -p < testdb_backup.sql

-- mysqlbinlog --start-datetime="2025-09-23 18:17:15" /var/lib/mysql/binlog.000001 > full_binlog.sql

-- Option B: Use --stop-position or --stop-datetime in mysqlbinlog

-- mysqlbinlog --stop-datetime="2025-09-23 21:00:00" /var/lib/mysql/mysql-bin.000001 > binlog_before_truncate.sql
-- mysql -u root -p testdb < binlog_before_truncate.sql

-- SELECT * FROM testdb.employees;

