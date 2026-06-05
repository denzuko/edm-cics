#!/usr/bin/env bats
# tests/e2e/menu.bats
# BDD: MENU transaction — sign on, see correct org menu.
# Requires: bricks running, Postgres running, expect installed.

load '../helpers/common'

setup() {
    bricks_is_up    || skip "bricks not running at ${BRICKS_HOST}:${BRICKS_PORT}"
    command -v expect >/dev/null 2>&1 || skip "expect not installed"
    command -v s3270  >/dev/null 2>&1 || skip "s3270 not installed"
}

# ── Helper: run an expect script and return its output ────────────────
run_expect() {
    local script="$1"
    shift
    run expect -f "${TESTS_DIR}/e2e/helpers/s3270.exp"                "${script}" "$@"
}

@test "MENU transaction is reachable after CSSN sign-on" {
    run expect << 'EXPEOF'
source [lindex $argv 0]
set sid [bricks_connect localhost 2300]
bricks_signon $sid admin admin
bricks_transid $sid MENU
set screen [bricks_screen $sid]
bricks_assert_contains $screen "MENU"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "MENU shows EDM options for admin user" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid MENU
set screen [bricks_screen $sid]
bricks_assert_contains $screen "CLNT"
bricks_assert_contains $screen "HLPD"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "PF3 from MENU returns to TRANSID prompt" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid MENU
bricks_pf $sid 3
set screen [bricks_screen $sid]
# After PF3 from MENU, should be back at blank TRANSID prompt
bricks_assert_not_contains $screen "MAIN MENU"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}
