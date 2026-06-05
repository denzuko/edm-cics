/* CLNT -- Client registry inquiry (REXX)                          */
/* Converted from COBOL: inquiry logic better suited to REXX       */
/* ACL: EDM, ADMIN                                                 */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER = 'CLIENT REGISTRY -- INQUIRY'
SCR.FOOTER = 'ENTER=Search  PF3=Menu  PF5=Update'

EXEC CICS CONVERSE MAP('CLNT1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

IF EIBAID = 'PF05' THEN DO
    EXEC CICS XCTL PROGRAM('CLNU') END-EXEC
    EXIT
END

CLIENTID = STRIP(SCR.CLIENTID)
SCR. = ''
SCR.CLIENTID = CLIENTID

EXEC SQL
    SELECT client_type, annoyance_rank,
           last_name || ', ' || first_name,
           department, location, status,
           asset_count, asset_value
    INTO :SCR.CLTYPE, :SCR.RANK,
         :SCR.CLNAME, :SCR.DEPT, :SCR.LOC, :SCR.STATF,
         :SCR.ASSETCT, :SCR.ASSETVAL
    FROM edm_clients
    WHERE client_id = :CLIENTID
END-EXEC

SELECT
    WHEN (SQLCODE = 0)   THEN SCR.MESSAGE = 'RECORD FOUND.'
    WHEN (SQLCODE = 100) THEN SCR.MESSAGE = 'CLIENT NOT FOUND.'
    OTHERWISE                 SCR.MESSAGE = 'SQL ERROR: ' || SQLCODE
END

SCR.FOOTER = 'ENTER=New Search  PF3=Menu  PF5=Update  PF6=Orders'

EXEC CICS CONVERSE MAP('CLNT1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF06' THEN DO
    EXEC CICS XCTL PROGRAM('ORDR') END-EXEC
    EXIT
END

EXEC CICS RETURN TRANSID('CLNT') IMMEDIATE END-EXEC

EXIT
