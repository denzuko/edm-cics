      *> HLPD -- Helpdesk ticket entry (COBOL)
      *> Helpdesk subsystem -- closes issue #1
      *>
      *> NOTE: All tickets are logged and audited.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HLPD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY DFHAID.
       COPY DFHRESP.
       COPY SQLCA.

       01 USR          PIC X(8).
       01 TRM          PIC X(4).
       01 WS-TICKET-ID PIC X(10).

       01 SCR.
          05 HEADER     PIC X(60).
          05 CLIENTID   PIC X(8).
          05 PRIORITY   PIC X(1).
          05 CATEGORY   PIC X(20).
          05 SUBJECT    PIC X(60).
          05 DESCR      PIC X(120).
          05 MESSAGE    PIC X(60).
          05 FOOTER     PIC X(60).

       PROCEDURE DIVISION.
       MAIN.
           EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC.
           MOVE SPACES TO SCR.
           MOVE 'EDM HELPDESK -- NEW TICKET' TO HEADER.
           MOVE '3' TO PRIORITY.
           MOVE 'GENERAL' TO CATEGORY.
           MOVE 'ENTER=Submit  PF3=Cancel' TO FOOTER.

           EXEC CICS CONVERSE MAP('HLPD1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           EXEC SQL WHENEVER SQLERROR CONTINUE END-EXEC.

           EXEC SQL
               SELECT 'HD' || LPAD(NEXTVAL('edm_ticket_seq')::TEXT,8,'0')
               INTO :WS-TICKET-ID
           END-EXEC.

           IF SQLCODE <> 0
               MOVE 'HD00000001' TO WS-TICKET-ID
           END-IF.

           EXEC SQL
               INSERT INTO edm_tickets
                   (ticket_id, status, priority, category,
                    client_id, assigned_to, subject, description)
               VALUES
                   (:WS-TICKET-ID, 'O', :PRIORITY, :CATEGORY,
                    NULLIF(:CLIENTID, '        '), :USR,
                    :SUBJECT, :DESCR)
           END-EXEC.

           EVALUATE SQLCODE
               WHEN SQL-OK
                   EXEC SQL COMMIT END-EXEC
                   STRING 'TICKET OPENED: ' WS-TICKET-ID
                       DELIMITED SIZE INTO MESSAGE
               WHEN OTHER
                   MOVE 'INSERT FAILED -- SEE BRICKS CONSOLE.' TO MESSAGE
           END-EVALUATE.

           EXEC CICS SEND MAP('HLPD1') FROM(SCR) ERASE END-EXEC.
           EXEC CICS RETURN END-EXEC.
           STOP RUN.
