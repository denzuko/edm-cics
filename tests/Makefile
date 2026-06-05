# tests/Makefile
# Run EDM CICS test suite.
#
# Targets:
#   make unit         -- brickscompile syntax checks (no bricks needed)
#   make integration  -- Postgres schema checks (Postgres needed)
#   make ceci         -- CECI interactive EXEC CICS/SQL tests (full stack + dev user)
#   make e2e          -- full terminal transaction flows (full stack)
#   make all          -- unit + integration + ceci + e2e
#   make ci           -- unit + integration (safe for CI without bricks)
#
# Environment variables:
#   BRICKSCOMPILE         -- path to brickscompile binary
#   BRICKS_HOST/PORT      -- bricks instance (default: localhost:2300)
#   BRICKS_USER/PASS      -- standard test user (default: admin/admin)
#   BRICKS_DEV_USER/PASS  -- dev group user for CECI tests (default: devtest/devtest)
#   PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE -- postgres connection

BATS ?= bats
BATS_FLAGS ?= --timing

.PHONY: unit integration ceci e2e all ci

unit:
	$(BATS) $(BATS_FLAGS) unit/

integration:
	$(BATS) $(BATS_FLAGS) integration/

ceci:
	$(BATS) $(BATS_FLAGS) ceci/

e2e:
	$(BATS) $(BATS_FLAGS) e2e/

all: unit integration ceci e2e

ci: unit integration

clean:
	@echo "No artifacts to clean."
