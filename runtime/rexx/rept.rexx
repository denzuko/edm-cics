/* REPT -- Management reports menu (REXX)                          */
/* Converted from COBOL: aggregate SQL better suited to REXX       */
/* ACL: EDM, ADMIN                                                 */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER = 'REPORTS -- MANAGEMENT DASHBOARD'
SCR.USERID = USR

/* Run aggregate queries */
EXEC SQL
    SELECT COUNT(*) INTO :TOTCLI FROM edm_clients WHERE status = 'A'
END-EXEC
IF SQLCODE = 0 THEN SCR.TOTCLI = TOTCLI

EXEC SQL
    SELECT COUNT(*) INTO :ACTORD
    FROM edm_orders WHERE order_status IN ('P','A')
END-EXEC
IF SQLCODE = 0 THEN SCR.ACTORD = ACTORD

EXEC SQL
    SELECT COALESCE(SUM(order_value),0) INTO :TOTVAL
    FROM edm_orders WHERE order_status IN ('P','A')
END-EXEC
IF SQLCODE = 0 THEN SCR.TOTVAL = TOTVAL

/* Most recent order */
EXEC SQL
    SELECT order_id, client_id, order_type, order_value, order_status
    INTO :SCR.ORD1ID, :SCR.ORD1CLI, :SCR.ORD1TYPE,
         :SCR.ORD1VAL, :SCR.ORD1STAT
    FROM edm_orders ORDER BY order_date DESC LIMIT 1
END-EXEC

SCR.FOOTER = 'ENTER=Refresh  PF3=Menu'

EXEC CICS CONVERSE MAP('REPT1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

EXEC CICS RETURN TRANSID('REPT') IMMEDIATE END-EXEC

EXIT
