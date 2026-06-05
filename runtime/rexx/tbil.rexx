/* TBIL -- Traffic billing summary (REXX)                          */
/* DPR back-office -- ACL: DPR, ADMIN                              */
/*                                                                 */
/* Displays billing summary and queues invoice report.             */
/* PF1=Queue invoice to print  PF3=Menu                            */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER = 'DPR TRAFFIC BILLING'
SCR.USERID = USR
SCR.FOOTER = 'ENTER=View  PF1=Print Invoice  PF3=Menu'

EXEC CICS CONVERSE MAP('TBIL1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

/* Summary counts */
EXEC SQL
    SELECT COUNT(*), COALESCE(SUM(amount_due),0)
    INTO :OPENCNT, :OPENTOTAL
    FROM dpr_billing WHERE status = 'O'
END-EXEC
IF SQLCODE = 0 THEN DO
    SCR.OPENCNT   = OPENCNT
    SCR.OPENTOTAL = OPENTOTAL
END

/* PF1: queue billing report */
IF EIBAID = 'PF01' THEN DO
    EXEC SQL
        INSERT INTO print_queue
            (report_type, requested_by, destination)
        VALUES ('BLNG_RPT', :USR, 'PRNT')
    END-EXEC
    IF SQLCODE = 0 THEN DO
        EXEC SQL COMMIT END-EXEC
        SCR.MESSAGE = 'BILLING REPORT QUEUED.'
    END
    ELSE SCR.MESSAGE = 'QUEUE FAILED: ' || SQLCODE
END

EXEC CICS SEND MAP('TBIL1') FROM(SCR.) ERASE END-EXEC
EXEC CICS RETURN TRANSID('TBIL') IMMEDIATE END-EXEC
EXIT
