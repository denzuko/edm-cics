      *> SQLCA -- SQL Communications Area copybook for BRICKS EXEC SQL
      *> Include with: COPY SQLCA.
      *> BRICKS writes SQLCODE and SQLSTATE after every EXEC SQL.
       01 SQLCA.
          05 SQLCAID    PIC X(8)       VALUE 'SQLCA   '.
          05 SQLCABC    PIC S9(9) COMP VALUE 136.
          05 SQLCODE    PIC S9(9) COMP.
          05 SQLERRM.
             10 SQLERRML PIC S9(4) COMP.
             10 SQLERRMC PIC X(70).
          05 SQLERRP    PIC X(8).
          05 SQLERRD    PIC S9(9) COMP OCCURS 6 TIMES.
          05 SQLWARN.
             10 SQLWARN0 PIC X(1).
             10 SQLWARN1 PIC X(1).
             10 SQLWARN2 PIC X(1).
             10 SQLWARN3 PIC X(1).
             10 SQLWARN4 PIC X(1).
             10 SQLWARN5 PIC X(1).
             10 SQLWARN6 PIC X(1).
             10 SQLWARN7 PIC X(1).
          05 SQLSTATE   PIC X(5).
      *> Named constants for EVALUATE SQLCODE
       01 SQL-OK          PIC S9(9) COMP VALUE 0.
       01 SQL-NODATA      PIC S9(9) COMP VALUE 100.
       01 SQL-NOCONFIG    PIC S9(9) COMP VALUE -1.
       01 SQL-MULTIPLEROWS PIC S9(9) COMP VALUE -811.
       01 SQL-DEADLOCK    PIC S9(9) COMP VALUE -911.
       01 SQL-CONNLOST    PIC S9(9) COMP VALUE -924.
       01 SQL-TIMEOUT     PIC S9(9) COMP VALUE -952.
       01 SQL-UNDEF-TBL   PIC S9(9) COMP VALUE -204.
