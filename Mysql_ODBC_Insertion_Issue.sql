select *From History; if i run this query in mysql i got connect time and data type datetime and  value is 2025-10-14 12:05:21 
but when the same query if i run from mssql  using select * From openquery([20.20.20.82],'select * From Electrolux.History') i got connect time value 2025-10-14 12:05:21.0000000 why ?

Answer :
select *From History; if i run this query in mysql i got connect time and data type datetime and  value is 2025-10-14 12:05:21 
but when the same query if i run from mssql  using select * From openquery([20.20.20.82],'select * From Electrolux.History') i got connect time value 2025-10-14 12:05:21.0000000 why ?


| Source                     | Value of `ConnectTime`        |
| -------------------------- | ----------------------------- |
| MySQL (direct query)       | `2025-10-14 12:05:21`         |
| SQL Server via `OPENQUERY` | `2025-10-14 12:05:21.0000000` |



Why this happens:

In MySQL, the DATETIME type supports fractional seconds up to 6 digits (e.g., DATETIME(6) = 2025-10-14 12:05:21.000000).

Even if no fractional part is stored, MySQL still allows fractional seconds to be part of the datatype.

When SQL Server queries this via Linked Server (OPENQUERY), the ODBC driver (like MySQL ODBC 8.0) reads DATETIME and maps it to SQL Server’s datetime2(7) by default.

Hence, SQL Server displays it with 7-digit fractional seconds: 2025-10-14 12:05:21.0000000.

You’re not seeing extra data — just different formatting/precision due to how the ODBC driver translates data types between MySQL and SQL Server.

---- Corrected query to insert 

INSERT INTO History (
    MyCode, Phone, ConnectTime, DisconnectTime, DisposeTime, Connid, AgentID,
    DispoCode, SubDispoCode, SubSubDispoCode, Campaign_Name, REMARKS,
    CALL_DATE, CALL_TIME,
    EmployeID, AGENT_NAME, BATCHID, callbacktime, DisconnectType, RecPath,
    Ticket_Number, Registered_Number
)
SELECT
    MyCode, Phone,
    TRY_CAST(ConnectTime AS datetime2(3)),
    TRY_CAST(DisconnectTime AS datetime2(3)),
    TRY_CAST(DisposeTime AS datetime2(3)),
    Connid, AgentID, DispoCode, SubDispoCode, SubSubDispoCode, Campaign_Name, REMARKS,
    TRY_CAST(CALL_DATE AS datetime2(3)),
    TRY_CAST(CALL_TIME AS datetime2(3)),
    EmployeID, AGENT_NAME, BATCHID, callbacktime, DisconnectType, RecPath,
    TicketNo, RegisteredPhoneNumber
FROM OPENQUERY([20.20.20.82], '
    SELECT
        MyCode,
        Phone,
        CASE WHEN ConnectTime < ''1753-01-01'' OR ConnectTime IS NULL THEN NULL ELSE ConnectTime END AS ConnectTime,
        CASE WHEN DisconnectTime < ''1753-01-01'' OR DisconnectTime IS NULL THEN NULL ELSE DisconnectTime END AS DisconnectTime,
        CASE WHEN DisposeTime < ''1753-01-01'' OR DisposeTime IS NULL THEN NULL ELSE DisposeTime END AS DisposeTime,
        Connid,
        AgentID,
        DispoCode,
        SubDispoCode,
        SubSubDispoCode,
        Campaign_Name,
        REMARKS,
        CASE WHEN CALL_DATE = ''0000-00-00'' OR CALL_DATE IS NULL THEN NULL ELSE CALL_DATE END AS CALL_DATE,
        CASE WHEN CALL_TIME = ''00:00:00'' OR CALL_TIME IS NULL THEN NULL ELSE CALL_TIME END AS CALL_TIME,
        EmployeID,
        AGENT_NAME,
        BATCHID,
        callbacktime,
        DisconnectType,
        RecPath,
        TicketNo,
        RegisteredPhoneNumber
    FROM Electrolux.History
    WHERE DisposeTime >= CURDATE() - INTERVAL 2 DAY
      AND (ConnectTime >= ''1753-01-01'' OR ConnectTime IS NULL)
      AND (DisconnectTime >= ''1753-01-01'' OR DisconnectTime IS NULL)
      AND (DisposeTime >= ''1753-01-01'' OR DisposeTime IS NULL)
      AND (CALL_DATE >= ''1753-01-01'' OR CALL_DATE IS NULL OR CALL_DATE = ''0000-00-00'')
      AND (CALL_TIME >= ''00:00:00'' OR CALL_TIME IS NULL OR CALL_TIME = ''00:00:00'')
') AS src
WHERE NOT EXISTS (
    SELECT 1 FROM History tgt WHERE tgt.connid = src.connid
);
