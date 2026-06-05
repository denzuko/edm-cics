#!/usr/bin/env bats
# tests/unit/rexx.bats
# BDD: every REXX source file must parse cleanly via brickscompile.
# No bricks instance required.

load '../helpers/common'

setup() {
    [ -n "${BRICKSCOMPILE}" ] || skip "brickscompile not found"
}

@test "menu.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/menu.rexx"
}

@test "clnt.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/clnt.rexx"
}

@test "rept.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/rept.rexx"
}

@test "audt.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/audt.rexx"
}

@test "mail.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/mail.rexx"
}

@test "schd.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/schd.rexx"
}

@test "lnkd.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/lnkd.rexx"
}

@test "lnkdwrk.rexx parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/rexx/lnkdwrk.rexx"
}
