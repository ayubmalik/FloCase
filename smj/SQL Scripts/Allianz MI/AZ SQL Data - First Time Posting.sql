USE [AderantLiveBLM]

SELECT 
[MATTER_UNO],
MIN([TRAN_DATE]) as "First_Time_Posting"
FROM
[TAT_TIME]
WHERE
WIP_STATUS Not In('X','N','C')
AND
BILLABLE_FLAG = 'B'
GROUP BY
[MATTER_UNO]

