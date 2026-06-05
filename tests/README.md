# EDM CICS — Test Suite

Three-tier test architecture:

| Tier | Directory | Tools | Needs bricks? |
|------|-----------|-------|--------------|
| Unit | `unit/` | `brickscompile` + `bats` | No |
| Integration | `integration/` | `psql` + `bats` | Postgres only |
| CECI | `ceci/` | `CECI` + `expect` + `s3270` + `bats` | Full stack + dev user |
| E2E / Regression | `e2e/` | `expect` + `s3270` + `bats` | Full stack |

## Quick start

```sh
# Unit tests only (no bricks, no Postgres)
bats tests/unit/

# Integration (Postgres required)
PGPASSWORD=brickspassword bats tests/integration/

# CECI tests (bricks + Postgres + dev group user)
BRICKS_DEV_USER=devtest BRICKS_DEV_PASS=devtest \
bats tests/ceci/

# Full E2E (bricks + Postgres + expect + s3270)
BRICKS_HOST=localhost BRICKS_PORT=2300 \
BRICKS_USER=admin BRICKS_PASS=admin \
PGPASSWORD=brickspassword \
bats tests/e2e/

# Or via make
cd tests && make ci        # unit + integration
cd tests && make all       # all three tiers
```

## Dependencies

```sh
# bats-core
npm install -g bats

# s3270 and expect (Ubuntu/Debian)
apt-get install x3270 expect

# s3270 (macOS)
brew install x3270 expect

# brickscompile — from the BRICKS_TS bin/ directory
# Set BRICKSCOMPILE env var or place in PATH
```

## Test tiers in detail

### Unit — `unit/`

- `cobol.bats`: every `.cob` file passes `brickscompile`
- `rexx.bats`: every `.rexx` file passes `brickscompile`
- `maps.bats`: every `.map` file passes `brickscompile`; internal MAP name
  matches filename (prevents runtime dispatch errors)
- `transactions_conf.bats`: every referenced program exists on disk;
  all TRANSIDs are exactly 4 chars; no old EM-prefix transids remain

### Integration — `integration/`

- `schema.bats`: all required tables exist; `risk_tier` not `annoyance_rank`;
  `edm_audit` UPDATE/DELETE revoked; seed data present

### CECI — `ceci/`

Requires a running bricks instance and a user with the `dev` group.
`CECI` is a built-in BRICKS_TS TRANSID (no `transactions.conf` entry)
that lets developers execute a single `EXEC CICS` or `EXEC SQL` statement
interactively and inspect the result (EIBRESP, SQLCODE, field values).

- `ceci/sql.bats`: `EXEC SQL SELECT` against all core tables; INSERT into
  `edm_audit`; verify `REVOKE DELETE` is enforced at DB level
- `ceci/cics.bats`: `EXEC CICS ASSIGN`, `ASKTIME`, `READ FILE` (NOTFND path),
  `WRITEQ TS` + `READQ TS` round-trip; dev group denial test

Each test follows the Given/When/Then pattern: Given a running stack and a
dev-group session, When CECI executes a single verb, Then the response line
confirms NORMAL or the expected condition.

### E2E — `e2e/`

- `menu.bats`: MENU dispatch, org-aware menu display, PF3 exit
- `clnt.bats`: client inquiry, not-found handling, PF5 transfer to CLNU
- `regression.bats`: named regressions — old transids undefined,
  no ARG content on screens, SECU shows access control not annoyance rank,
  AUDT uses correct transid literal, PA1 break-out works

## Adding a new test

**Unit:** add a `@test` block in the appropriate `.bats` file.

**E2E:** follow the pattern in `e2e/clnt.bats`. Source
`tests/e2e/helpers/s3270.exp` from your expect script, use
`bricks_connect`, `bricks_signon`, `bricks_transid`, `bricks_screen`,
`bricks_assert_contains`.

**Regression:** add a `@test` in `e2e/regression.bats` with a comment
linking it to the issue or commit it guards.
