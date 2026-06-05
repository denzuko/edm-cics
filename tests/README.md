# EDM CICS — Test Suite

Three-tier test architecture:

| Tier | Directory | Tools | Needs bricks? |
|------|-----------|-------|--------------|
| Unit | `unit/` | `brickscompile` + `bats` | No |
| Integration | `integration/` | `psql` + `bats` | Postgres only |
| E2E / Regression | `e2e/` | `expect` + `s3270` + `bats` | Full stack |

## Quick start

```sh
# Unit tests only (no bricks, no Postgres)
bats tests/unit/

# Integration (Postgres required)
PGPASSWORD=brickspassword bats tests/integration/

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
