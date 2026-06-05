/* TRAF -- Traffic log view and build (REXX)                       */
/* DPR back-office -- ACL: DPR, ADMIN                              */
/*                                                                 */
/* Displays the traffic log for a given date/show.                 */
/* PF1=Build log from orders  PF2=Export to Liquidsoap             */
/* PF3=Menu  PF5=Mark aired                                        */

ADDRESS CICS

EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC

SCR. = ''
SCR.HEADER = 'DPR TRAFFIC LOG'
SCR.USERID = USR
SCR.LOGDATE = DATE('S')  /* YYYYMMDD */
SCR.SHOWID  = 'DPRMAIN '
SCR.FOOTER  = 'ENTER=View  PF1=Build  PF2=Export  PF3=Menu'

EXEC CICS CONVERSE MAP('TRAF1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

LOGDATE = STRIP(SCR.LOGDATE)
SHOWID  = STRIP(SCR.SHOWID)

/* PF1: build traffic log from active orders for this date */
IF EIBAID = 'PF01' THEN DO
    EXEC SQL
        INSERT INTO dpr_traffic
            (log_date, show_id, position, scheduled_time,
             content_type, content_id, content_title, duration_secs)
        SELECT
            :LOGDATE::DATE,
            o.show_id,
            ROW_NUMBER() OVER (ORDER BY s.spot_id),
            '00:00'::TIME + (ROW_NUMBER() OVER (ORDER BY s.spot_id) * INTERVAL '30 minutes'),
            'SPOT',
            s.spot_id,
            s.spot_title,
            s.duration_secs
        FROM dpr_traffic_orders o
        JOIN dpr_spots s ON s.spot_id = o.spot_id
        WHERE o.status    = 'A'
          AND o.flight_start <= :LOGDATE::DATE
          AND o.flight_end   >= :LOGDATE::DATE
          AND (o.show_id = :SHOWID OR o.show_id IS NULL)
        ON CONFLICT (log_date, show_id, position) DO NOTHING
    END-EXEC
    IF SQLCODE = 0 THEN DO
        EXEC SQL COMMIT END-EXEC
        SCR.MESSAGE = 'TRAFFIC LOG BUILT.'
    END
    ELSE SCR.MESSAGE = 'BUILD FAILED: ' || SQLCODE
    EXEC CICS SEND MAP('TRAF1') FROM(SCR.) ERASE END-EXEC
    EXEC CICS RETURN TRANSID('TRAF') IMMEDIATE END-EXEC
    EXIT
END

/* Default: display log entries */
SCR.L1DATE = '' ; SCR.L1TIME = '' ; SCR.L1TYPE = '' ; SCR.L1TITLE = ''
SCR.L2DATE = '' ; SCR.L2TIME = '' ; SCR.L2TYPE = '' ; SCR.L2TITLE = ''
SCR.L3DATE = '' ; SCR.L3TIME = '' ; SCR.L3TYPE = '' ; SCR.L3TITLE = ''
SCR.L4DATE = '' ; SCR.L4TIME = '' ; SCR.L4TYPE = '' ; SCR.L4TITLE = ''
SCR.L5DATE = '' ; SCR.L5TIME = '' ; SCR.L5TYPE = '' ; SCR.L5TITLE = ''

EXEC SQL DECLARE TRAF_CUR CURSOR FOR
    SELECT TO_CHAR(scheduled_time,'HH24:MI'),
           content_type,
           LEFT(content_title, 30),
           status
    FROM   dpr_traffic
    WHERE  log_date = :LOGDATE::DATE
      AND  show_id  = :SHOWID
    ORDER  BY position
    LIMIT  5
END-EXEC

EXEC SQL OPEN TRAF_CUR END-EXEC

DO I = 1 TO 5
    EXEC SQL FETCH TRAF_CUR INTO :FTIME, :FTYPE, :FTITLE, :FSTAT END-EXEC
    IF SQLCODE <> 0 THEN LEAVE
    SCR.('L'||I||'TIME')  = FTIME
    SCR.('L'||I||'TYPE')  = FTYPE
    SCR.('L'||I||'TITLE') = FTITLE
END

EXEC SQL CLOSE TRAF_CUR END-EXEC
SCR.MESSAGE = ''

EXEC CICS CONVERSE MAP('TRAF1') FROM(SCR.) INTO(SCR.) ERASE END-EXEC

IF EIBAID = 'PF03' THEN DO
    EXEC CICS XCTL PROGRAM('MENU') END-EXEC
    EXIT
END

EXEC CICS RETURN TRANSID('TRAF') IMMEDIATE END-EXEC
EXIT
