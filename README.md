# edm-cics
## Multi-tenant CICS back-office platform on BRICKS_TS

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

| Ep | TRANSID | Lang  | Topic |
|----|---------|-------|-------|
| 00 | —       | —     | BRICKS_TS setup, Docker, this repo |
| 01 | CLNT    | REXX  | Client inquiry — SEND MAP, RETURN |
| 02 | CLNU    | COBOL | Client add/update — WRITE, REWRITE |
| 03 | CLNS    | COBOL | Client SQL lookup — SELECT INTO |
| 04 | ORDN    | COBOL | Order entry — COMMAREA, multi-screen |
| 05 | AUDT    | REXX  | Audit log append — append-only INSERT |
| 06 | HLPD    | COBOL | Helpdesk ticket entry |
| 07 | SECU    | COBOL | Access control inquiry |
| 08 | REPT    | REXX  | Management reports |
| 09 | MAIL    | REXX  | Mail dispatch |
| 10 | SCHD    | REXX  | Show schedule (DPR) |

## Companion repos

- [denzuko/BRICKS_TS-docker](https://github.com/denzuko/BRICKS_TS-docker) — Docker image
- [denzuko/edm-cics-quadlet](https://github.com/denzuko/edm-cics-quadlet) — Podman Quadlet deployment

## License

BSD-2-Clause. The fictional company is fictional. The COBOL is not.

---

