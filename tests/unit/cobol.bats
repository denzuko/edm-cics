#!/usr/bin/env bats
# tests/unit/cobol.bats
# BDD: every COBOL source file must parse cleanly via brickscompile.
# No bricks instance required.

load '../helpers/common'

setup() {
    [ -n "${BRICKSCOMPILE}" ] || skip "brickscompile not found"
}

# ── Core EDM COBOL programs ───────────────────────────────────────────

@test "clnu.cob parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/cobol/clnu.cob"
}

@test "clns.cob parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/cobol/clns.cob"
}

@test "clnt_ksds.cob parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/cobol/clnt_ksds.cob"
}

@test "ordn.cob parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/cobol/ordn.cob"
}

@test "secu.cob parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/cobol/secu.cob"
}

@test "hlpd.cob parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/cobol/hlpd.cob"
}

@test "rept.cob absent — converted to REXX" {
    # rept.cob was converted to rept.rexx; COBOL version must not exist
    [ ! -f "${RUNTIME_DIR}/cobol/rept.cob" ]
}

@test "clnt.cob absent — converted to REXX" {
    [ ! -f "${RUNTIME_DIR}/cobol/clnt.cob" ]
}
