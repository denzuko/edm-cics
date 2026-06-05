#!/usr/bin/env bats
# tests/e2e/clnt.bats
# BDD: CLNT transaction — client inquiry screen flows.
# Requires: bricks + Postgres running, test client record seeded.

load '../helpers/common'

setup() {
    bricks_is_up    || skip "bricks not running"
    pg_is_up        || skip "Postgres not running"
    command -v expect >/dev/null 2>&1 || skip "expect not installed"
    command -v s3270  >/dev/null 2>&1 || skip "s3270 not installed"

    # Seed a known test client if not present
    pg_query "INSERT INTO edm_clients
        (client_id, client_type, risk_tier, last_name, first_name,
         location, status, created_date)
        VALUES ('TESTCL01','C',3,'TEST','CLIENT','ALB','A',CURRENT_DATE)
        ON CONFLICT DO NOTHING" >/dev/null 2>&1
}

@test "CLNT transaction displays client inquiry screen" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid CLNT
set screen [bricks_screen $sid]
bricks_assert_contains $screen "CLIENT REGISTRY"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CLNT returns client record for known client ID" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid CLNT
# Type client ID into the CLIENTID field and submit
send -i $sid "String(TESTCL01)
"
send -i $sid "Enter
"
expect -i $sid -timeout 10 "ok"
set screen [bricks_screen $sid]
bricks_assert_contains $screen "TEST"
bricks_assert_contains $screen "RECORD FOUND"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CLNT returns not-found message for unknown client ID" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid CLNT
send -i $sid "String(XXXXXXXX)
"
send -i $sid "Enter
"
expect -i $sid -timeout 10 "ok"
set screen [bricks_screen $sid]
bricks_assert_contains $screen "NOT FOUND"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CLNT PF5 transfers to CLNU update screen" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid CLNT
bricks_pf $sid 5
set screen [bricks_screen $sid]
bricks_assert_contains $screen "ADD / UPDATE"
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}
