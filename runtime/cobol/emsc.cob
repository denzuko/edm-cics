      *> EMSC -- EDMSEC Annoyance Rank lookup (COBOL)
      *> Episode 08 -- EDM CICS Tutorial Series
      *> Ellison Digital Minerals Internal Systems
      *>
      *> BOFH NOTE: This transaction checks your Annoyance Rank.
      *>            If it is >= 7 you should not be running this.
      *>            If you are running this and your rank is >= 7,
      *>            that itself is an Annoyance Rank event.
      *>
      *> Demonstrates: ASSIGN USERID, SQL SELECT on edm_security,
      *> role-based access check, CONVERSE.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EMSC.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY DFHAID.
       COPY DFHRESP.
       COPY SQLCA.

       01 USR   PIC X(8).
       01 TRM   PIC X(4).

       01 SCR.
          05 HEADER    PIC X(60).
          05 USERID    PIC X(8).
          05 RANK      PIC S9(4) COMP.
          05 RANKDSP   PIC Z9.
          05 MAXAUTH   PIC X(4).
          05 LASTVIOL  PIC X(10).
          05 VIOLCNT   PIC S9(8) COMP.
          05 VIOLCDSP  PIC ZZZ9.
          05 STATUSF   PIC X(1).
          05 MESSAGE   PIC X(60).
          05 FOOTER    PIC X(60).

       PROCEDURE DIVISION.
       MAIN.
           EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC.

           MOVE SPACES TO SCR.
           MOVE 'EDM SECURITY -- ANNOYANCE RANK INQUIRY' TO HEADER.
           MOVE USR TO USERID.
           MOVE 'ENTER=Lookup  PF3=Exit' TO FOOTER.

           EXEC SQL WHENEVER SQLERROR CONTINUE END-EXEC.

           EXEC SQL
               SELECT annoyance_rank, max_trans_auth,
                      last_violation, violation_count, status
               INTO :RANK, :MAXAUTH,
                    :LASTVIOL, :VIOLCNT, :STATUSF
               FROM edm_security
               WHERE userid = :USR
           END-EXEC.

           EVALUATE SQLCODE
               WHEN SQL-OK
                   MOVE RANK   TO RANKDSP
                   MOVE VIOLCNT TO VIOLCDSP
                   IF RANK >= 7
                       MOVE 'ELEVATED -- ADMINISTRATOR NOTIFIED'
                           TO MESSAGE
                   ELSE
                       MOVE 'WITHIN ACCEPTABLE PARAMETERS' TO MESSAGE
                   END-IF
               WHEN SQL-NODATA
                   MOVE 'USER NOT IN SECURITY REGISTRY.' TO MESSAGE
               WHEN OTHER
                   MOVE 'SQL ERROR -- BOFH HAS BEEN NOTIFIED.' TO MESSAGE
           END-EVALUATE.

           EXEC CICS CONVERSE MAP('EMSC1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           EXEC CICS RETURN END-EXEC.
           STOP RUN.
