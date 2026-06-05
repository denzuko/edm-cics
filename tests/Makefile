# tests/Makefile
# Run EDM CICS test suite.
#
# Targets:
#   make unit         -- brickscompile syntax checks (no bricks needed)
#   make integration  -- Postgres schema checks (Postgres needed)
#   make e2e          -- full terminal flows via expect/s3270 (full stack)
#   make all          -- unit + integration + e2e
#   make ci           -- unit + integration (safe for CI without bricks)
#
# Environment variables:
#   BRICKSCOMPILE     -- path to brickscompile binary
#   BRICKS_HOST       -- bricks host (default: localhost)
#   BRICKS_PORT       -- bricks port (default: 2300)
#   BRICKS_USER       -- bricks user (default: admin)
#   BRICKS_PASS       -- bricks password (default: admin)
#   PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE -- postgres connection

BATS ?= bats
BATS_FLAGS ?= --timing

.PHONY: unit integration e2e all ci

unit:
	$(BATS) $(BATS_FLAGS) unit/

integration:
	$(BATS) $(BATS_FLAGS) integration/

e2e:
	$(BATS) $(BATS_FLAGS) e2e/

all: unit integration e2e

ci: unit integration

clean:
	@echo "No artifacts to clean."
