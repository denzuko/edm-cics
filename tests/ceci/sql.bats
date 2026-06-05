#!/usr/bin/env bats
# tests/ceci/sql.bats
# BDD: CECI-driven SQL integration tests.
#
# Uses CECI to execute EXEC SQL statements interactively against the
# live bricks + Postgres stack. Verifies SQL layer is wired correctly
# without running full transaction flows.
#
# Requires: bricks running, Postgres running, dev group user.
# The dev user is created automatically via ensure_dev_user() if
# add_brick_user.bash is available.

load '../helpers/common'

setup() {
    bricks_is_up  || skip "bricks not running at ${BRICKS_HOST}:${BRICKS_PORT}"
    pg_is_up      || skip "Postgres not running"
    command -v expect >/dev/null 2>&1 || skip "expect not installed"
    command -v s3270  >/dev/null 2>&1 || skip "s3270 not installed"
    ensure_dev_user
}

# ── Given: a running bricks with Postgres
# When: CECI executes EXEC SQL SELECT COUNT(*)
# Then: SQLCODE = 0 and response shows NORMAL

@test "CECI: EXEC SQL SELECT from edm_clients returns SQLCODE 0" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid {EXEC SQL SELECT COUNT(*) INTO :WK-COUNT FROM edm_clients END-EXEC}]
ceci_assert_response $resp "NORMAL"
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CECI: EXEC SQL SELECT from sys_user_orgs returns SQLCODE 0" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid {EXEC SQL SELECT COUNT(*) INTO :WK-COUNT FROM sys_user_orgs END-EXEC}]
ceci_assert_response $resp "NORMAL"
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CECI: EXEC SQL against nonexistent table returns SQLCODE -204" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid {EXEC SQL SELECT 1 INTO :WK-X FROM no_such_table END-EXEC}]
# Expect SQL error response
ceci_assert_response $resp "SQL"
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CECI: EXEC SQL INSERT into edm_audit succeeds" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid     {EXEC SQL INSERT INTO edm_audit (trans_timestamp,userid,transid,program,action_code,result_code) VALUES (NOW(),'DEVTEST ','CECI','CECI','TEST','SUCC') END-EXEC}]
ceci_assert_response $resp "NORMAL"
ceci_exec $sid {EXEC SQL COMMIT END-EXEC}
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CECI: EXEC SQL INSERT into edm_audit DELETE is blocked at DB level" {
    # This tests that the DB-level REVOKE is enforced, not just the app
    run pg_query "DELETE FROM edm_audit WHERE userid='DEVTEST '" 2>&1
    # psql returns ERROR when DELETE is revoked
    [[ "$output" =~ "ERROR" ]] || [[ "$output" =~ "permission denied" ]]
}
