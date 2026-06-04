# ELLISON DIGITAL MINERALS
## Internal Systems Development Programme
### CICS Transaction Processing — Onboarding Series

```
CLASSIFICATION: INTERNAL USE ONLY
DISTRIBUTION:   ALL ACQUISITION SPECIALISTS WITH ANNOYANCE RANK < 7
PREPARED BY:    Office of Systems Administration (B. O. F. H.)
APPROVED BY:    Regional Management, Albany District
VERSION:        1.0.0
LAST UPDATED:   SEE GIT LOG. I TOLD YOU TO USE GIT LOG.
```

---

> "The mainframe does not care what year it is.
>  Neither do we."
>
> — CEO, Ellison Digital Minerals, Launch Day Address

---

## What This Is

This repository contains the source code for all ten episodes of the
**EDM Internal CICS Development Programme**, using
[BRICKS_TS](https://github.com/moshix/BRICKS_TS) as the transaction
server platform.

By the end of this series you will have built a fully operational CICS
application emulating the core Ellison Digital Minerals business
subsystems: client registry, acquisition order processing, asset
inventory, account ledger, security/access control, immutable audit
ledger, and management reporting.

All code is real. Every transaction compiles. Every screen maps to a
3270 terminal. The SQL backend is not a simulation.

## Prerequisites

You will need:

- Hercules mainframe emulator with TK5 (MVS 3.8j) or equivalent
- BRICKS_TS installed and configured (see Episode 0)
- COBOL compiler (IGYCRCTL or equivalent)
- A 3270 terminal emulator (x3270, c3270, tn3270)
- Patience for JCL

If you do not have Hercules and TK5 installed, see Episode 0.
If you do not know what Hercules is, see Episode 0 and then reconsider
your life choices. — *BOFH*

## Episode Structure

| Episode | Subsystem | Voice | Topic |
|---------|-----------|-------|-------|
| 00 | Infrastructure | BOFH | BRICKS_TS installation, Hercules, JCL basics |
| 01 | EDMHELO | PFY | First transaction, EXEC CICS SEND TEXT |
| 02 | EDMMST UI | PFY | BMS maps, 3270 screen layout |
| 03 | EDMMST Data | PFY | VSAM KSDS, EXEC CICS READ/WRITE |
| 04 | SQL Bridge | PFY | CICS-SQL attachment, DDL, two-phase commit |
| 05 | EDMORD | PFY | Multi-screen flow, COMMAREA state |
| 06 | EDMINV/EDMACT | PFY | Linked programs, acquisition pipeline |
| 07 | EDMSEC | BOFH | Annoyance Rank, access control, ASSIGN USERID |
| 08 | EDMARC | PFY | ESDS append-only, immutable audit ledger |
| 09 | EDMRPT | PHB+PFY | Browse transactions, reporting, the Dashboard |

## Repository Structure

```
ep00-orientation/    Episode 0 — JCL, BRICKS_TS setup
ep01-hello/          Episode 1 — EDMHELO transaction
ep02-bms/            Episode 2 — BMS map source
ep03-vsam/           Episode 3 — VSAM definitions + COBOL
ep04-sql/            Episode 4 — SQL DDL + COBOL SQL bridge
ep05-orders/         Episode 5 — EDMORD transaction
ep06-pipeline/       Episode 6 — EDMINV + EDMACT
ep07-security/       Episode 7 — EDMSEC access control
ep08-ledger/         Episode 8 — EDMARC ESDS ledger
ep09-reports/        Episode 9 — EDMRPT inquiry + reporting
jcl/                 Shared JCL procedures (compile, link, deploy)
copybooks/           Shared COBOL copybooks (record layouts)
sql/                 SQL DDL for all subsystem tables
```

## License

BSD-2-Clause. The fictional company is fictional.
The COBOL is not.

---

```
NOTE FROM BOFH:
If you break the development LPAR I will find you.
I always find you.
```
