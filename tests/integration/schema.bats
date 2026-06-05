#!/usr/bin/env bats
# tests/integration/schema.bats
# BDD: PostgreSQL schema integrity checks.
# Requires: Postgres running with edm database initialized.

load '../helpers/common'

setup() {
    pg_is_up || skip "Postgres not reachable at ${PGHOST}:${PGPORT}"
}

# ── Core tables exist ─────────────────────────────────────────────────

@test "edm_clients table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='edm_clients'"
    [ "${output}" = "1" ]
}

@test "edm_orders table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='edm_orders'"
    [ "${output}" = "1" ]
}

@test "edm_security table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='edm_security'"
    [ "${output}" = "1" ]
}

@test "edm_audit table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='edm_audit'"
    [ "${output}" = "1" ]
}

@test "sys_user_orgs table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='sys_user_orgs'"
    [ "${output}" = "1" ]
}

@test "edm_tickets table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='edm_tickets'"
    [ "${output}" = "1" ]
}

@test "edm_mailq table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='edm_mailq'"
    [ "${output}" = "1" ]
}

@test "dpr_shows table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='dpr_shows'"
    [ "${output}" = "1" ]
}

# ── Schema correctness ────────────────────────────────────────────────

@test "edm_clients has risk_tier column not annoyance_rank" {
    run pg_query "SELECT column_name FROM information_schema.columns
                  WHERE table_name='edm_clients'
                  AND column_name='risk_tier'"
    [ "${output}" = "risk_tier" ]
}

@test "edm_clients does not have annoyance_rank column" {
    run pg_query "SELECT COUNT(*) FROM information_schema.columns
                  WHERE table_name='edm_clients'
                  AND column_name='annoyance_rank'"
    [ "${output}" = "0" ]
}

@test "edm_tickets has escalated column not annoyance_event" {
    run pg_query "SELECT column_name FROM information_schema.columns
                  WHERE table_name='edm_tickets'
                  AND column_name='escalated'"
    [ "${output}" = "escalated" ]
}

@test "edm_audit UPDATE is revoked" {
    run pg_query "SELECT has_table_privilege('bricks','edm_audit','UPDATE')"
    [ "${output}" = "f" ]
}

@test "edm_audit DELETE is revoked" {
    run pg_query "SELECT has_table_privilege('bricks','edm_audit','DELETE')"
    [ "${output}" = "f" ]
}

@test "sys_user_orgs has admin seed record" {
    run pg_query "SELECT COUNT(*) FROM sys_user_orgs
                  WHERE userid='admin   ' AND grp='ADMIN'"
    [ "${output}" = "1" ]
}

@test "dpr_shows has DPRMAIN seed record" {
    run pg_query "SELECT COUNT(*) FROM dpr_shows
                  WHERE show_id='DPRMAIN '"
    [ "${output}" = "1" ]
}

@test "edm_ticket_seq sequence exists" {
    run pg_query "SELECT COUNT(*) FROM information_schema.sequences
                  WHERE sequence_name='edm_ticket_seq'"
    [ "${output}" = "1" ]
}
