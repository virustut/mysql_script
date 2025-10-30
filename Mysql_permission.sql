-- ===========================================================
-- 🧑‍💻 MYSQL USER PERMISSIONS MASTER SCRIPT
-- Description: Common GRANT and REVOKE examples for MySQL users
-- ===========================================================

-- 1️⃣ CREATE USER
-- Create a new user (change username, host, and password as needed)
CREATE USER 'app_user'@'%' IDENTIFIED BY 'StrongPassword!';

-- ===========================================================
-- 2️⃣ READ-ONLY ACCESS (SELECT only)
-- User can only read data from all tables in database `mydb`
GRANT SELECT ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 3️⃣ DML-ONLY ACCESS (Data Manipulation: INSERT, UPDATE, DELETE)
-- User can modify data but cannot change table structure
GRANT INSERT, UPDATE, DELETE ON mydb.* TO 'app_user'@'%';

-- Example: only INSERT permission
GRANT INSERT ON mydb.* TO 'app_user'@'%';

-- Example: only UPDATE permission
GRANT UPDATE ON mydb.* TO 'app_user'@'%';

-- Example: only DELETE permission
GRANT DELETE ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 4️⃣ DDL-ONLY ACCESS (Data Definition: CREATE, DROP, ALTER)
-- User can manage database objects but not modify table data
GRANT CREATE, DROP, ALTER, INDEX ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 5️⃣ READ + DML (Can read and modify data but not schema)
GRANT SELECT, INSERT, UPDATE, DELETE ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 6️⃣ FULL DATABASE ACCESS (ALL PRIVILEGES)
-- User can do everything inside the specific database
GRANT ALL PRIVILEGES ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 7️⃣ VIEW CREATION PRIVILEGE
-- Allow the user to create and manage views
GRANT CREATE VIEW, SHOW VIEW ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 8️⃣ EXECUTE PRIVILEGE (for stored procedures and functions)
GRANT EXECUTE ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 9️⃣ DCL-RELATED (GRANT OPTION)
-- Allow user to grant permissions to others
GRANT GRANT OPTION ON mydb.* TO 'app_user'@'%';

-- ===========================================================
-- 🔒 REVOKE EXAMPLES
-- Revoke all privileges from the user
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'app_user'@'%';

-- Revoke only DML privileges
REVOKE INSERT, UPDATE, DELETE ON mydb.* FROM 'app_user'@'%';

-- Revoke only DDL privileges
REVOKE CREATE, DROP, ALTER, INDEX ON mydb.* FROM 'app_user'@'%';

-- ===========================================================
-- ✅ APPLY CHANGES
FLUSH PRIVILEGES;

-- ===========================================================
-- 🔍 CHECK USER PRIVILEGES
SHOW GRANTS FOR 'app_user'@'%';
