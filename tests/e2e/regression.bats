#!/usr/bin/env bats
# tests/e2e/regression.bats
# Regression tests: specific bugs and invariants that must not reappear.
# Each test corresponds to a named issue or commit.
# Requires: bricks + Postgres running.

load '../helpers/common'

setup() {
    bricks_is_up    || skip "bricks not running"
    command -v expect >/dev/null 2>&1 || skip "expect not installed"
    command -v s3270  >/dev/null 2>&1 || skip "s3270 not installed"
}

# Regression: Track A rename — old EMHL transid must not be dispatched
@test "EMHL transid is undefined and abends cleanly" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid EMHL
set screen [bricks_screen $sid]
# BRICKS returns an error screen for undefined transids
bricks_assert_not_contains $screen "ELLISON DIGITAL MINERALS"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

# Regression: ARG content must not appear on any screen
@test "no screen contains annoyance rank text" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid MENU
set screen [bricks_screen $sid]
bricks_assert_not_contains $screen "ANNOYANCE"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

# Regression: SECU must show access control, not annoyance rank
@test "SECU screen does not contain ANNOYANCE RANK" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid SECU
set screen [bricks_screen $sid]
bricks_assert_contains $screen "ACCESS CONTROL"
bricks_assert_not_contains $screen "ANNOYANCE"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

# Regression: AUDT must insert with correct TRANSID literal
@test "edm_audit rows have AUDT transid not EMARC" {
    pg_is_up || skip "Postgres not running"
    run pg_query "SELECT COUNT(*) FROM edm_audit WHERE transid='EMARC'"
    # Any EMARC rows would be from pre-rename code — must be zero
    [ "${output}" = "0" ]
}

# Regression: PA1 break-out must not leave terminal stuck
@test "PA1 break-out returns to TRANSID prompt" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid CLNT
# Break out with PA1 before the transaction completes
bricks_pa $sid 1
set screen [bricks_screen $sid]
# Should be back at blank TRANSID prompt, not stuck on CLNT screen
bricks_assert_not_contains $screen "CLIENT REGISTRY"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}
