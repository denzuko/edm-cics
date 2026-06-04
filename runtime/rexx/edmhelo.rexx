/* EMHI -- EDM Welcome transaction (REXX)                          */
/* Episode 02 -- EDM CICS Tutorial Series                          */
/* Ellison Digital Minerals Internal Systems                       */
/*                                                                 */
/* REXX twin of EMHL. Demonstrates stem variable population,       */
/* ASSIGN, SEND MAP FROM(stem.), and RETURN.                       */
/* PFY NOTE: REXX stem variables map to COBOL 01-group children    */
/* by matching field names. SCR.BANNER populates BANNER in the map.*/

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.BANNER   = 'ELLISON DIGITAL MINERALS -- INTERNAL SYSTEMS'
SCR.USERID   = USR
SCR.GREETING = 'WELCOME, ACQUISITION SPECIALIST.'
SCR.ANNRANK  = 'ANNOYANCE RANK: PENDING ASSESSMENT'
SCR.FOOTER   = 'ENTER=Continue  PF3=Exit'

EXEC CICS SEND MAP('EMHELO1') FROM(SCR.) ERASE END-EXEC

EXEC CICS RETURN END-EXEC

EXIT
