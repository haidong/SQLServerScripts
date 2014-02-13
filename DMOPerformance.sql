-- Base info - sys.dm_os_sys_info
SELECT cpu_count AS logical_cpu_count,
 cpu_count / hyperthread_ratio AS physical_cpu_count,
 CAST(physical_memory_kb / 1024. AS int) AS physical_memory__mb, 
 sqlserver_start_time
FROM sys.dm_os_sys_info;

-- Waiting sessions - sys.dm_os_waiting_tasks, sys.dm_exec_sessions
SELECT S.login_name, S.host_name, S.program_name,
 WT.session_id, WT.wait_duration_ms, WT.wait_type, 
 WT.blocking_session_id, WT.resource_description
FROM sys.dm_os_waiting_tasks AS WT
 INNER JOIN sys.dm_exec_sessions AS S
  ON WT.session_id = S.session_id
WHERE s.is_user_process = 1;

-- Currently executing batches, with text and wait info
SELECT S.login_name, S.host_name, S.program_name,
 R.command, T.text,
 R.wait_type, R.wait_time, R.blocking_session_id
FROM sys.dm_exec_requests AS R
 INNER JOIN sys.dm_exec_sessions AS S
  ON R.session_id = S.session_id		
 OUTER APPLY sys.dm_exec_sql_text(R.sql_handle) AS T
WHERE S.is_user_process = 1;

-- Top five queries by total logical IO
SELECT TOP (5)
 (total_logical_reads + total_logical_writes) AS total_logical_IO,
 execution_count, 
 (total_logical_reads/execution_count) AS avg_logical_reads,
 (total_logical_writes/execution_count) AS avg_logical_writes,
 (SELECT SUBSTRING(text, statement_start_offset/2 + 1,
    (CASE WHEN statement_end_offset = -1
          THEN LEN(CONVERT(nvarchar(MAX),text)) * 2
          ELSE statement_end_offset
     END - statement_start_offset)/2)
   FROM sys.dm_exec_sql_text(sql_handle)) AS query_text
FROM sys.dm_exec_query_stats
ORDER BY (total_logical_reads + total_logical_writes) DESC;
GO

--Check which indexes are used for a given table ('Sales.Orders')
SELECT OBJECT_NAME(S.object_id) AS table_name,
I.name AS index_name,
S.user_seeks, S.user_scans, s.user_lookups
FROM sys.dm_db_index_usage_stats AS S
INNER JOIN sys.indexes AS i
ON S.object_id = I.object_id
AND S.index_id = I.index_id
WHERE S.object_id = OBJECT_ID(N'Sales.Orders', N'U');

--Check when statistics was last updated
DBCC SHOW_STATISTICS(N'Sales.Orders',N'idx_nc_empid') WITH STAT_HEADER;
