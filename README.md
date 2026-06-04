# ELLISON DIGITAL MINERALS
## Internal Systems Development Programme
### CICS Transaction Processing — Onboarding Series

```
CLASSIFICATION: INTERNAL USE ONLY
DISTRIBUTION:   ALL ACQUISITION SPECIALISTS WITH ANNOYANCE RANK < 7
PREPARED BY:    Office of Systems Administration (B. O. F. H.)
APPROVED BY:    Regional Management, Albany District
```

---

> "The mainframe does not care what year it is. Neither do we."
> — CEO, Ellison Digital Minerals, Launch Day Address

---

## What This Is

Source code for the EDM Internal CICS Development Programme.

Platform: [BRICKS_TS](https://github.com/moshix/BRICKS_TS) — a Go
implementation of a CICS-compatible 3270 transaction server with
embedded COBOL and REXX interpreters and PostgreSQL via `EXEC SQL`.

No Hercules. No JCL. No MVS. You write COBOL or REXX, drop it in the
right directory, add a line to `transactions.conf`, and it runs.

## Runtime layout

```
runtime/
  cobol/        COBOL source files (.cob)
  rexx/         REXX source files (.rexx)
  map/          BMS-style map definitions (.map)
  cobolcopy/    Copybooks referenced by COPY directives
  transactions.conf
  databases.conf
  users.conf
sql/
  EDM-DDL.sql   PostgreSQL DDL for all EDM subsystems
```

## Episode structure

| Ep | TRANSID | Lang  | Voice | Topic |
|----|---------|-------|-------|-------|
| 00 | —       | —     | BOFH  | BRICKS_TS setup, Docker, this repo |
| 01 | EMHL    | COBOL | PFY   | First transaction — SEND MAP / RETURN |
| 02 | EMHI    | REXX  | PFY   | REXX twin, map DSL, stem variables |
| 03 | EMMI    | COBOL | PFY   | EDMMST inquiry — EXEC CICS READ (KSDS) |
| 04 | EMMW    | COBOL | PFY   | EDMMST write — EXEC CICS WRITE / REWRITE |
| 05 | EMSI    | COBOL | PFY   | SQL bridge — SELECT INTO from EDM_CLIENTS |
| 06 | EMOR    | COBOL | PFY   | EDMORD order entry — COMMAREA, multi-screen |
| 07 | EMLI    | REXX  | PFY   | EXEC CICS LINK — business logic separation |
| 08 | EMSC    | COBOL | BOFH  | EDMSEC — ASSIGN USERID, Annoyance Rank |
| 09 | EMARC   | REXX  | PFY   | EDMARC — append-only audit log (ESDS-style) |
| 10 | EMRP    | COBOL | PHB+PFY | EDMRPT — browse, reports, the Dashboard |

## Companion repos

- [denzuko/BRICKS_TS-docker](https://github.com/denzuko/BRICKS_TS-docker) — Docker image
- [denzuko/edm-cics-quadlet](https://github.com/denzuko/edm-cics-quadlet) — Podman Quadlet deployment

## License

BSD-2-Clause. The fictional company is fictional. The COBOL is not.

---

```
NOTE FROM BOFH:
This runs in Docker with postgres. Not on a z/OS.
Not on Hercules. If you file a ticket asking about JCL
your Annoyance Rank will be adjusted accordingly.
```
