      *=================================================================*
      * EDMHELO - EDM Hello World Transaction                          *
      * TRANSID: HELO                                                  *
      * Episode 1 - EDM CICS Tutorial Series                          *
      * Ellison Digital Minerals Internal Systems                      *
      *=================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    EDMHELO.
       AUTHOR.        PFY-DARREN.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-USERID            PIC X(8)  VALUE SPACES.
       01  WS-SYSID             PIC X(4)  VALUE SPACES.
       01  WS-ABSTIME           PIC S9(15) COMP-3.
       01  WS-FORMATTED-DATE    PIC X(10) VALUE SPACES.
       01  WS-FORMATTED-TIME    PIC X(8)  VALUE SPACES.

       01  WS-BANNER.
           05  FILLER  PIC X(79) VALUE
      -        '  ELLISON DIGITAL MINERALS --- INTERNAL SYSTEMS'.
           05  FILLER  PIC X(79) VALUE
      -        '  Transaction Processing Environment v1.0'.
           05  FILLER  PIC X(79) VALUE SPACES.
       01  WS-BANNER-LEN        PIC S9(4) COMP VALUE 237.

       01  WS-LINE2.
           05  FILLER           PIC X(10) VALUE '  USERID: '.
           05  WS-L2-USERID     PIC X(8)  VALUE SPACES.
           05  FILLER           PIC X(10) VALUE '  SYSTEM: '.
           05  WS-L2-SYSID      PIC X(4)  VALUE SPACES.
           05  FILLER           PIC X(10) VALUE '  DATE:   '.
           05  WS-L2-DATE       PIC X(10) VALUE SPACES.
           05  FILLER           PIC X(10) VALUE '  TIME:   '.
           05  WS-L2-TIME       PIC X(8)  VALUE SPACES.
       01  WS-LINE2-LEN         PIC S9(4) COMP VALUE 70.

       01  WS-PROMPT            PIC X(40)
               VALUE '  Press any key to return to CICS...'.
       01  WS-PROMPT-LEN        PIC S9(4) COMP VALUE 40.

       01  WS-RECV-AREA         PIC X(1).
       01  WS-RECV-LEN          PIC S9(4) COMP VALUE 1.

       PROCEDURE DIVISION.

       MAIN-LOGIC.
      *----------------------------------------------------------------*
      * Get operator userid and system id                              *
      *----------------------------------------------------------------*
           EXEC CICS ASSIGN
               USERID(WS-USERID)
               SYSID(WS-SYSID)
           END-EXEC

      *----------------------------------------------------------------*
      * Get current date and time                                      *
      *----------------------------------------------------------------*
           EXEC CICS ASKTIME
               ABSTIME(WS-ABSTIME)
           END-EXEC

           EXEC CICS FORMATTIME
               ABSTIME(WS-ABSTIME)
               DDMMYYYY(WS-FORMATTED-DATE)
               TIME(WS-FORMATTED-TIME)
           END-EXEC

      *----------------------------------------------------------------*
      * Build display fields                                           *
      *----------------------------------------------------------------*
           MOVE WS-USERID         TO WS-L2-USERID
           MOVE WS-SYSID          TO WS-L2-SYSID
           MOVE WS-FORMATTED-DATE TO WS-L2-DATE
           MOVE WS-FORMATTED-TIME TO WS-L2-TIME

      *----------------------------------------------------------------*
      * Send banner — ERASE clears screen, FREEKB releases keyboard   *
      *----------------------------------------------------------------*
           EXEC CICS SEND TEXT
               FROM(WS-BANNER)
               LENGTH(WS-BANNER-LEN)
               ERASE
               FREEKB
           END-EXEC

      *----------------------------------------------------------------*
      * Send user information line (ACCUM accumulates with previous)  *
      *----------------------------------------------------------------*
           EXEC CICS SEND TEXT
               FROM(WS-LINE2)
               LENGTH(WS-LINE2-LEN)
               ACCUM
           END-EXEC

      *----------------------------------------------------------------*
      * Send prompt                                                    *
      *----------------------------------------------------------------*
           EXEC CICS SEND TEXT
               FROM(WS-PROMPT)
               LENGTH(WS-PROMPT-LEN)
               ACCUM
           END-EXEC

           EXEC CICS SEND PAGE
           END-EXEC

      *----------------------------------------------------------------*
      * Wait for any key                                               *
      *----------------------------------------------------------------*
           EXEC CICS RECEIVE
               INTO(WS-RECV-AREA)
               LENGTH(WS-RECV-LEN)
           END-EXEC

      *----------------------------------------------------------------*
      * Return control to CICS — MANDATORY                            *
      *----------------------------------------------------------------*
           EXEC CICS RETURN
           END-EXEC

           STOP RUN.
