# CLAUDE.md — edm-cics

## Project

COBOL/REXX CICS application source for the EDM (Ellison Digital Minerals)
tenant. Two tenants share this codebase: EDM (MSSP/business ops) and
DPR (Da Planet Radio back-office). PostgreSQL via EXEC SQL. PostScript
report generation via pure PL/pgSQL with `print_queue` table and `pg_notify`.

Deployed via `edm-cics-quadlet` (sibling repo).

## Architecture

- COBOL programs: transaction logic, screen maps, report generation
- REXX execs: JCL-equivalent batch processing, installation scripts
- `sql/`: PostgreSQL schema, migrations, stored procedures
- `runtime/`: runtime configuration and MTA integration
- `ep00/`: entry point definitions

## Workflow (BDD-first)

1. Open GitHub Issue
2. Branch: `feat/N` or `fix/N` from `master`
3. Write BATS test first (unit → integration → e2e → ceci)
4. Write COBOL/REXX until tests pass
5. Update `CHANGELOG.md` under `[Unreleased]`
6. Push → PR → review → merge → semver tag

Never commit directly to master. BDD order is mandatory.

## Test structure

```
tests/
  unit/          — COBOL unit logic, REXX exec tests
  integration/   — schema + print_queue integration
  ceci/          — CICS/EXEC CICS command paths
  e2e/           — client/server regression
```

## Semver

- MAJOR — schema break or wire protocol change
- MINOR — new non-breaking transaction or report
- PATCH — everything else

## Standards

- BSD 2-Clause Licence
- BATS tests mandatory — no untested COBOL/REXX
- net.matrix CMDB labels in all Quadlet container units (via edm-cics-quadlet)
- SLSA Level 3 provenance on release tarballs
- Option C rule for Odoo: direct PostgreSQL for reads, XML-RPC for creates/updates
