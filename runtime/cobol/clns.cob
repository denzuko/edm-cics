      *> CLNS -- Client SQL lookup (COBOL)
      *> Episode 05 -- EDM CICS Tutorial Series
      *>
      *> Operator types a CLIENT_ID; program runs SELECT INTO against
      *> the edm.edm_clients table and displays the result.
      *> Database binding: transactions.conf 5th field = edm
      *>
      *> SQLCODE values:
      *>   0     OK -- record found
      *>  +100   no row with that CLIENT_ID
      *>   -1    SQL not configured in bricks.cnf
      *>  -204   edm_clients table not found (run EDM-DDL.sql first)
      *>  -911   deadlock -- retry
      *>  -924   Postgres connection lost
      *>  -952   query timed out
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CLNS.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY DFHAID.
       COPY DFHRESP.
       COPY SQLCA.

       01 TRM PIC X(8).
       01 NMIND PIC S9(8).

       01 SCR.
          05 TERMID    PIC X(8).
          05 CLIENTID  PIC X(8).
          05 CLNAME    PIC X(35).
          05 DEPT      PIC X(20).
          05 RANK      PIC X(2).
          05 STATUS    PIC X(1).
          05 SQLCD     PIC X(8).
          05 SQLERR    PIC X(60).
          05 FOOTER    PIC X(60).

       PROCEDURE DIVISION.
       MAIN.
           EXEC CICS ASSIGN TERMID(TRM) END-EXEC.
           MOVE SPACES TO SCR.
           MOVE TRM TO TERMID.
           MOVE 'ENTER=Search  PF3=Exit' TO FOOTER.

           EXEC CICS CONVERSE MAP('CLNS1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           IF EIBAID = PF03
               EXEC CICS RETURN END-EXEC
               STOP RUN
           END-IF.

           EXEC SQL WHENEVER SQLERROR CONTINUE END-EXEC.

           EXEC SQL
               SELECT last_name || ', ' || first_name,
                      department,
                      risk_tier,
                      status
               INTO :CLNAME :NMIND,
                    :DEPT,
                    :RANK,
                    :STATUS
               FROM edm_clients
               WHERE client_id = :CLIENTID
           END-EXEC.

           MOVE SQLCODE TO SQLCD.
           MOVE SPACES TO SQLERR.

           EVALUATE SQLCODE
               WHEN SQL-OK
                   IF NMIND = -1
                       MOVE '(name is NULL)' TO CLNAME
                   END-IF
                   MOVE 'OK' TO SQLERR
               WHEN SQL-NODATA
                   MOVE 'CLIENT NOT FOUND.' TO SQLERR
                   MOVE SPACES TO CLNAME
               WHEN SQL-NOCONFIG
                   MOVE 'SQL NOT CONFIGURED IN BRICKS.CNF' TO SQLERR
               WHEN SQL-UNDEF-TBL
                   MOVE 'TABLE edm_clients NOT FOUND. RUN EDM-DDL.SQL'
                       TO SQLERR
               WHEN SQL-CONNLOST
                   MOVE 'LOST POSTGRES CONNECTION.' TO SQLERR
               WHEN SQL-TIMEOUT
                   MOVE 'QUERY TIMED OUT.' TO SQLERR
               WHEN SQL-DEADLOCK
                   MOVE 'DEADLOCK -- RETRY.' TO SQLERR
               WHEN OTHER
                   MOVE 'SQL ERROR -- SEE BRICKS CONSOLE LOG.' TO SQLERR
           END-EVALUATE.

           EXEC CICS CONVERSE MAP('CLNS1') FROM(SCR) INTO(SCR)
                              ERASE END-EXEC.

           EXEC CICS RETURN END-EXEC.
           STOP RUN.
