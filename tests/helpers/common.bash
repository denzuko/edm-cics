# tests/helpers/common.bash
# Sourced by all bats test files.
# Sets up paths, environment, and shared helpers.

# ── Paths ─────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="${REPO_ROOT}/runtime"
SQL_DIR="${REPO_ROOT}/sql"
TESTS_DIR="${REPO_ROOT}/tests"
FIXTURES_DIR="${TESTS_DIR}/fixtures"

# ── brickscompile location ────────────────────────────────────────────
# Override by setting BRICKSCOMPILE in the environment.
# Searches: $BRICKSCOMPILE, ./bin/, /srv/bricks/bin/, PATH
find_brickscompile() {
    if [ -n "${BRICKSCOMPILE:-}" ] && [ -x "${BRICKSCOMPILE}" ]; then
        echo "${BRICKSCOMPILE}"
        return 0
    fi
    for candidate in         "${REPO_ROOT}/bin/brickscompile"         "/srv/bricks/bin/brickscompile"         "$(command -v brickscompile 2>/dev/null)"; do
        [ -x "${candidate}" ] && echo "${candidate}" && return 0
    done
    return 1
}

BRICKSCOMPILE="$(find_brickscompile)" || {
    echo "WARNING: brickscompile not found -- unit tests will skip" >&2
    BRICKSCOMPILE=""
}

# ── bricks instance (integration/e2e) ────────────────────────────────
BRICKS_HOST="${BRICKS_HOST:-localhost}"
BRICKS_PORT="${BRICKS_PORT:-2300}"
BRICKS_USER="${BRICKS_USER:-admin}"
BRICKS_PASS="${BRICKS_PASS:-admin}"

# ── Postgres (integration) ────────────────────────────────────────────
PGHOST="${PGHOST:-localhost}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-bricks}"
PGPASSWORD="${PGPASSWORD:-brickspassword}"
PGDATABASE="${PGDATABASE:-edm}"
export PGPASSWORD

# ── Helpers ───────────────────────────────────────────────────────────

# Run brickscompile against a single file; return its exit code.
# Usage: brickscompile_check <file>
brickscompile_check() {
    [ -z "${BRICKSCOMPILE}" ] && skip "brickscompile not found"
    "${BRICKSCOMPILE}" "$1" 2>&1
}

# Assert that brickscompile exits 0 for a file.
assert_compiles() {
    local file="$1"
    run brickscompile_check "${file}"
    if [ "${status}" -ne 0 ]; then
        echo "brickscompile FAILED: ${file}"
        echo "${output}"
        return 1
    fi
}

# Check if the bricks instance is reachable.
bricks_is_up() {
    nc -z "${BRICKS_HOST}" "${BRICKS_PORT}" 2>/dev/null
}

# Check if postgres is reachable.
pg_is_up() {
    psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}"          -d "${PGDATABASE}" -c "SELECT 1" >/dev/null 2>&1
}

# Run a SQL query and return its output.
pg_query() {
    psql -h "${PGHOST}" -p "${PGPORT}" -U "${PGUSER}"          -d "${PGDATABASE}" -tAc "$1" 2>&1
}
