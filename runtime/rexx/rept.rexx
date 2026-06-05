/* REPT -- Management reports and print dispatch (REXX)            */
/* ACL: EDM, ADMIN                                                 */
/*                                                                 */
/* Displays dashboard and allows operator to queue a report for    */
/* printing or email delivery. Report generation is handled by     */
/* PL/PgSQL functions; this transaction submits the job and        */
/* returns immediately (non-blocking).                             */

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

SCR.FOOTER = 'ENTER=Refresh  PF1=Print Client List  PF2=Print Orders  PF3=Menu  PF4=Print Audit'

EXEC CICS CONVERSE MAP('REPT1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

SELECT
    WHEN (EIBAID = 'PF03') THEN DO
        EXEC CICS XCTL PROGRAM('MENU') END-EXEC
        EXIT
    END
    WHEN (EIBAID = 'PF01') THEN DO
        /* Queue client list report to printer */
        EXEC SQL
            INSERT INTO print_queue (report_type, requested_by, destination)
            VALUES ('CLNT_RPT', :USR, 'PRNT')
        END-EXEC
        IF SQLCODE = 0 THEN DO
            EXEC SQL COMMIT END-EXEC
            SCR.MESSAGE = 'CLIENT LIST REPORT QUEUED FOR PRINTING.'
        END
        ELSE SCR.MESSAGE = 'QUEUE FAILED: ' || SQLCODE
    END
    WHEN (EIBAID = 'PF02') THEN DO
        /* Queue open orders report */
        EXEC SQL
            INSERT INTO print_queue (report_type, requested_by, destination)
            VALUES ('ORDR_RPT', :USR, 'PRNT')
        END-EXEC
        IF SQLCODE = 0 THEN DO
            EXEC SQL COMMIT END-EXEC
            SCR.MESSAGE = 'OPEN ORDERS REPORT QUEUED.'
        END
        ELSE SCR.MESSAGE = 'QUEUE FAILED: ' || SQLCODE
    END
    WHEN (EIBAID = 'PF04') THEN DO
        /* Queue audit log report for last 24 hours */
        EXEC SQL
            INSERT INTO print_queue
                (report_type, requested_by, destination, parameters)
            VALUES
                ('AUDT_RPT', :USR, 'PRNT',
                 ('{"from_date":"' || TO_CHAR(NOW()-INTERVAL '24 hours',
                  'YYYY-MM-DD HH24:MI:SS') || '"}')::JSONB)
        END-EXEC
        IF SQLCODE = 0 THEN DO
            EXEC SQL COMMIT END-EXEC
            SCR.MESSAGE = 'AUDIT LOG REPORT QUEUED.'
        END
        ELSE SCR.MESSAGE = 'QUEUE FAILED: ' || SQLCODE
    END
    OTHERWISE DO
        SCR.MESSAGE = ''
    END
END

EXEC CICS SEND MAP('REPT1') FROM(SCR.) ERASE END-EXEC
EXEC CICS RETURN TRANSID('REPT') IMMEDIATE END-EXEC

EXIT
