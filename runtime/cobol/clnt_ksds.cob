      *> CLNT_KSDS -- Client KSDS inquiry (COBOL)
      *> Episode 03 -- EDM CICS Tutorial Series
      *>
      *> Demonstrates: EXEC CICS READ FILE, DFHRESP(NOTFND),
      *> CONVERSE MAP, pseudo-conversational RETURN.
      *>
      *> NOTE: BRICKS KSDS files are backed by bbolt on disk.
      *>       Define the file in CEDA FILE or bricks.cnf.
      *>       File name: EDMMST
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CLNT_KSDS.

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
          05 ER-STATUS      PIC X(1).
          05 FILLER         PIC X(46).

       01 SCR.
          05 HEADER     PIC X(60).
          05 CLIENTID   PIC X(8).
          05 CLTYPE     PIC X(1).
          05 RANK       PIC 99.
          05 LNAME      PIC X(20).
          05 FNAME      PIC X(15).
          05 DEPT       PIC X(20).
          05 LOC        PIC X(3).
          05 STATF      PIC X(1).
          05 MESSAGE    PIC X(60).
          05 FOOTER     PIC X(60).

       PROCEDURE DIVISION.
       MAIN.
           MOVE SPACES TO SCR.
           MOVE 'EDM CLIENT INQUIRY -- EDMMST' TO HEADER.
           MOVE 'ENTER CLIENT ID, PRESS ENTER.  PF3=EXIT'
               TO FOOTER.

           EXEC CICS CONVERSE MAP('CLNT1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           MOVE CLIENTID TO WS-KEY.
           MOVE SPACES TO MESSAGE.

           EXEC CICS READ FILE('EDMMST')
               INTO(EDM-REC)
               RIDFLD(WS-KEY)
               RESP(WS-RC)
           END-EXEC.

           EVALUATE WS-RC
               WHEN DFHRESP(NORMAL)
                   MOVE ER-CLIENT-TYPE TO CLTYPE
                   MOVE ER-RANK        TO RANK
                   MOVE ER-LAST-NAME   TO LNAME
                   MOVE ER-FIRST-NAME  TO FNAME
                   MOVE ER-DEPT        TO DEPT
                   MOVE ER-LOCATION    TO LOC
                   MOVE ER-STATUS      TO STATF
                   MOVE 'RECORD FOUND.' TO MESSAGE
               WHEN DFHRESP(NOTFND)
                   MOVE 'CLIENT NOT FOUND.' TO MESSAGE
               WHEN OTHER
                   MOVE 'FILE ERROR -- SEE BRICKS CONSOLE.' TO MESSAGE
           END-EVALUATE.

           EXEC CICS CONVERSE MAP('CLNT1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           EXEC CICS RETURN TRANSID('CLNT') IMMEDIATE END-EXEC.
           STOP RUN.
