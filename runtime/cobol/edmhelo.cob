      *> EMHL -- EDM Welcome transaction (COBOL)
      *> Episode 01 -- EDM CICS Tutorial Series
      *> Ellison Digital Minerals Internal Systems
      *>
      *> Demonstrates: ASSIGN, SEND MAP FROM, RETURN.
      *> No SQL. No KSDS. Just a screen and a greeting.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EDMHELO.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 USR     PIC X(8).
       01 TRM     PIC X(4).

       01 SCR.
          05 BANNER   PIC X(60).
          05 USERID   PIC X(8).
          05 GREETING PIC X(40).
          05 ANNRANK  PIC X(20).
          05 FOOTER   PIC X(60).

       PROCEDURE DIVISION.
       MAIN.
           EXEC CICS ASSIGN USERID(USR) TERMID(TRM) END-EXEC.

           MOVE SPACES TO SCR.
           MOVE 'ELLISON DIGITAL MINERALS -- INTERNAL SYSTEMS'
               TO BANNER.
           MOVE USR TO USERID.
           MOVE 'WELCOME, ACQUISITION SPECIALIST.' TO GREETING.
           MOVE 'ANNOYANCE RANK: PENDING ASSESSMENT' TO ANNRANK.
           MOVE 'ENTER=Continue  PF3=Exit' TO FOOTER.

           EXEC CICS SEND MAP('EMHELO1') FROM(SCR) ERASE END-EXEC.

           EXEC CICS RETURN END-EXEC.
           STOP RUN.
