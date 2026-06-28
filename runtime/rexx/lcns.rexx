/* LCNS -- Licensing report query (REXX)                           */
/* DPR back-office -- ACL: DPR, ADMIN                              */
/*                                                                 */
/* Queries unreported plays and queues licensing report.           */
/* PF1=Queue ASCAP report  PF2=Queue BMI  PF3=Menu                 */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER = 'DPR LICENSING REPORTS'
SCR.USERID = USR
SCR.FOOTER = 'PF1=ASCAP  PF2=BMI  PF3=Menu'

EXEC SQL
    SELECT COUNT(*), MIN(aired_at), MAX(aired_at)
    INTO :UNRPTCNT, :FRDATE, :TODATE
    FROM dpr_licensing WHERE reported = FALSE
END-EXEC

IF SQLCODE = 0 THEN DO
    SCR.UNRPTCNT = UNRPTCNT
    SCR.FRDATE   = FRDATE
    SCR.TODATE   = TODATE
END

SCR.MESSAGE = ''

EXEC CICS CONVERSE MAP('LCNS1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

SELECT
    WHEN (EIBAID = 'PF03') THEN DO
        EXEC CICS XCTL PROGRAM('MENU') END-EXEC
        EXIT
    END
    WHEN (EIBAID = 'PF01' | EIBAID = 'PF02') THEN DO
        BODY = CASE EIBAID WHEN 'PF01' THEN 'ASCAP' ELSE 'BMI' END
        EXEC SQL
            INSERT INTO print_queue
                (report_type, requested_by, destination,
                 parameters)
            VALUES
                ('LCNS_RPT', :USR, 'PRNT',
                 ('{"body":"'||BODY||'"}')::JSONB)
        END-EXEC
        IF SQLCODE = 0 THEN DO
            EXEC SQL COMMIT END-EXEC
            SCR.MESSAGE = BODY || ' REPORT QUEUED.'
        END
        ELSE SCR.MESSAGE = 'QUEUE FAILED: ' || SQLCODE
    END
    OTHERWISE NOP
END

EXEC CICS SEND MAP('LCNS1') FROM(SCR.) ERASE END-EXEC
EXEC CICS RETURN TRANSID('LCNS') IMMEDIATE END-EXEC
EXIT
