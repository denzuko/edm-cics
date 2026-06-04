# Episode 1: Your First Transaction — EDMHELO
## EXEC CICS, BMS, and Why Hello World Takes 40 Lines

```
PREPARED BY:    Darren (PFY, IT Support)
NOTE FROM BOFH: I reviewed this. The Hello World example is
                adequate. The editorial asides are not sanctioned.
                Leave them in. Nobody reads documentation anyway.
```

---

## What We Are Building

`EDMHELO` — Transaction ID: `HELO`

A CICS transaction that:
1. Clears the 3270 screen
2. Displays the EDM corporate welcome banner
3. Displays the operator's USERID and current date/time
4. Waits for any key press, then returns to CICS

This is Hello World for mainframes. It is more involved than you expect
and less involved than BOFH's infrastructure documentation implies.

---

## CICS Concepts Introduced

### The transaction model

In CICS, a **transaction** is a unit of work initiated by a 4-character
**TRANSID**. When an operator types `HELO` at a 3270 terminal and
presses Enter, CICS:

1. Looks up `HELO` in the Program Control Table (PCT)
2. Finds the associated program name (`EDMHELO`)
3. Loads and executes `EDMHELO`
4. Returns control to CICS when the program issues EXEC CICS RETURN

### EXEC CICS

CICS programs interact with CICS services via `EXEC CICS` commands.
These look like COBOL but are preprocessed by the CICS translator
before compilation. The translator converts them to CALL statements
against the CICS runtime.

```cobol
EXEC CICS SEND TEXT
    FROM(WS-BANNER-TEXT)
    LENGTH(WS-BANNER-LEN)
    ERASE
    FREEKB
END-EXEC
```

This sends text to the terminal, erases the current screen contents,
and releases the keyboard so the operator can type.

### EXEC CICS ASSIGN

To get information about the current environment:

```cobol
EXEC CICS ASSIGN
    USERID(WS-USERID)
    SYSID(WS-SYSID)
END-EXEC
```

### EXEC CICS RETURN

Every CICS program **must** end with EXEC CICS RETURN.
Falling through the end of a CICS program is not the same as returning.
It will cause a transaction abend. BOFH will notice.

---

## The Program: EDMHELO.cbl

```cobol
      *=================================================================*
      * EDMHELO - EDM Hello World Transaction                           *
      * TRANSID: HELO                                                   *
      * Episode 1 - EDM CICS Tutorial Series                           *
      * Ellison Digital Minerals                                        *
      *=================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID.    EDMHELO.
       AUTHOR.        PFY - DARREN.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-USERID            PIC X(8)  VALUE SPACES.
       01  WS-SYSID             PIC X(4)  VALUE SPACES.
       01  WS-DATE.
           05  WS-DATE-YY       PIC 9(2).
           05  FILLER           PIC X(1)  VALUE '/'.
           05  WS-DATE-MM       PIC 9(2).
           05  FILLER           PIC X(1)  VALUE '/'.
           05  WS-DATE-DD       PIC 9(2).
       01  WS-TIME.
           05  WS-TIME-HH       PIC 9(2).
           05  FILLER           PIC X(1)  VALUE ':'.
           05  WS-TIME-MM       PIC 9(2).

       01  WS-ABSTIME           PIC S9(15) COMP-3.
       01  WS-FORMATTED-DATE    PIC X(10).
       01  WS-FORMATTED-TIME    PIC X(8).

       01  WS-BANNER.
           05  FILLER  PIC X(79) VALUE
               '  ELLISON DIGITAL MINERALS --- INTERNAL SYSTEMS'.
           05  FILLER  PIC X(79) VALUE
               '  Transaction Processing Environment v1.0'.
           05  FILLER  PIC X(79) VALUE SPACES.

       01  WS-BANNER-LEN        PIC S9(4) COMP VALUE 237.

       01  WS-LINE2.
           05  FILLER           PIC X(10) VALUE '  USERID: '.
           05  WS-L2-USERID     PIC X(8)  VALUE SPACES.
           05  FILLER           PIC X(10) VALUE '  SYSTEM: '.
           05  WS-L2-SYSID      PIC X(4)  VALUE SPACES.
           05  FILLER           PIC X(10) VALUE '  DATE:   '.
           05  WS-L2-DATE       PIC X(10) VALUE SPACES.
           05  FILLER           PIC X(10) VALUE '  TIME:   '.
           05  WS-L2-TIME       PIC X(8)  VALUE SPACES.
       01  WS-LINE2-LEN         PIC S9(4) COMP VALUE 70.

       01  WS-PROMPT.
           05  FILLER  PIC X(40)
               VALUE '  Press any key to return to CICS...'.
       01  WS-PROMPT-LEN        PIC S9(4) COMP VALUE 40.

       PROCEDURE DIVISION.

       MAIN-LOGIC.
      *    Get current user and system information
           EXEC CICS ASSIGN
               USERID(WS-USERID)
               SYSID(WS-SYSID)
           END-EXEC

      *    Get current date and time
           EXEC CICS ASKTIME
               ABSTIME(WS-ABSTIME)
           END-EXEC

           EXEC CICS FORMATTIME
               ABSTIME(WS-ABSTIME)
               DDMMYYYY(WS-FORMATTED-DATE)
               TIME(WS-FORMATTED-TIME)
           END-EXEC

      *    Populate display fields
           MOVE WS-USERID         TO WS-L2-USERID
           MOVE WS-SYSID          TO WS-L2-SYSID
           MOVE WS-FORMATTED-DATE TO WS-L2-DATE
           MOVE WS-FORMATTED-TIME TO WS-L2-TIME

      *    Send banner to terminal — ERASE clears the screen
           EXEC CICS SEND TEXT
               FROM(WS-BANNER)
               LENGTH(WS-BANNER-LEN)
               ERASE
               FREEKB
           END-EXEC

      *    Send user information line
           EXEC CICS SEND TEXT
               FROM(WS-LINE2)
               LENGTH(WS-LINE2-LEN)
               ACCUM
           END-EXEC

      *    Send prompt and wait for keypress
           EXEC CICS SEND TEXT
               FROM(WS-PROMPT)
               LENGTH(WS-PROMPT-LEN)
               ACCUM
           END-EXEC

           EXEC CICS SEND PAGE
           END-EXEC

      *    Receive (wait for any key)
           EXEC CICS RECEIVE
               FLENGTH(WS-BANNER-LEN)
           END-EXEC

      *    Return to CICS
           EXEC CICS RETURN
           END-EXEC

           STOP RUN.
```

---

## Compile and Link JCL

See `jcl/EDMHELO.jcl`. This JCL:

1. Runs the CICS translator (`DFHECP1$`) on `EDMHELO.cbl`
2. Compiles the translated source with IGYCRCTL
3. Link-edits the object into `EDM.LOADLIB`

Submit and verify RC=0 at every step.

---

## Define the Transaction in BRICKS_TS

In BRICKS_TS, add the transaction definition. This is equivalent to
a PCT entry in traditional CICS:

```
DEFINE TRANSACTION(HELO) PROGRAM(EDMHELO)
```

The exact syntax depends on your BRICKS_TS version.
Check the BRICKS_TS README at https://github.com/moshix/BRICKS_TS

---

## Run It

At a 3270 terminal connected to BRICKS_TS:

```
HELO
```

Press Enter. You should see the EDM banner, your USERID, and the
current date and time. Press any key to return.

If you get an `AICA` abend: your program looped. Check EXEC CICS RETURN.
If you get an `APCT` abend: the transaction is not defined. Define it.
If you get an `APCI` abend: the program is not in DFHRPL. Check EDMLOAD.

---

## What Just Happened

You wrote and executed a CICS transaction. The key concepts:

- `EXEC CICS ASSIGN` — query the CICS environment
- `EXEC CICS ASKTIME` / `FORMATTIME` — get formatted date/time
- `EXEC CICS SEND TEXT` — write to the 3270 terminal
- `EXEC CICS RECEIVE` — wait for terminal input
- `EXEC CICS RETURN` — give control back to CICS

In Episode 2 we replace the SEND TEXT approach with BMS maps —
structured 3270 screen definitions that handle field positioning,
attributes, and cursor movement properly.

---

> *PFY NOTE: The BOFH told me to tell you that if your Hello World
> takes more than 20 minutes to compile, you have a JCL error.
> He is correct. Check your SYSLIB concatenation.*
