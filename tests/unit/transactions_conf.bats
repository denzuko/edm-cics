#!/usr/bin/env bats
# tests/unit/transactions_conf.bats
# BDD: transactions.conf structural integrity checks.
# Every TRANSID must reference an existing source file.
# No bricks instance required.

load '../helpers/common'

# Parse transactions.conf and check each program file exists
@test "transactions.conf exists" {
    [ -f "${RUNTIME_DIR}/transactions.conf" ]
}

@test "every COBOL program in transactions.conf exists on disk" {
    local missing=0
    while IFS=: read -r transid lang program rest; do
        # Skip comments and blank lines
        [[ "${transid}" =~ ^[[:space:]]*# ]] && continue
        [ -z "${transid}" ] && continue

        if [ "${lang}" = "cobol" ]; then
            if [ ! -f "${RUNTIME_DIR}/cobol/${program}" ]; then
                echo "MISSING cobol: ${program} (TRANSID: ${transid})"
                missing=$((missing + 1))
            fi
        fi
    done < "${RUNTIME_DIR}/transactions.conf"
    [ "${missing}" -eq 0 ]
}

@test "every REXX program in transactions.conf exists on disk" {
    local missing=0
    while IFS=: read -r transid lang program rest; do
        [[ "${transid}" =~ ^[[:space:]]*# ]] && continue
        [ -z "${transid}" ] && continue

        if [ "${lang}" = "rexx" ]; then
            if [ ! -f "${RUNTIME_DIR}/rexx/${program}" ]; then
                echo "MISSING rexx: ${program} (TRANSID: ${transid})"
                missing=$((missing + 1))
            fi
        fi
    done < "${RUNTIME_DIR}/transactions.conf"
    [ "${missing}" -eq 0 ]
}

@test "every TRANSID is exactly 4 characters" {
    local bad=0
    while IFS=: read -r transid rest; do
        [[ "${transid}" =~ ^[[:space:]]*# ]] && continue
        [ -z "${transid}" ] && continue
        transid="${transid// /}"
        if [ "${#transid}" -ne 4 ]; then
            echo "BAD TRANSID length: '${transid}' (${#transid} chars)"
            bad=$((bad + 1))
        fi
    done < "${RUNTIME_DIR}/transactions.conf"
    [ "${bad}" -eq 0 ]
}

@test "MENU transaction is defined" {
    grep -q "^MENU:" "${RUNTIME_DIR}/transactions.conf"
}

@test "no old-style EM-prefix transids remain" {
    # EMHL, EMHI, EMMI etc. must all be gone
    local found
    found=$(grep -E "^EM[A-Z]{2}:" "${RUNTIME_DIR}/transactions.conf" || true)
    [ -z "${found}" ]
}

@test "DPR transactions use DPR ACL group" {
    # SCHD, TRAF, SPOT, MLIB etc. must include DPR in their groups field
    local bad=0
    for transid in SCHD TRAF SPOT MLIB MLBU COPY ADVT TLNT TBIL LCNS ALOG; do
        line=$(grep "^${transid}:" "${RUNTIME_DIR}/transactions.conf" || true)
        [ -z "${line}" ] && continue  # not yet implemented — skip
        if ! echo "${line}" | grep -q "DPR"; then
            echo "MISSING DPR group: ${transid}"
            bad=$((bad + 1))
        fi
    done
    [ "${bad}" -eq 0 ]
}
