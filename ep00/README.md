# Episode 0: Orientation
## BRICKS_TS Setup and EDM Development Environment

```
PREPARED BY:    B. O. F. H., Systems Administration
AUDIENCE:       Authorized developers
TONE:           Professional.
```

---

## What BRICKS_TS is

BRICKS_TS is a Go implementation of a CICS-compatible 3270 transaction
server, written by moshix. It embeds its own COBOL and REXX interpreters
— not GNUCobol, not Regina — and connects to PostgreSQL for SQL support.

You write COBOL or REXX source files. You drop them in the right directory.
You add one line to `transactions.conf`. The transaction runs.

There is no compile step. There is no JCL. There is no Hercules.
If you are looking for JCL, you are in the wrong tutorial.

Source: https://github.com/moshix/BRICKS_TS

---

## Running the EDM stack

The EDM environment runs via Podman Quadlet. See the companion repo:
https://github.com/denzuko/edm-cics-quadlet

For development without Quadlet, use Docker Compose directly.
See https://github.com/denzuko/BRICKS_TS-docker

### Minimum compose (development)

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: bricks
      POSTGRES_PASSWORD: brickspassword
      POSTGRES_DB: bricks

  bricks:
    image: localhost/bricks:latest
    depends_on: [postgres]
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_USER: bricks
      POSTGRES_PASSWORD: brickspassword
      POSTGRES_DB: bricks
      BRICKS_start_web3270: "yes"
    volumes:
      - ./runtime:/srv/bricks/runtime:ro
      - ./sql:/srv/bricks/sql:ro
      - bricks-data:/srv/bricks/data
    ports:
      - "2300:2300"
      - "9000:9000"

volumes:
  bricks-data:
```

### Connect

web3270 (browser): http://localhost:9000

3270 emulator: `c3270 -port 2300 localhost`

Sign on: TRANSID `CSSN`, then type your username and password.
Default admin credentials are in `runtime/users.conf` (change these).

### Initialize the EDM database

Once Postgres is running:

```sh
docker exec -i <postgres_container> psql -U bricks bricks \
  < sql/EDM-DDL.sql
```

Or set `BRICKS_auto_init_sql=/srv/bricks/sql/EDM-DDL.sql` in the
bricks container environment.

---

## Development workflow

1. Edit a `.cob` or `.rexx` file under `runtime/cobol/` or `runtime/rexx/`
2. If it is a new program, add a line to `runtime/transactions.conf`
3. Reload: BRICKS_TS parses and caches programs on first dispatch;
   restart the container or use `CEMT SET PROGRAM(name) NEWCOPY` to
   pick up changes
4. Type the TRANSID at the 3270 terminal and press Enter

No compile. No link-edit. No JCL submit.

---

## This repo structure

```
runtime/
  cobol/        COBOL source (.cob) — BRICKS embedded interpreter
  rexx/         REXX source (.rexx) — BRICKS embedded interpreter
  map/          BMS-style map definitions (.map)
  cobolcopy/    Copybooks (COPY directive)
  transactions.conf
  databases.conf
sql/
  EDM-DDL.sql   PostgreSQL DDL — run once before first use
ep00/ .. ep10/  Episode documentation
```

---

## EDM business systems

| Subsystem | Purpose | Episodes |
|-----------|---------|---------|
| EDMMST | Master client registry | 03, 04 |
| EDMORD | Acquisition order processing | 06 |
| EDMINV | Asset inventory | 06 |
| EDMACT | Account ledger | 06 |
| EDMSEC | User access control | 08 |
| EDMARC | Immutable audit ledger | 09 |
| EDMRPT | Reporting and inquiry | 10 |

---

