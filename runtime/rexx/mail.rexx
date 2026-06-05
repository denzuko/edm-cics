/* MAIL -- Mail dispatch (REXX)                                    */
/* Episode bonus -- EDM CICS Tutorial Series                       */
/*                                                                 */
/* Queues an email to edm_mailq. The queue is drained by an       */
/* external relay (pg_smtp_client trigger or sidecar process).     */
/* This transaction never touches SMTP directly.                   */
/*                                                                 */
/* Supports two modes:                                             */
/*   TO LIST: send to a named list in edm_maillists               */
/*   TO CLIENT: send to a specific client's email via edm_clients  */
/*                                                                 */
/* NOTE: All helpdesk list traffic is logged for compliance.       */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER  = 'MAIL DISPATCH'
SCR.USERID  = USR
SCR.FOOTER  = 'ENTER=Send  PF3=Cancel'

EXEC CICS CONVERSE MAP('MAIL1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS RETURN END-EXEC
    EXIT
END

/* Determine recipient: list name takes priority over client ID */
TOADDR  = ''
CLIID   = STRIP(SCR.CLIENTID)
LISTNAM = STRIP(SCR.LISTNAME)
SUBJ    = STRIP(SCR.SUBJECT)
BODY    = STRIP(SCR.BODY)

IF LISTNAM <> '' THEN DO
    /* Look up list address */
    EXEC SQL
        SELECT list_addr INTO :TOADDR
        FROM edm_maillists
        WHERE list_name = :LISTNAM
          AND status    = 'A'
    END-EXEC
    IF SQLCODE <> 0 THEN DO
        SCR.MESSAGE = 'LIST NOT FOUND OR INACTIVE: ' || LISTNAM
        EXEC CICS SEND MAP('MAIL1') FROM(SCR.) ERASE END-EXEC
        EXEC CICS RETURN END-EXEC
        EXIT
    END
    CLIID = ''  /* list send; no client_id FK */
END
ELSE IF CLIID <> '' THEN DO
    /* Look up client email -- stored in reserved1 per EDM schema convention */
    EXEC SQL
        SELECT reserved1 INTO :TOADDR
        FROM edm_clients
        WHERE client_id = :CLIID
          AND status    = 'A'
    END-EXEC
    IF SQLCODE <> 0 | STRIP(TOADDR) = '' THEN DO
        SCR.MESSAGE = 'CLIENT NOT FOUND OR NO EMAIL ON FILE.'
        EXEC CICS SEND MAP('MAIL1') FROM(SCR.) ERASE END-EXEC
        EXEC CICS RETURN END-EXEC
        EXIT
    END
END
ELSE DO
    SCR.MESSAGE = 'PROVIDE A LIST NAME OR CLIENT ID.'
    EXEC CICS SEND MAP('MAIL1') FROM(SCR.) ERASE END-EXEC
    EXEC CICS RETURN END-EXEC
    EXIT
END

/* Queue the message */
EXEC SQL
    INSERT INTO edm_mailq
        (to_addr, client_id, subject, body_text, transid, userid)
    VALUES
        (:TOADDR, NULLIF(:CLIID,''), :SUBJ, :BODY, 'MAIL', :USR)
END-EXEC

IF SQLCODE = 0 THEN DO
    EXEC SQL COMMIT END-EXEC
    SCR.MESSAGE = 'MESSAGE QUEUED FOR DELIVERY.'
END
ELSE DO
    SCR.MESSAGE = 'QUEUE INSERT FAILED: ' || SQLCODE
END

EXEC CICS SEND MAP('MAIL1') FROM(SCR.) ERASE END-EXEC
EXEC CICS RETURN END-EXEC

EXIT
