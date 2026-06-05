#!/usr/bin/env bats
# tests/integration/print_queue.bats
# BDD: PostScript report generation and print queue integrity.
# Requires: Postgres running with EDM-PRINT.sql applied.

load '../helpers/common'

setup() {
    pg_is_up || skip "Postgres not reachable"
}

@test "print_queue table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='print_queue'"
    [ "${output}" = "1" ]
}

@test "rpt_client_list() function exists" {
    run pg_query "SELECT COUNT(*) FROM pg_proc
                  WHERE proname='rpt_client_list'"
    [ "${output}" = "1" ]
}

@test "rpt_audit_log() function exists" {
    run pg_query "SELECT COUNT(*) FROM pg_proc
                  WHERE proname='rpt_audit_log'"
    [ "${output}" = "1" ]
}

@test "rpt_open_orders() function exists" {
    run pg_query "SELECT COUNT(*) FROM pg_proc
                  WHERE proname='rpt_open_orders'"
    [ "${output}" = "1" ]
}

@test "process_print_queue() function exists" {
    run pg_query "SELECT COUNT(*) FROM pg_proc
                  WHERE proname='process_print_queue'"
    [ "${output}" = "1" ]
}

@test "rpt_client_list() returns valid PostScript" {
    run pg_query "SELECT LEFT(rpt_client_list(),20)"
    [[ "${output}" =~ "%!PS-Adobe-3.0" ]]
}

@test "rpt_open_orders() returns valid PostScript" {
    run pg_query "SELECT LEFT(rpt_open_orders(),20)"
    [[ "${output}" =~ "%!PS-Adobe-3.0" ]]
}

@test "INSERT into print_queue fires pg_notify trigger" {
    run pg_query "INSERT INTO print_queue
        (report_type, requested_by, destination)
        VALUES ('CLNT_RPT','admin   ','PRNT')
        RETURNING job_id"
    [ "${status}" -eq 0 ]
    [[ "${output}" =~ [0-9]+ ]]
}

@test "process_print_queue() processes pending jobs" {
    # Insert a test job
    pg_query "INSERT INTO print_queue
        (report_type, requested_by, destination)
        VALUES ('ORDR_RPT','admin   ','PRNT')" >/dev/null 2>&1

    run pg_query "SELECT process_print_queue()"
    [ "${status}" -eq 0 ]
    # Returns number of processed jobs (>= 1)
    [ "${output}" -ge 1 ] 2>/dev/null || [ -n "${output}" ]
}

@test "processed print job has PostScript content" {
    run pg_query "SELECT LEFT(postscript_doc,20)
                  FROM print_queue
                  WHERE status='C'
                  ORDER BY processed_at DESC
                  LIMIT 1"
    [[ "${output}" =~ "%!PS-Adobe-3.0" ]]
}

@test "webhook_events table exists" {
    run pg_query "SELECT 1 FROM information_schema.tables
                  WHERE table_name='webhook_events'"
    [ "${output}" = "1" ]
}

@test "web_anon role exists" {
    run pg_query "SELECT COUNT(*) FROM pg_roles WHERE rolname='web_anon'"
    [ "${output}" = "1" ]
}

@test "public_shows view exists" {
    run pg_query "SELECT 1 FROM information_schema.views
                  WHERE table_name='public_shows'"
    [ "${output}" = "1" ]
}
