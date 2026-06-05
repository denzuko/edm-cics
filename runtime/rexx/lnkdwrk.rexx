/* EMLIWORK -- linked worker program for EMLI (REXX)               */
/* Episode 07 -- EDM CICS Tutorial Series                          */
/*                                                                 */
/* Called via EXEC CICS LINK from EMLI. Receives a COMMAREA with  */
/* CLIENT_ID in bytes 1-8; writes the lookup result into bytes    */
/* 9-68. Never sends to the terminal directly.                     */
/*                                                                 */
/* NOTE: linked programs share the same terminal and task as      */
/* the calling program but have their own variable scope.         */
/* COMMAREA is the only way to pass data back to the caller.      */

ADDRESS CICS

/* Extract client ID from COMMAREA */
CLIENTID = LEFT(DFHCOMMAREA, 8)
RESULT   = COPIES(' ', 60)

EXEC SQL
    SELECT last_name || ', ' || first_name || ' [' || status || ']'
    INTO :RESULT
    FROM edm_clients
    WHERE client_id = :CLIENTID
END-EXEC

IF SQLCODE <> 0 THEN DO
    IF SQLCODE = 100 THEN
        RESULT = 'CLIENT NOT FOUND.'
    ELSE
        RESULT = 'SQL ERROR: ' || SQLCODE
END

/* Write result back into COMMAREA bytes 9-68 */
DFHCOMMAREA = LEFT(DFHCOMMAREA, 8) || LEFT(RESULT, 60)

EXEC CICS RETURN END-EXEC

EXIT
