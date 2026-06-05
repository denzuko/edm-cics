/* EMLI -- EXEC CICS LINK demonstration (REXX)                     */
/* Episode 07 -- EDM CICS Tutorial Series                          */
/* Ellison Digital Minerals Internal Systems                       */
/*                                                                 */
/* Demonstrates: EXEC CICS LINK PROGRAM COMMAREA to call a        */
/* subordinate program synchronously. The called program          */
/* (EMLIWORK) performs the SQL lookup; this program handles       */
/* the screen I/O. Separation of business logic from presentation.*/

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER  = 'EDM LINKED PROGRAM DEMO -- EMLI'
SCR.USERID  = USR
SCR.FOOTER  = 'ENTER=Lookup  PF3=Exit'

EXEC CICS CONVERSE MAP('EMLI1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS RETURN END-EXEC
    EXIT
END

/* Build COMMAREA: 8-byte client ID + 60-byte result area */
CA = LEFT(SCR.CLIENTID, 8)
CA = CA || COPIES(' ', 60)

EXEC CICS LINK PROGRAM('EMLIWORK')
               COMMAREA(CA)
               LENGTH(68)
END-EXEC

/* Result is in the last 60 bytes of COMMAREA */
SCR.RESULT = SUBSTR(CA, 9, 60)

EXEC CICS CONVERSE MAP('EMLI1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

EXEC CICS RETURN END-EXEC

EXIT
