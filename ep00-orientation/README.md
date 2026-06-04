# Episode 0: Orientation
## BRICKS_TS Installation and EDM Infrastructure Setup

```
PREPARED BY:    B. O. F. H., Systems Administration
AUDIENCE:       Developers who apparently need this explained
TONE:           Informational. Do not test me.
```

---

## What BRICKS_TS Is

[BRICKS_TS](https://github.com/moshix/BRICKS_TS) is a CICS-compatible
transaction server written in COBOL by moshix. It runs on MVS 3.8j,
provides EXEC CICS API compatibility, supports VSAM file control, and
does not require a software license that costs more than your car.

The CEO mandated mainframe infrastructure in 2026 for three reasons:

1. Legacy systems carry legacy truth.
2. Nobody has a rootkit for a 1970s instruction set.
3. The 6502 does not phone home.

You are here because you will be writing CICS transactions for the EDM
business systems. This episode gets you to a running BRICKS_TS
environment. Subsequent episodes assume this works.

If it does not work, you have made an error. Reread this document.

---

## Step 1: Hercules and TK5

EDM development runs on Hercules — an open-source IBM System/370
emulator. The standard distribution is TK5 (Tur(n)key 5), a preconfigured
MVS 3.8j image with COBOL, JCL, and TSO already working.

### Install Hercules

```sh
# Ubuntu/Debian
sudo apt-get install hercules

# macOS
brew install hercules

# Build from source (if you distrust package managers, which is correct)
git clone https://github.com/SDL-Hercules-390/hyperion.git
cd hyperion && ./configure && make && sudo make install
```

### Download TK5

```
https://wotho.ethz.ch/tk5/
```

Unpack to a working directory. You should have:
- `hercules.cnf` — Hercules configuration
- `dasd/` — disk images
- `mvs/` — MVS starter scripts

### IPL MVS

```sh
cd tk5
./mvs
```

Wait for the console to show `IEF234I OPERATOR REPLY` or similar.
You have an MVS system.

Connect with your 3270 emulator on port 3270:

```sh
x3270 localhost:3270
```

---

## Step 2: Install BRICKS_TS

BRICKS_TS source is at https://github.com/moshix/BRICKS_TS

The installation JCL is in this episode's `jcl/` directory.

### Upload source to MVS

Use `hercules` file transfer or IND$FILE via the 3270 connection.
The provided JCL assumes source in `BRICKS.SOURCE` PDS.

### Compile and link

```jcl
// EXEC BRICKSBL
```

See `jcl/BRICKSBL.jcl` for the full compile/link procedure.

### Start BRICKS_TS

Add the BRICKS_TS started task to your proclib and start it:

```
S BRICKS
```

Verify with:

```
D A,BRICKS
```

If it is not active, check the SYSLOG. The error will be obvious.
Fix it. Do not file a ticket.

---

## Step 3: Verify BRICKS_TS is functional

Enter transaction `BRTM` at a 3270 terminal.
You should see the BRICKS_TS master menu.

If you do not, consult the BRICKS_TS README at the source repo.
If that does not help, consult moshix's YouTube channel.
If that does not help, you have a Hercules configuration problem.
Return to Step 1.

---

## Step 4: Create the EDM development partitioned datasets

The following JCL allocates the EDM development library structure.
Submit `jcl/EDMALLOC.jcl`:

```jcl
//EDMALLOC JOB (EDM),'EDM LIBRARY ALLOC',CLASS=A,MSGCLASS=X
//STEP1    EXEC PGM=IEFBR14
//EDMSRC   DD DSN=EDM.SOURCE,
//            DISP=(NEW,CATLG),
//            UNIT=SYSDA,
//            SPACE=(CYL,(5,2,50)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//EDMLOAD  DD DSN=EDM.LOADLIB,
//            DISP=(NEW,CATLG),
//            UNIT=SYSDA,
//            SPACE=(CYL,(10,5)),
//            DCB=(RECFM=U,BLKSIZE=32760)
//EDMCOPY  DD DSN=EDM.COPYLIB,
//            DISP=(NEW,CATLG),
//            UNIT=SYSDA,
//            SPACE=(CYL,(2,1,30)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//EDMMAP   DD DSN=EDM.MAPLIB,
//            DISP=(NEW,CATLG),
//            UNIT=SYSDA,
//            SPACE=(CYL,(2,1,30)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
```

---

## Step 5: Add EDM load library to BRICKS_TS DFHRPL

In the BRICKS_TS startup JCL, add `EDM.LOADLIB` to the DFHRPL
concatenation:

```jcl
//DFHRPL   DD DSN=BRICKS.LOADLIB,DISP=SHR
//         DD DSN=EDM.LOADLIB,DISP=SHR
```

Restart BRICKS_TS.

---

## Environment verified

When you can:

1. IPL MVS via Hercules
2. Connect via 3270 terminal
3. Start BRICKS_TS with `S BRICKS`
4. See `BRTM` master menu
5. Access EDM datasets via TSO/ISPF

...proceed to Episode 1.

Not before.

---

```
BOFH ADDENDUM:
The development LPAR has a 4-hour idle timeout.
If you disconnect without cancelling your jobs, I will
notice. The Annoyance Rank adjustment will be immediate.
```
