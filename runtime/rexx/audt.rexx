/* AUDT -- Audit log append (REXX)                                 */
/* Episode 09 -- EDM CICS Tutorial Series                          */
/*                                                                 */
/* Demonstrates: append-only SQL INSERT, EXEC SQL COMMIT,         */
/* EXEC CICS ASKTIME / FORMATTIME for timestamp generation.       */
/*                                                                 */
/* NOTE: edm_audit has UPDATE and DELETE revoked at the DB level. */
/* This program only INSERTs. The immutability is enforced by DB  */
/* permissions, not application logic.                            */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER  = 'EDM AUDIT LOG -- EDMARC'
SCR.USERID  = USR
SCR.FOOTER  = 'ENTER=Log event  PF3=Exit'

EXEC CICS CONVERSE MAP('AUDT1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS RETURN END-EXEC
    EXIT
END

/* Get precise timestamp */
EXEC CICS ASKTIME ABSTIME(ABS) END-EXEC
EXEC CICS FORMATTIME ABSTIME(ABS) YYYYMMDD(ADATE) TIME(ATIME) END-EXEC
TS = ADATE || LEFT(ATIME, 6)  /* YYYYMMDDHHMMSS */

/* Retrieve entered values from screen */
CLIENTID   = STRIP(SCR.CLIENTID)
ACTIONCODE = STRIP(SCR.ACTIONCODE)
RESULTCODE = STRIP(SCR.RESULTCODE)
NOTES      = STRIP(SCR.NOTES)

EXEC SQL
    INSERT INTO edm_audit
        (trans_timestamp, userid, transid, program,
         client_id, action_code, after_image, result_code, terminal_id)
    VALUES
        (:TS, :USR, 'AUDT', 'AUDT',
         :CLIENTID, :ACTIONCODE, :NOTES, :RESULTCODE, :TRM)
END-EXEC

IF SQLCODE = 0 THEN DO
    EXEC SQL COMMIT END-EXEC
    SCR.MESSAGE = 'AUDIT RECORD LOGGED. SEQ: ' || SQLERRD.1
END
ELSE DO
    SCR.MESSAGE = 'INSERT FAILED: ' || SQLCODE
END

EXEC CICS SEND MAP('AUDT1') FROM(SCR.) ERASE END-EXEC

EXEC CICS RETURN END-EXEC

EXIT
