-- EDM-HELPDESK.sql -- Helpdesk ticketing and CMDB schema
-- Run after EDM-DDL.sql against the edm database.

BEGIN;

CREATE SEQUENCE IF NOT EXISTS edm_ticket_seq
    AS BIGINT START WITH 1 INCREMENT BY 1 NO CYCLE;

-- -------------------------------------------------------------------
-- edm_tickets -- helpdesk ticket queue (EDMHD subsystem)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_tickets (
    ticket_id       CHAR(10)        PRIMARY KEY,
    opened_at       TIMESTAMP       NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMP,
    status          CHAR(1)         NOT NULL DEFAULT 'O',
    priority        CHAR(1)         NOT NULL DEFAULT '3',
    category        VARCHAR(20)     NOT NULL DEFAULT 'GENERAL',
    client_id       CHAR(8)         REFERENCES edm_clients(client_id),
    assigned_to     CHAR(8),
    subject         VARCHAR(120)    NOT NULL,
    description     TEXT            NOT NULL DEFAULT '',
    resolution      TEXT            NOT NULL DEFAULT '',
    annoyance_event CHAR(1)         NOT NULL DEFAULT 'N',
    reserved1       VARCHAR(80)     NOT NULL DEFAULT '',
    reserved2       VARCHAR(80)     NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS edm_tickets_status_idx
    ON edm_tickets (status, priority, opened_at);
CREATE INDEX IF NOT EXISTS edm_tickets_client_idx
    ON edm_tickets (client_id, status);

-- -------------------------------------------------------------------
-- edm_ticket_notes -- work log per ticket
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_ticket_notes (
    note_id         BIGSERIAL       PRIMARY KEY,
    ticket_id       CHAR(10)        NOT NULL
                                    REFERENCES edm_tickets(ticket_id),
    noted_at        TIMESTAMP       NOT NULL DEFAULT NOW(),
    userid          CHAR(8)         NOT NULL,
    note_type       CHAR(1)         NOT NULL DEFAULT 'N',
    note_text       TEXT            NOT NULL
);

-- -------------------------------------------------------------------
-- edm_cmdb_items -- Configuration Item registry
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_cmdb_items (
    ci_id           CHAR(12)        PRIMARY KEY,
    ci_type         CHAR(4)         NOT NULL,
    -- SRVR WKST NETW STRG SOFT PROC CONT MAIN
    ci_name         VARCHAR(60)     NOT NULL,
    ci_status       CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active D=Decommissioned P=Planned M=Maintenance
    owner_userid    CHAR(8),
    client_id       CHAR(8)         REFERENCES edm_clients(client_id),
    location        CHAR(6)         NOT NULL DEFAULT '',
    ip_address      VARCHAR(45)     NOT NULL DEFAULT '',
    os_version      VARCHAR(40)     NOT NULL DEFAULT '',
    installed_date  DATE,
    last_scan       DATE,
    criticality     CHAR(1)         NOT NULL DEFAULT '3',
    description     VARCHAR(254)    NOT NULL DEFAULT '',
    reserved1       VARCHAR(80)     NOT NULL DEFAULT '',
    reserved2       VARCHAR(80)     NOT NULL DEFAULT '',
    reserved3       VARCHAR(80)     NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS edm_cmdb_type_idx
    ON edm_cmdb_items (ci_type, ci_status);

-- -------------------------------------------------------------------
-- edm_cmdb_relations -- CI dependency map
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_cmdb_relations (
    rel_id          BIGSERIAL       PRIMARY KEY,
    from_ci         CHAR(12)        NOT NULL
                                    REFERENCES edm_cmdb_items(ci_id),
    rel_type        CHAR(8)         NOT NULL,
    -- DEPENDS HOSTS RUNS CONNECTS BACKUPS MONITORS
    to_ci           CHAR(12)        NOT NULL
                                    REFERENCES edm_cmdb_items(ci_id),
    notes           VARCHAR(120)    NOT NULL DEFAULT ''
);

-- Seed: the BRICKS_TS instance itself as a CMDB CI
INSERT INTO edm_cmdb_items
    (ci_id, ci_type, ci_name, ci_status, criticality, description)
VALUES
    ('CIMAIN00000001', 'MAIN', 'EDM BRICKS_TS Mainframe',
     'A', '1', 'Primary CICS transaction server')
ON CONFLICT DO NOTHING;

COMMIT;
