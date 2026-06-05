      *> EMOR -- EDMORD acquisition order entry (COBOL)
      *> Episode 06 -- EDM CICS Tutorial Series
      *>
      *> Demonstrates: COMMAREA for pseudo-conversational state,
      *> multi-screen flow, EXEC SQL INSERT, EIBCALEN check.
      *>
      *> Screen 1: client ID and order type
      *> Screen 2: value, required date, notes -- confirm/cancel
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EMOR.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY DFHAID.
       COPY DFHRESP.
       COPY SQLCA.

       01 WS-PHASE   PIC 9(1) VALUE 0.

       01 SCR1.
          05 HEADER1    PIC X(60).
          05 CLIENTID   PIC X(8).
          05 ORDTYPE    PIC X(2).
          05 MSG1       PIC X(60).
          05 FOOTER1    PIC X(60).

       01 SCR2.
          05 HEADER2    PIC X(60).
          05 ORDVALUE   PIC 9(11)V99.
          05 REQDATE    PIC X(10).
          05 NOTES      PIC X(60).
          05 MSG2       PIC X(60).
          05 FOOTER2    PIC X(60).

       01 WS-ORDER-ID  PIC X(10).
       01 WS-TODAY     PIC X(10).

       *> COMMAREA layout -- carries state between pseudo-conversational
       *> invocations. BRICKS passes this through DFHCOMMAREA.
       01 CA-DATA.
          05 CA-PHASE    PIC 9(1).
          05 CA-CLIENTID PIC X(8).
          05 CA-ORDTYPE  PIC X(2).
          05 CA-ORDVALUE PIC 9(11)V99.
          05 CA-REQDATE  PIC X(10).
          05 CA-NOTES    PIC X(60).

       LINKAGE SECTION.
       01 DFHCOMMAREA   PIC X(96).

       PROCEDURE DIVISION.
       MAIN.
      *> Check if this is a new invocation or a continuation
           IF EIBCALEN = 0
               MOVE 1 TO CA-PHASE
               PERFORM PHASE-1
           ELSE
               MOVE DFHCOMMAREA TO CA-DATA
               EVALUATE CA-PHASE
                   WHEN 1 PERFORM PHASE-2
                   WHEN 2 PERFORM PHASE-COMMIT
                   WHEN OTHER
                       EXEC CICS RETURN END-EXEC
               END-EVALUATE
           END-IF.
           STOP RUN.

       PHASE-1.
           MOVE SPACES TO SCR1.
           MOVE 'EDM ORDER ENTRY -- SCREEN 1 OF 2' TO HEADER1.
           MOVE 'CLIENT ID + TYPE.  ENTER=Next  PF3=Cancel'
               TO FOOTER1.

           EXEC CICS CONVERSE MAP('EMOR1') FROM(SCR1) INTO(SCR1)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           MOVE CLIENTID TO CA-CLIENTID.
           MOVE ORDTYPE  TO CA-ORDTYPE.
           MOVE 2 TO CA-PHASE.

           EXEC CICS RETURN TRANSID('EMOR')
               COMMAREA(CA-DATA)
               LENGTH(96)
           END-EXEC.

       PHASE-2.
           MOVE SPACES TO SCR2.
           MOVE 'EDM ORDER ENTRY -- SCREEN 2 OF 2' TO HEADER2.
           MOVE 'VALUE + DATE + NOTES.  ENTER=Confirm  PF3=Cancel'
               TO FOOTER2.

           EXEC CICS CONVERSE MAP('EMOR2') FROM(SCR2) INTO(SCR2)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           MOVE ORDVALUE TO CA-ORDVALUE.
           MOVE REQDATE  TO CA-REQDATE.
           MOVE NOTES    TO CA-NOTES.
           MOVE 3 TO CA-PHASE.

           EXEC CICS RETURN TRANSID('EMOR')
               COMMAREA(CA-DATA)
               LENGTH(96)
           END-EXEC.

       PHASE-COMMIT.
           EXEC CICS ASKTIME END-EXEC.
           EXEC CICS FORMATTIME
               ABSTIME(EIBTIME)
               YYYYMMDD(WS-TODAY)
           END-EXEC.

      *> Build order ID: YYYYMMDD + first 2 chars of client ID
           STRING WS-TODAY(1:8) CA-CLIENTID(1:2)
               DELIMITED SIZE INTO WS-ORDER-ID.

           EXEC SQL
               INSERT INTO edm_orders
                   (order_id, client_id, order_type,
                    order_status, order_date, required_date,
                    order_value, notes)
               VALUES
                   (:WS-ORDER-ID, :CA-CLIENTID, :CA-ORDTYPE,
                    'P', CURRENT_DATE, :CA-REQDATE,
                    :CA-ORDVALUE, :CA-NOTES)
           END-EXEC.

           IF SQLCODE = 0
               MOVE 'ORDER SUBMITTED: ' TO MSG2
               STRING MSG2 WS-ORDER-ID DELIMITED SIZE INTO MSG2
           ELSE
               MOVE 'SQL ERROR -- ORDER NOT SAVED.' TO MSG2
           END-IF.

           EXEC SQL COMMIT END-EXEC.

           EXEC CICS SEND MAP('EMOR2') FROM(SCR2) ERASE END-EXEC.
           EXEC CICS RETURN END-EXEC.
