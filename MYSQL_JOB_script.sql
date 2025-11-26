✅ How to Track MySQL Event Job Success/Failure (Like SQL Agent)

You must create:

✔ 1. A job history table (like SQL Agent history)
✔ 2. Modify every MySQL event to log success or errors
✔ 3. Create an email alert or dashboard

⭐ STEP 1 — Create Job History Table

CREATE TABLE job_history (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(200),
    status VARCHAR(20),     -- SUCCESS / FAILED
    error_message TEXT,
    start_time DATETIME,
    end_time DATETIME
);

⭐ STEP 2 — Wrap Every Event in TRY/CATCH Simulation

MySQL does NOT have TRY/CATCH like SQL Server,
but you can simulate error capture using DECLARE HANDLER.

Example Event with Logging:
CREATE EVENT ev_daily_sales_update
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    DECLARE v_start DATETIME;
    DECLARE v_error TEXT DEFAULT NULL;
    
    SET v_start = NOW();

    -- ERROR HANDLER
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error = CONCAT('Error Code: ', @@ERROR, ' Message: ', MESSAGE_TEXT());
    END;

    -- Your actual job query
    INSERT INTO sales_summary (date, total_sales)
    SELECT CURDATE(), SUM(amount) FROM sales;

    -- Log result
    INSERT INTO job_history(job_name, status, error_message, start_time, end_time)
    VALUES (
        'ev_daily_sales_update',
        IF(v_error IS NULL, 'SUCCESS', 'FAILED'),
        v_error,
        v_start,
        NOW()
    );
END;


This will automatically write to job_history table:

| job_name              | status  | error_message    | start_time       | end_time         |
| --------------------- | ------- | ---------------- | ---------------- | ---------------- |
| ev_daily_sales_update | SUCCESS | NULL             | 2025-01-01 01:00 | 2025-01-01 01:00 |
| ev_daily_sales_update | FAILED  | Duplicate entry… | 2025-01-02 01:00 | 2025-01-02 01:00 |


⭐ STEP 3 — Query Job Status Like SQL Agent History

SELECT *
FROM job_history
ORDER BY id DESC
LIMIT 10;


⭐ STEP 4 — Send Email Alert on Failure (Optional)

MySQL cannot send emails directly.

But you can:

✔ Use Python script
✔ Query for failed jobs
✔ Send email/Slack/Teams alert

Example Python check:

SELECT job_name, error_message, end_time
FROM job_history
WHERE status = 'FAILED'
AND end_time > NOW() - INTERVAL 10 MINUTE;
