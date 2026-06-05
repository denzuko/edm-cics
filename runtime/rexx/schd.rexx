/* DPRSC -- Da Planet Radio show schedule (REXX)                   */
/* DPR subsystem -- closes issue #2                                */
/* ACL group: DPR (separate from EDM corporate groups)             */
/*                                                                 */
/* DPR_HOST persona: Tier B radio show host character.             */
/* Manages Da Planet Radio show schedule, playlist, and on-air     */
/* session logging. Not subject to Annoyance Rank. Probably.       */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER  = 'DA PLANET RADIO -- SHOW SCHEDULE'
SCR.USERID  = USR
SCR.FOOTER  = 'ENTER=View  PF1=Go Live  PF3=Exit'

EXEC CICS CONVERSE MAP('SCHD1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS RETURN END-EXEC
    EXIT
END

/* PF1: open on-air session */
IF EIBAID = 'PF01' THEN DO
    SHOWID = STRIP(SCR.SHOWID)
    EXEC SQL
        INSERT INTO dpr_oncall (show_id, host_userid)
        VALUES (:SHOWID, :USR)
    END-EXEC
    IF SQLCODE = 0 THEN DO
        EXEC SQL COMMIT END-EXEC
        SCR.MESSAGE = 'ON AIR. SESSION LOGGED.'
    END
    ELSE
        SCR.MESSAGE = 'SESSION LOG FAILED: ' || SQLCODE
    EXEC CICS SEND MAP('SCHD1') FROM(SCR.) ERASE END-EXEC
    EXEC CICS RETURN END-EXEC
    EXIT
END

/* Default: show inquiry */
SCR.SHOWNAME = ''
SCR.SHOWDAY  = ''
SCR.SHOWTIME = ''
SCR.SHOWSTAT = ''
SHOWID = STRIP(SCR.SHOWID)

EXEC SQL
    SELECT show_name, day_of_week, start_time, status
    INTO :SCR.SHOWNAME, :SCR.SHOWDAY, :SCR.SHOWTIME, :SCR.SHOWSTAT
    FROM dpr_shows
    WHERE show_id = :SHOWID
END-EXEC

IF SQLCODE = 0 THEN
    SCR.MESSAGE = 'SHOW FOUND.'
ELSE IF SQLCODE = 100 THEN
    SCR.MESSAGE = 'SHOW NOT FOUND.'
ELSE
    SCR.MESSAGE = 'SQL ERROR: ' || SQLCODE

EXEC CICS SEND MAP('SCHD1') FROM(SCR.) ERASE END-EXEC
EXEC CICS RETURN END-EXEC

EXIT
