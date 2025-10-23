⚙️ 2. Create the Event Scheduler

SET GLOBAL event_scheduler = ON;
You can also make this permanent by adding to your my.cnf (MySQL config):
event_scheduler=ON


🪄 3. Create the Event (Job)

DELIMITER $$

CREATE EVENT IF NOT EXISTS ev_archive_call_details
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 DAY
DO
BEGIN
    -- Move records older than 31 days to backup
    INSERT INTO call_details_backup
    SELECT *
    FROM call_details
    WHERE call_date < NOW() - INTERVAL 31 DAY;

    -- Delete those records from main table
    DELETE FROM call_details
    WHERE call_date < NOW() - INTERVAL 31 DAY;

    -- Delete old records (older than 365 days) from backup
    DELETE FROM call_details_backup
    WHERE call_date < NOW() - INTERVAL 365 DAY;
END$$

DELIMITER ;

✅ What this does:

Runs every day.

Copies data older than 31 days into call_details_backup.

Deletes the copied rows from call_details.

Deletes anything older than 1 year from call_details_backup.
-- to see the event 

SHOW EVENTS;
SHOW CREATE EVENT ev_archive_call_details\G
