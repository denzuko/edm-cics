-- EDM-DDL.sql -- EDM operational database schema
-- Run once against the 'edm' PostgreSQL database before starting BRICKS_TS.
-- Pattern follows bank_schema.sql: NUMERIC(15,2) for money,
-- reserved VARCHAR(80) columns for future expansion, BEGIN/COMMIT wrapper.
--
-- Create the database first:
--   createdb -U bricks edm
--   psql -U bricks edm < EDM-DDL.sql

BEGIN;

-- -------------------------------------------------------------------
-- edm_clients -- Master client registry (EDMMST)
-- Primary key: client_id CHAR(8), zero-padded
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_clients (
    client_id        CHAR(8)         PRIMARY KEY,
    client_type      CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Account C=Corporate G=Government R=Research
    risk_tier        SMALLINT        NOT NULL DEFAULT 3,
    -- 1=High 2=Elevated 3=Standard 4=Low
    last_name        VARCHAR(20)     NOT NULL,
    first_name       VARCHAR(15)     NOT NULL,
    title            CHAR(4)         NOT NULL DEFAULT '',
    department       VARCHAR(20)     NOT NULL DEFAULT '',
    location         CHAR(3)         NOT NULL DEFAULT 'ALB',
    -- ALB=Albany SYR=Syracuse NYC=New York RMT=Remote
    status           CHAR(1)         NOT NULL DEFAULT 'P',
    -- A=Active S=Suspended T=Terminated P=Pending
    created_date     DATE            NOT NULL DEFAULT CURRENT_DATE,
    last_activity    DATE,
    last_modified    DATE,
    asset_count      INTEGER         NOT NULL DEFAULT 0,
    asset_value      NUMERIC(15,2)   NOT NULL DEFAULT 0,
    flag_audit       CHAR(1)         NOT NULL DEFAULT 'N',
    flag_hold        CHAR(1)         NOT NULL DEFAULT 'N',
    flag_vip         CHAR(1)         NOT NULL DEFAULT 'N',
    -- VIP = key account; flag_hold and flag_audit require ADMIN to clear
    reserved1        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved2        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved3        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved4        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved5        VARCHAR(80)     NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS edm_clients_name_idx
    ON edm_clients (last_name, first_name);
CREATE INDEX IF NOT EXISTS edm_clients_status_idx
    ON edm_clients (status, location);

-- -------------------------------------------------------------------
-- edm_orders -- Acquisition order processing (EDMORD)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_orders (
    order_id         CHAR(10)        PRIMARY KEY,
    client_id        CHAR(8)         NOT NULL
                                     REFERENCES edm_clients(client_id),
    order_type       CHAR(2)         NOT NULL,
    -- MA=Mineral DA=Data HA=Hardware SA=System
    order_status     CHAR(1)         NOT NULL DEFAULT 'P',
    -- P=Pending A=Approved R=Rejected C=Complete X=Cancelled
    order_date       DATE            NOT NULL DEFAULT CURRENT_DATE,
    required_date    DATE,
    complete_date    DATE,
    order_value      NUMERIC(15,2)   NOT NULL DEFAULT 0,
    approved_by      CHAR(8),
    notes            VARCHAR(254)    NOT NULL DEFAULT '',
    reserved1        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved2        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved3        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved4        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved5        VARCHAR(80)     NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS edm_orders_client_idx
    ON edm_orders (client_id, order_date);

-- -------------------------------------------------------------------
-- edm_inventory -- Asset catalog (EDMINV)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_inventory (
    asset_id         CHAR(12)        PRIMARY KEY,
    asset_type       CHAR(2)         NOT NULL,
    -- MI=Mineral DT=Data HW=Hardware SW=Software AR=Archive
    asset_name       VARCHAR(40)     NOT NULL,
    client_id        CHAR(8)         REFERENCES edm_clients(client_id),
    order_id         CHAR(10)        REFERENCES edm_orders(order_id),
    status           CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active H=Hold D=Disposed T=Transferred
    acquired_date    DATE,
    value_original   NUMERIC(15,2)   NOT NULL DEFAULT 0,
    value_current    NUMERIC(15,2)   NOT NULL DEFAULT 0,
    location_code    CHAR(6)         NOT NULL DEFAULT '',
    notes            VARCHAR(254)    NOT NULL DEFAULT '',
    reserved1        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved2        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved3        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved4        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved5        VARCHAR(80)     NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------------
-- edm_ledger -- Account ledger (EDMACT)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_ledger (
    trans_id         CHAR(14)        PRIMARY KEY,
    -- Format: YYYYMMDDHHMMSS
    client_id        CHAR(8)         NOT NULL
                                     REFERENCES edm_clients(client_id),
    order_id         CHAR(10)        REFERENCES edm_orders(order_id),
    trans_type       CHAR(2)         NOT NULL,
    -- CR=Credit DB=Debit FE=Fee AD=Adjustment PY=Payment
    amount           NUMERIC(15,2)   NOT NULL,
    balance_after    NUMERIC(15,2)   NOT NULL,
    trans_date       DATE            NOT NULL,
    trans_time       TIME            NOT NULL,
    processed_by     CHAR(8)         NOT NULL,
    notes            VARCHAR(128)    NOT NULL DEFAULT '',
    reserved1        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved2        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved3        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved4        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved5        VARCHAR(80)     NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS edm_ledger_client_idx
    ON edm_ledger (client_id, trans_date);

-- -------------------------------------------------------------------
-- edm_security -- User access control and session tracking
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_security (
    userid           CHAR(8)         PRIMARY KEY,
    client_id        CHAR(8)         REFERENCES edm_clients(client_id),
    risk_tier        SMALLINT        NOT NULL DEFAULT 3,
    -- 1=High 2=Elevated 3=Standard 4=Low
    max_trans_auth   CHAR(4)         NOT NULL DEFAULT 'EM',
    -- EDM = all EDM transactions; EDMR = read-only; SECU = security only
    last_violation   DATE,
    violation_count  INTEGER         NOT NULL DEFAULT 0,
    last_login       DATE,
    last_trans       CHAR(4)         NOT NULL DEFAULT '',
    status           CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active S=Suspended L=Locked T=Terminated
    notes            VARCHAR(254)    NOT NULL DEFAULT '',
    reserved1        VARCHAR(80)     NOT NULL DEFAULT '',
    reserved2        VARCHAR(80)     NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------------
-- edm_audit -- Immutable audit log (EDMARC)
-- Append-only by policy. No UPDATE or DELETE permitted.
-- REVOKE UPDATE, DELETE ON edm_audit FROM PUBLIC after creation.
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_audit (
    seq_no           BIGSERIAL       PRIMARY KEY,
    trans_timestamp  TIMESTAMP       NOT NULL DEFAULT NOW(),
    userid           CHAR(8)         NOT NULL,
    transid          CHAR(4)         NOT NULL,
    program          CHAR(8)         NOT NULL,
    client_id        CHAR(8),
    action_code      CHAR(4)         NOT NULL,
    -- READ WRIT UPDT DELT AUTH VIOL LOGN LOGO
    before_image     VARCHAR(254),
    after_image      VARCHAR(254),
    result_code      CHAR(4)         NOT NULL,
    -- SUCC FAIL DENY ABND
    terminal_id      CHAR(4)         NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS edm_audit_ts_idx
    ON edm_audit (trans_timestamp);
CREATE INDEX IF NOT EXISTS edm_audit_user_idx
    ON edm_audit (userid, trans_timestamp);

-- Enforce immutability
REVOKE UPDATE, DELETE ON edm_audit FROM PUBLIC;


-- -------------------------------------------------------------------
-- sys_user_orgs -- maps BRICKS userids to org/ACL groups
-- Drives MENU transaction org detection and role-based dispatch.
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_user_orgs (
    userid  CHAR(8)  NOT NULL,
    grp     CHAR(8)  NOT NULL,
    CONSTRAINT pk_sys_user_orgs PRIMARY KEY (userid, grp)
);

-- Seed admin user
INSERT INTO sys_user_orgs (userid, grp)
VALUES ('admin   ', 'ADMIN')
ON CONFLICT DO NOTHING;

COMMIT;
