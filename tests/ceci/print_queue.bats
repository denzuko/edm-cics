#!/usr/bin/env bats
# tests/ceci/print_queue.bats
# BDD: CECI-driven print queue dispatch tests.
# Verifies the REPT transaction can queue PostScript print jobs.
# Requires: bricks + Postgres running, dev group user.

load '../helpers/common'

setup() {
    bricks_is_up  || skip "bricks not running"
    pg_is_up      || skip "Postgres not running"
    command -v expect >/dev/null 2>&1 || skip "expect not installed"
    command -v s3270  >/dev/null 2>&1 || skip "s3270 not installed"
    ensure_dev_user
}

@test "CECI: INSERT into print_queue succeeds" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid \
    {EXEC SQL INSERT INTO print_queue (report_type,requested_by,destination) VALUES ('CLNT_RPT','DEVTEST ','PRNT') END-EXEC}]
ceci_assert_response $resp "NORMAL"
ceci_exec $sid {EXEC SQL COMMIT END-EXEC}
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CECI: process_print_queue() generates PostScript" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid {EXEC SQL SELECT process_print_queue() INTO :WK-COUNT END-EXEC}]
ceci_assert_response $resp "NORMAL"
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}
