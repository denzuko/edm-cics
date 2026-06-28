/* MLIB -- Music library inquiry (REXX)                            */
/* DPR back-office -- ACL: DPR, ADMIN                              */
/*                                                                 */
/* Search and display music library catalog.                       */
/* PF5=Add/Update (MLBU)  PF3=Menu                                 */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER  = 'DPR MUSIC LIBRARY'
SCR.USERID  = USR
SCR.FOOTER  = 'ENTER=Search  PF5=Add/Update  PF3=Menu'

EXEC CICS CONVERSE MAP('MLIB1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

IF EIBAID = 'PF05' THEN DO
    EXEC CICS XCTL PROGRAM('MLBU') END-EXEC
    EXIT
END

SEARCH = STRIP(SCR.SEARCH)

EXEC SQL
    SELECT track_id, title, artist, duration_secs,
           category, status, media_type,
           TO_CHAR(last_played,'YYYY-MM-DD')
    INTO :SCR.TRACKID, :SCR.TITLE, :SCR.ARTIST, :SCR.DURSECS,
         :SCR.CATEGORY, :SCR.STATF, :SCR.MTYPE, :SCR.LASTPLAY
    FROM dpr_music_library
    WHERE (title  ILIKE '%' || :SEARCH || '%'
       OR  artist ILIKE '%' || :SEARCH || '%'
       OR  track_id = :SEARCH)
    ORDER BY last_played ASC NULLS FIRST
    LIMIT 1
END-EXEC

SELECT
    WHEN (SQLCODE = 0)   THEN SCR.MESSAGE = 'FOUND.'
    WHEN (SQLCODE = 100) THEN SCR.MESSAGE = 'NOT FOUND.'
    OTHERWISE                 SCR.MESSAGE = 'SQL ERROR: ' || SQLCODE
END

EXEC CICS CONVERSE MAP('MLIB1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

EXEC CICS RETURN TRANSID('MLIB') IMMEDIATE END-EXEC
EXIT
