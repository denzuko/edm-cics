#!/usr/bin/env bats
# tests/unit/maps.bats
# BDD: every map file must parse cleanly via brickscompile,
# and each map's internal MAP name must match its filename.
# No bricks instance required.

load '../helpers/common'

setup() {
    [ -n "${BRICKSCOMPILE}" ] || skip "brickscompile not found"
}

# ── Map parse checks ──────────────────────────────────────────────────

@test "menu1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/menu1.map"
}

@test "clnt1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/clnt1.map"
}

@test "clnu1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/clnu1.map"
}

@test "clns1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/clns1.map"
}

@test "ordn1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/ordn1.map"
}

@test "ordn2.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/ordn2.map"
}

@test "audt1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/audt1.map"
}

@test "hlpd1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/hlpd1.map"
}

@test "secu1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/secu1.map"
}

@test "mail1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/mail1.map"
}

@test "rept1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/rept1.map"
}

@test "schd1.map parses cleanly" {
    assert_compiles "${RUNTIME_DIR}/map/schd1.map"
}

# ── Map name consistency: MAP NAME in file must match filename ─────────
# BRICKS_TS matches the MAP() argument in SEND MAP to the MAP name
# declared inside the .map file. Mismatches cause runtime errors.
# This test catches them at source-level.

check_map_name() {
    local mapfile="$1"
    local expected_name
    expected_name="$(basename "${mapfile}" .map | tr '[:lower:]' '[:upper:]')"
    grep -qi "^MAP ${expected_name} " "${mapfile}"
}

@test "menu1.map internal name is MENU1" {
    check_map_name "${RUNTIME_DIR}/map/menu1.map"
}

@test "clnt1.map internal name is CLNT1" {
    check_map_name "${RUNTIME_DIR}/map/clnt1.map"
}

@test "clnu1.map internal name is CLNU1" {
    check_map_name "${RUNTIME_DIR}/map/clnu1.map"
}

@test "clns1.map internal name is CLNS1" {
    check_map_name "${RUNTIME_DIR}/map/clns1.map"
}

@test "ordn1.map internal name is ORDN1" {
    check_map_name "${RUNTIME_DIR}/map/ordn1.map"
}

@test "audt1.map internal name is AUDT1" {
    check_map_name "${RUNTIME_DIR}/map/audt1.map"
}

@test "hlpd1.map internal name is HLPD1" {
    check_map_name "${RUNTIME_DIR}/map/hlpd1.map"
}

@test "secu1.map internal name is SECU1" {
    check_map_name "${RUNTIME_DIR}/map/secu1.map"
}

@test "mail1.map internal name is MAIL1" {
    check_map_name "${RUNTIME_DIR}/map/mail1.map"
}

@test "rept1.map internal name is REPT1" {
    check_map_name "${RUNTIME_DIR}/map/rept1.map"
}

@test "schd1.map internal name is SCHD1" {
    check_map_name "${RUNTIME_DIR}/map/schd1.map"
}

# ── No stale old-name map files ───────────────────────────────────────

@test "emhelo1.map does not exist" {
    [ ! -f "${RUNTIME_DIR}/map/emhelo1.map" ]
}

@test "emmi1.map does not exist" {
    [ ! -f "${RUNTIME_DIR}/map/emmi1.map" ]
}

@test "emsc1.map does not exist" {
    [ ! -f "${RUNTIME_DIR}/map/emsc1.map" ]
}
