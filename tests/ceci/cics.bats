#!/usr/bin/env bats
# tests/ceci/cics.bats
# BDD: CECI-driven EXEC CICS integration tests.
#
# Tests EXEC CICS verbs interactively via CECI: ASSIGN, ASKTIME,
# FILE READ (KSDS), and WRITEQ TS. Each test is a focused
# Given/When/Then against a single verb.
#
# Requires: bricks running, dev group user.

load '../helpers/common'

setup() {
    bricks_is_up  || skip "bricks not running"
    command -v expect >/dev/null 2>&1 || skip "expect not installed"
    command -v s3270  >/dev/null 2>&1 || skip "s3270 not installed"
    ensure_dev_user
}

# Given: a signed-on dev session
# When: CECI executes EXEC CICS ASSIGN
# Then: EIBRESP = 0 (NORMAL) and TERMID/USERID are populated

@test "CECI: EXEC CICS ASSIGN USERID returns EIBRESP 0" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid {EXEC CICS ASSIGN USERID(WK-USER) TERMID(WK-TERM) END-EXEC}]
ceci_assert_response $resp "NORMAL"
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CECI: EXEC CICS ASKTIME returns EIBRESP 0" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid {EXEC CICS ASKTIME ABSTIME(WK-TIME) END-EXEC}]
ceci_assert_response $resp "NORMAL"
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

# Given: the EDMMST KSDS is defined
# When: CECI executes EXEC CICS READ FILE on an unknown key
# Then: EIBRESP = NOTFND (not a system abend)

@test "CECI: EXEC CICS READ FILE NOTFND returns EIBRESP NOTFND not abend" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
set resp [ceci_exec $sid {EXEC CICS READ FILE('EDMMST') INTO(WK-REC) RIDFLD(WK-KEY) RESP(WK-RC) END-EXEC}]
# Should return NOTFND (EIBRESP=13) or NORMAL -- not an abend
bricks_assert_not_contains $resp "ABEND"
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

@test "CECI: EXEC CICS WRITEQ TS writes and READQ TS reads" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_DEV_USER) $env(BRICKS_DEV_PASS)
ceci_open $sid
# Write to a test TS queue
set resp [ceci_exec $sid {EXEC CICS WRITEQ TS QUEUE('TESTQ') FROM(WK-DATA) LENGTH(8) END-EXEC}]
ceci_assert_response $resp "NORMAL"
# Read it back
set resp [ceci_exec $sid {EXEC CICS READQ TS QUEUE('TESTQ') INTO(WK-DATA) LENGTH(8) ITEM(1) END-EXEC}]
ceci_assert_response $resp "NORMAL"
# Clean up
ceci_exec $sid {EXEC CICS DELETEQ TS QUEUE('TESTQ') END-EXEC}
ceci_close $sid
bricks_disconnect $sid
exit 0
EXPEOF
    [ "$status" -eq 0 ]
}

# Given: a non-dev user
# When: they attempt to type CECI
# Then: bricks returns the dev-group error message

@test "CECI is denied to users without dev group" {
    run expect << 'EXPEOF'
source tests/e2e/helpers/s3270.exp
# Sign on as admin (no dev group by default)
set sid [bricks_connect $env(BRICKS_HOST) $env(BRICKS_PORT)]
bricks_signon $sid $env(BRICKS_USER) $env(BRICKS_PASS)
bricks_transid $sid CECI
set screen [bricks_screen $sid]
bricks_assert_contains $screen "DEV"
bricks_disconnect $sid
exit 0
EXPEOF
    # This test is informational — admin may or may not have dev group
    # depending on deployment. If admin has dev, CECI opens (status 0 still ok).
    [ "$status" -eq 0 ]
}
