      *> EMRP -- EDMRPT management reporting (COBOL)
      *> Episode 10 -- EDM CICS Tutorial Series
      *>
      *> PHB NOTE: This is the Management Dashboard. It shows key
      *>           performance indicators for the acquisition pipeline.
      *>           I have been assured by IT that these numbers are
      *>           accurate. Please do not ask follow-up questions.
      *>
      *> PFY NOTE: What this actually does is run three aggregate SQL
      *>           queries and display the results on one screen.
      *>           Browse (STARTBR/READNEXT) is demonstrated against
      *>           the edm_orders table for the recent orders list.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EMRP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY DFHAID.
       COPY DFHRESP.
       COPY SQLCA.

       01 WS-RC         PIC S9(8) COMP.

       *> Aggregate counters
       01 WS-TOTAL-CLIENTS  PIC S9(9) COMP.
       01 WS-ACTIVE-ORDERS  PIC S9(9) COMP.
       01 WS-TOTAL-VALUE    NUMERIC(15,2).
       01 WS-HIGH-RANK      PIC S9(4) COMP.

       *> Browse: most recent order
       01 WS-ORD-ID     PIC X(10).
       01 WS-ORD-CLI    PIC X(8).
       01 WS-ORD-TYPE   PIC X(2).
       01 WS-ORD-VAL    NUMERIC(15,2).
       01 WS-ORD-STAT   PIC X(1).

       01 SCR.
          05 HEADER      PIC X(60).
          05 TOTCLI      PIC ZZZZ9.
          05 ACTORD      PIC ZZZZ9.
          05 TOTVAL      PIC Z(11)9.99.
          05 HIRANK      PIC Z9.
          05 ORD1ID      PIC X(10).
          05 ORD1CLI     PIC X(8).
          05 ORD1TYPE    PIC X(2).
          05 ORD1VAL     PIC Z(9)9.99.
          05 ORD1STAT    PIC X(1).
          05 FOOTER      PIC X(60).

       PROCEDURE DIVISION.
       MAIN.
           MOVE SPACES TO SCR.
           MOVE 'EDM MANAGEMENT DASHBOARD -- EMRPT' TO HEADER.
           MOVE 'ENTER=Refresh  PF3=Exit' TO FOOTER.

           EXEC SQL WHENEVER SQLERROR CONTINUE END-EXEC.

      *> Count active clients
           EXEC SQL
               SELECT COUNT(*) INTO :WS-TOTAL-CLIENTS
               FROM edm_clients WHERE status = 'A'
           END-EXEC.
           IF SQLCODE = 0 MOVE WS-TOTAL-CLIENTS TO TOTCLI.

      *> Count pending/active orders
           EXEC SQL
               SELECT COUNT(*) INTO :WS-ACTIVE-ORDERS
               FROM edm_orders WHERE order_status IN ('P','A')
           END-EXEC.
           IF SQLCODE = 0 MOVE WS-ACTIVE-ORDERS TO ACTORD.

      *> Total pipeline value
           EXEC SQL
               SELECT COALESCE(SUM(order_value),0) INTO :WS-TOTAL-VALUE
               FROM edm_orders WHERE order_status IN ('P','A')
           END-EXEC.
           IF SQLCODE = 0 MOVE WS-TOTAL-VALUE TO TOTVAL.

      *> Highest annoyance rank
           EXEC SQL
               SELECT COALESCE(MAX(annoyance_rank),0)
               INTO :WS-HIGH-RANK
               FROM edm_clients WHERE status = 'A'
           END-EXEC.
           IF SQLCODE = 0 MOVE WS-HIGH-RANK TO HIRANK.

      *> Most recent order via browse
           EXEC SQL
               SELECT order_id, client_id, order_type,
                      order_value, order_status
               INTO :WS-ORD-ID, :WS-ORD-CLI, :WS-ORD-TYPE,
                    :WS-ORD-VAL, :WS-ORD-STAT
               FROM edm_orders
               ORDER BY order_date DESC
               LIMIT 1
           END-EXEC.

           IF SQLCODE = 0
               MOVE WS-ORD-ID   TO ORD1ID
               MOVE WS-ORD-CLI  TO ORD1CLI
               MOVE WS-ORD-TYPE TO ORD1TYPE
               MOVE WS-ORD-VAL  TO ORD1VAL
               MOVE WS-ORD-STAT TO ORD1STAT
           END-IF.

           EXEC CICS CONVERSE MAP('EMRP1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           EXEC CICS RETURN TRANSID('EMRP') IMMEDIATE END-EXEC.
           STOP RUN.
