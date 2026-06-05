      *> SECU -- User access control inquiry (COBOL)
      *>
      *> Displays the access control record for a given userid:
      *> authorized transaction groups, last login, failed auth
      *> attempts, account status. Admin-only.
      *>
      *> Demonstrates: ASSIGN USERID, SQL SELECT on edm_security,
      *> CONVERSE, PF3 exit.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SECU.

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
          05 MAXAUTH   PIC X(4).
          05 LASTVIOL  PIC X(10).
          05 VIOLCDSP  PIC ZZZ9.
          05 STATUSF   PIC X(1).
          05 MESSAGE   PIC X(60).
          05 FOOTER    PIC X(60).

       01 VIOLCNT  PIC S9(8) COMP.

       PROCEDURE DIVISION.
       MAIN.
           EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC.

           MOVE SPACES TO SCR.
           MOVE 'ACCESS CONTROL -- USER SECURITY INQUIRY' TO HEADER.
           MOVE USR TO USERID.
           MOVE 'ENTER=Lookup  PF3=Exit' TO FOOTER.

           EXEC SQL WHENEVER SQLERROR CONTINUE END-EXEC.

           EXEC SQL
               SELECT max_trans_auth,
                      last_violation, violation_count, status
               INTO :MAXAUTH,
                    :LASTVIOL, :VIOLCNT, :STATUSF
               FROM edm_security
               WHERE userid = :USR
           END-EXEC.

           EVALUATE SQLCODE
               WHEN SQL-OK
                   MOVE VIOLCNT TO VIOLCDSP
                   MOVE 'ACCESS RECORD FOUND.' TO MESSAGE
               WHEN SQL-NODATA
                   MOVE 'USER NOT IN SECURITY REGISTRY.' TO MESSAGE
               WHEN OTHER
                   MOVE 'SQL ERROR -- SEE BRICKS CONSOLE.' TO MESSAGE
           END-EVALUATE.

           EXEC CICS CONVERSE MAP('SECU1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           EXEC CICS RETURN END-EXEC.
           STOP RUN.
