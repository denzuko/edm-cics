/* ALOG -- On-air log inquiry (REXX)                               */
/* DPR back-office -- ACL: DPR, ADMIN                              */
/*                                                                 */
/* Displays what actually aired from the automation feed.          */
/* Reconciliation: compares dpr_alog against dpr_traffic.          */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER  = 'DPR ON-AIR LOG'
SCR.USERID  = USR
SCR.LOGDATE = DATE('S')
SCR.FOOTER  = 'ENTER=View  PF3=Menu'

EXEC CICS CONVERSE MAP('ALOG1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

LOGDATE = STRIP(SCR.LOGDATE)

/* Reconciliation counts */
EXEC SQL
    SELECT
        (SELECT COUNT(*) FROM dpr_alog
         WHERE aired_at::DATE = :LOGDATE::DATE) AS aired,
        (SELECT COUNT(*) FROM dpr_traffic
         WHERE log_date = :LOGDATE::DATE AND status = 'M') AS missed
    INTO :AIRED_CT, :MISSED_CT
END-EXEC

IF SQLCODE = 0 THEN DO
    SCR.AIREDCT  = AIRED_CT
    SCR.MISSEDCT = MISSED_CT
END

EXEC CICS SEND MAP('ALOG1') FROM(SCR.) ERASE END-EXEC
EXEC CICS RETURN TRANSID('ALOG') IMMEDIATE END-EXEC
EXIT
