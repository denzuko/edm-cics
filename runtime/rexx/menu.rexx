/* MENU -- org-aware master menu dispatch                          */
/* Entry point after CSSN sign-on                                  */
/* ACL: PUBLIC (all authenticated users)                           */
/*                                                                 */
/* Reads the operator's session context, determines their primary  */
/* org group, and presents the appropriate menu. Dispatches to     */
/* subsystem transactions via EXEC CICS XCTL.                      */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

/* Determine org from ACL group membership */
/* BRICKS populates EIBSIG with the user's first matching group   */
/* We check in priority order: ADMIN > EDM > DPR > HLPD > PUBLIC */

ORG = 'PUBLIC'

EXEC SQL
    SELECT grp INTO :ORG
    FROM sys_user_orgs
    WHERE userid = :USR
    AND grp IN ('ADMIN','EDM','DPR','HLPD','CMDB')
    ORDER BY CASE grp
        WHEN 'ADMIN' THEN 1
        WHEN 'EDM'   THEN 2
        WHEN 'DPR'   THEN 3
        WHEN 'HLPD'  THEN 4
        WHEN 'CMDB'  THEN 5
        ELSE 9 END
    LIMIT 1
END-EXEC

IF SQLCODE <> 0 THEN ORG = 'PUBLIC'

SCR. = ''
SCR.USERID  = USR
SCR.ORG     = ORG

SELECT
    WHEN (ORG = 'EDM' | ORG = 'ADMIN') THEN DO
        SCR.HEADER = 'ELLISON DIGITAL MINERALS -- MAIN MENU'
        SCR.OPT1   = '1. Client Registry     (CLNT)'
        SCR.OPT2   = '2. Order Management    (ORDN)'
        SCR.OPT3   = '3. Helpdesk            (HLPD)'
        SCR.OPT4   = '4. Reports             (REPT)'
        SCR.OPT5   = '5. Mail Dispatch       (MAIL)'
        SCR.FOOTER = 'SELECT OPTION OR TYPE TRANSID DIRECTLY'
    END
    WHEN (ORG = 'DPR') THEN DO
        SCR.HEADER = 'DA PLANET RADIO -- BACK OFFICE MENU'
        SCR.OPT1   = '1. Show Schedule       (SCHD)'
        SCR.OPT2   = '2. Traffic Log         (TRAF)'
        SCR.OPT3   = '3. Music Library       (MLIB)'
        SCR.OPT4   = '4. Advertiser CRM      (ADVT)'
        SCR.OPT5   = '5. Traffic Billing     (TBIL)'
        SCR.FOOTER = 'SELECT OPTION OR TYPE TRANSID DIRECTLY'
    END
    WHEN (ORG = 'HLPD') THEN DO
        SCR.HEADER = 'HELPDESK CONSOLE'
        SCR.OPT1   = '1. New Ticket          (HLPD)'
        SCR.OPT2   = '2. View/Update Ticket  (HDVW)'
        SCR.OPT3   = '3. Client Lookup       (CLNT)'
        SCR.OPT4   = '4. CMDB Inquiry        (CMDB)'
        SCR.OPT5   = ''
        SCR.FOOTER = 'SELECT OPTION OR TYPE TRANSID DIRECTLY'
    END
    OTHERWISE DO
        SCR.HEADER = 'SYSTEM MENU'
        SCR.OPT1   = '1. Helpdesk            (HLPD)'
        SCR.OPT2   = '2. Mail                (MAIL)'
        SCR.OPT3   = ''
        SCR.OPT4   = ''
        SCR.OPT5   = ''
        SCR.FOOTER = 'CONTACT ADMINISTRATOR FOR ACCESS'
    END
END

EXEC CICS CONVERSE MAP('MENU1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS RETURN END-EXEC
    EXIT
END

/* Dispatch by option number or direct TRANSID input */
OPT = STRIP(SCR.OPTION)

DISPATCH = ''
SELECT
    WHEN (ORG = 'EDM' | ORG = 'ADMIN') THEN DO
        SELECT
            WHEN (OPT = '1') THEN DISPATCH = 'CLNT'
            WHEN (OPT = '2') THEN DISPATCH = 'ORDN'
            WHEN (OPT = '3') THEN DISPATCH = 'HLPD'
            WHEN (OPT = '4') THEN DISPATCH = 'REPT'
            WHEN (OPT = '5') THEN DISPATCH = 'MAIL'
            OTHERWISE             DISPATCH = OPT
        END
    END
    WHEN (ORG = 'DPR') THEN DO
        SELECT
            WHEN (OPT = '1') THEN DISPATCH = 'SCHD'
            WHEN (OPT = '2') THEN DISPATCH = 'TRAF'
            WHEN (OPT = '3') THEN DISPATCH = 'MLIB'
            WHEN (OPT = '4') THEN DISPATCH = 'ADVT'
            WHEN (OPT = '5') THEN DISPATCH = 'TBIL'
            OTHERWISE             DISPATCH = OPT
        END
    END
    WHEN (ORG = 'HLPD') THEN DO
        SELECT
            WHEN (OPT = '1') THEN DISPATCH = 'HLPD'
            WHEN (OPT = '2') THEN DISPATCH = 'HDVW'
            WHEN (OPT = '3') THEN DISPATCH = 'CLNT'
            WHEN (OPT = '4') THEN DISPATCH = 'CMDB'
            OTHERWISE             DISPATCH = OPT
        END
    END
    OTHERWISE DISPATCH = OPT
END

IF LENGTH(STRIP(DISPATCH)) = 4 THEN DO
    EXEC CICS XCTL PROGRAM(DISPATCH) END-EXEC
END

EXEC CICS RETURN TRANSID('MENU') IMMEDIATE END-EXEC

EXIT
