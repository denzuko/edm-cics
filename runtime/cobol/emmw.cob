      *> EMMW -- EDMMST client add/update (COBOL)
      *> Episode 04 -- EDM CICS Tutorial Series
      *>
      *> Demonstrates: EXEC CICS WRITE FILE (new record),
      *> EXEC CICS REWRITE FILE (update), DFHRESP(DUPREC).
      *>
      *> PFY NOTE: WRITE fails with DUPREC if the key already exists.
      *>           Use REWRITE to update an existing record.
      *>           This transaction tries WRITE first; on DUPREC it
      *>           REWRITEs. That is the standard CICS insert-or-update
      *>           pattern.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EMMW.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY DFHAID.
       COPY DFHRESP.

       01 WS-RC      PIC S9(8) COMP.
       01 WS-KEY     PIC X(8).

       01 EDM-REC.
          05 ER-CLIENT-ID   PIC X(8).
          05 ER-CLIENT-TYPE PIC X(1).
          05 ER-RANK        PIC 99.
          05 ER-LAST-NAME   PIC X(20).
          05 ER-FIRST-NAME  PIC X(15).
          05 ER-DEPT        PIC X(20).
          05 ER-LOCATION    PIC X(3).
          05 ER-STATUS      PIC X(1)  VALUE 'P'.
          05 FILLER         PIC X(46) VALUE SPACES.

       01 SCR.
          05 HEADER     PIC X(60).
          05 CLIENTID   PIC X(8).
          05 CLTYPE     PIC X(1).
          05 RANK       PIC 99.
          05 LNAME      PIC X(20).
          05 FNAME      PIC X(15).
          05 DEPT       PIC X(20).
          05 LOC        PIC X(3).
          05 MESSAGE    PIC X(60).
          05 FOOTER     PIC X(60).

       PROCEDURE DIVISION.
       MAIN.
           MOVE SPACES TO SCR.
           MOVE 'EDM CLIENT ADD / UPDATE -- EMMMST' TO HEADER.
           MOVE 'FILL FIELDS AND PRESS ENTER.  PF3=EXIT' TO FOOTER.

           EXEC CICS CONVERSE MAP('EMMW1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           MOVE CLIENTID TO WS-KEY.
           MOVE CLIENTID TO ER-CLIENT-ID.
           MOVE CLTYPE   TO ER-CLIENT-TYPE.
           MOVE RANK     TO ER-RANK.
           MOVE LNAME    TO ER-LAST-NAME.
           MOVE FNAME    TO ER-FIRST-NAME.
           MOVE DEPT     TO ER-DEPT.
           MOVE LOC      TO ER-LOCATION.

           EXEC CICS WRITE FILE('EDMMST')
               FROM(EDM-REC)
               RIDFLD(WS-KEY)
               RESP(WS-RC)
           END-EXEC.

           EVALUATE WS-RC
               WHEN DFHRESP(NORMAL)
                   MOVE 'RECORD ADDED.' TO MESSAGE
               WHEN DFHRESP(DUPREC)
                   EXEC CICS REWRITE FILE('EDMMST')
                       FROM(EDM-REC)
                       RESP(WS-RC)
                   END-EXEC
                   IF WS-RC = DFHRESP(NORMAL)
                       MOVE 'RECORD UPDATED.' TO MESSAGE
                   ELSE
                       MOVE 'REWRITE FAILED -- SEE CONSOLE.' TO MESSAGE
                   END-IF
               WHEN OTHER
                   MOVE 'WRITE ERROR -- SEE BRICKS CONSOLE.' TO MESSAGE
           END-EVALUATE.

           EXEC CICS CONVERSE MAP('EMMW1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           EXEC CICS RETURN TRANSID('EMMW') IMMEDIATE END-EXEC.
           STOP RUN.
