-- =================================================================
-- EDM-DDL.sql - Ellison Digital Minerals SQL Schema
-- Episode 4+ - EDM CICS Tutorial Series
-- Replaces VSAM KSDS backend with relational tables
-- Compatible with: DB2, SQLite, PostgreSQL
-- =================================================================

-- ---------------------------------------------------------------
-- EDMMST - Master Client Registry
-- Mirrors VSAM KSDS layout from EDMMSTR.cpy copybook
-- ---------------------------------------------------------------
CREATE TABLE EDMMST (
    CLIENT_ID        CHAR(8)         NOT NULL,
    CLIENT_TYPE      CHAR(1)         NOT NULL DEFAULT 'A',
    ANNOYANCE_RANK   SMALLINT        NOT NULL DEFAULT 0,
    LAST_NAME        CHAR(20)        NOT NULL,
    FIRST_NAME       CHAR(15)        NOT NULL,
    TITLE            CHAR(4),
    DEPARTMENT       CHAR(20),
    LOCATION         CHAR(3),
    STATUS           CHAR(1)         NOT NULL DEFAULT 'P',
    CREATED_DATE     DECIMAL(8,0)    NOT NULL,
    LAST_ACTIVITY    DECIMAL(8,0),
    LAST_MODIFIED    DECIMAL(8,0),
    ASSET_COUNT      INTEGER         NOT NULL DEFAULT 0,
    ASSET_VALUE      DECIMAL(13,2)   NOT NULL DEFAULT 0,
    FLAG_AUDIT       CHAR(1)         NOT NULL DEFAULT 'N',
    FLAG_HOLD        CHAR(1)         NOT NULL DEFAULT 'N',
    FLAG_VIP         CHAR(1)         NOT NULL DEFAULT 'N',
    CONSTRAINT PK_EDMMST PRIMARY KEY (CLIENT_ID),
    CONSTRAINT CK_EDMMST_TYPE
        CHECK (CLIENT_TYPE IN ('A','C','G','R')),
    CONSTRAINT CK_EDMMST_STATUS
        CHECK (STATUS IN ('A','S','T','P')),
    CONSTRAINT CK_EDMMST_LOC
        CHECK (LOCATION IN ('ALB','SYR','NYC','RMT'))
);

-- ---------------------------------------------------------------
-- EDMORD - Acquisition Order Processing
-- ---------------------------------------------------------------
CREATE TABLE EDMORD (
    ORDER_ID         CHAR(10)        NOT NULL,
    CLIENT_ID        CHAR(8)         NOT NULL,
    ORDER_TYPE       CHAR(2)         NOT NULL,
    -- MA=Mineral Acquisition, DA=Data Acquisition,
    -- HA=Hardware Acquisition, SA=System Acquisition
    ORDER_STATUS     CHAR(1)         NOT NULL DEFAULT 'P',
    -- P=Pending, A=Approved, R=Rejected, C=Complete, X=Cancelled
    ORDER_DATE       DECIMAL(8,0)    NOT NULL,
    REQUIRED_DATE    DECIMAL(8,0),
    COMPLETE_DATE    DECIMAL(8,0),
    ORDER_VALUE      DECIMAL(13,2)   NOT NULL DEFAULT 0,
    APPROVED_BY      CHAR(8),
    NOTES            VARCHAR(254),
    CONSTRAINT PK_EDMORD PRIMARY KEY (ORDER_ID),
    CONSTRAINT FK_EDMORD_CLIENT
        FOREIGN KEY (CLIENT_ID) REFERENCES EDMMST(CLIENT_ID),
    CONSTRAINT CK_EDMORD_TYPE
        CHECK (ORDER_TYPE IN ('MA','DA','HA','SA')),
    CONSTRAINT CK_EDMORD_STATUS
        CHECK (ORDER_STATUS IN ('P','A','R','C','X'))
);

-- ---------------------------------------------------------------
-- EDMINV - Asset Inventory
-- Minerals, data assets, legacy hardware
-- ---------------------------------------------------------------
CREATE TABLE EDMINV (
    ASSET_ID         CHAR(12)        NOT NULL,
    ASSET_TYPE       CHAR(2)         NOT NULL,
    -- MI=Mineral, DT=Data, HW=Hardware, SW=Software, AR=Archive
    ASSET_NAME       CHAR(40)        NOT NULL,
    CLIENT_ID        CHAR(8),
    ORDER_ID         CHAR(10),
    STATUS           CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active, H=Hold, D=Disposed, T=Transferred
    ACQUIRED_DATE    DECIMAL(8,0),
    VALUE_ORIGINAL   DECIMAL(13,2)   NOT NULL DEFAULT 0,
    VALUE_CURRENT    DECIMAL(13,2)   NOT NULL DEFAULT 0,
    LOCATION_CODE    CHAR(6),
    NOTES            VARCHAR(254),
    CONSTRAINT PK_EDMINV PRIMARY KEY (ASSET_ID),
    CONSTRAINT FK_EDMINV_CLIENT
        FOREIGN KEY (CLIENT_ID) REFERENCES EDMMST(CLIENT_ID),
    CONSTRAINT CK_EDMINV_TYPE
        CHECK (ASSET_TYPE IN ('MI','DT','HW','SW','AR'))
);

-- ---------------------------------------------------------------
-- EDMACT - Account Ledger
-- ---------------------------------------------------------------
CREATE TABLE EDMACT (
    TRANS_ID         CHAR(14)        NOT NULL,
    -- Format: YYYYMMDDHHMMSS
    CLIENT_ID        CHAR(8)         NOT NULL,
    ORDER_ID         CHAR(10),
    TRANS_TYPE       CHAR(2)         NOT NULL,
    -- CR=Credit, DB=Debit, FE=Fee, AD=Adjustment, PY=Payment
    AMOUNT           DECIMAL(13,2)   NOT NULL,
    BALANCE_AFTER    DECIMAL(13,2)   NOT NULL,
    TRANS_DATE       DECIMAL(8,0)    NOT NULL,
    TRANS_TIME       DECIMAL(6,0)    NOT NULL,
    PROCESSED_BY     CHAR(8)         NOT NULL,
    NOTES            VARCHAR(128),
    CONSTRAINT PK_EDMACT PRIMARY KEY (TRANS_ID),
    CONSTRAINT FK_EDMACT_CLIENT
        FOREIGN KEY (CLIENT_ID) REFERENCES EDMMST(CLIENT_ID),
    CONSTRAINT CK_EDMACT_TYPE
        CHECK (TRANS_TYPE IN ('CR','DB','FE','AD','PY'))
);

-- ---------------------------------------------------------------
-- EDMSEC - Security and Access Control
-- Annoyance Rank tracking and transaction authorization
-- ---------------------------------------------------------------
CREATE TABLE EDMSEC (
    USERID           CHAR(8)         NOT NULL,
    CLIENT_ID        CHAR(8),
    ANNOYANCE_RANK   SMALLINT        NOT NULL DEFAULT 0,
    MAX_TRANS_AUTH   CHAR(4),
    -- Maximum authorized transaction ID prefix (e.g. EDM0=read only)
    LAST_VIOLATION   DECIMAL(8,0),
    VIOLATION_COUNT  INTEGER         NOT NULL DEFAULT 0,
    LAST_LOGIN       DECIMAL(8,0),
    LAST_TRANS       CHAR(4),
    STATUS           CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active, S=Suspended, L=Locked, T=Terminated
    NOTES            VARCHAR(254),
    CONSTRAINT PK_EDMSEC PRIMARY KEY (USERID),
    CONSTRAINT FK_EDMSEC_CLIENT
        FOREIGN KEY (CLIENT_ID) REFERENCES EDMMST(CLIENT_ID)
);

-- ---------------------------------------------------------------
-- EDMARC - Immutable Audit Ledger
-- Append-only; no UPDATE or DELETE permitted
-- Mirrors ESDS VSAM access pattern
-- ---------------------------------------------------------------
CREATE TABLE EDMARC (
    SEQ_NO           INTEGER         NOT NULL
                     GENERATED ALWAYS AS IDENTITY,
    TRANS_TIMESTAMP  DECIMAL(14,0)   NOT NULL,
    -- Format: YYYYMMDDHHMMSS
    USERID           CHAR(8)         NOT NULL,
    TRANSID          CHAR(4)         NOT NULL,
    PROGRAM          CHAR(8)         NOT NULL,
    CLIENT_ID        CHAR(8),
    ACTION_CODE      CHAR(4)         NOT NULL,
    -- READ, WRIT, UPDT, DELT, AUTH, VIOL, LOGN, LOGO
    BEFORE_IMAGE     VARCHAR(254),
    AFTER_IMAGE      VARCHAR(254),
    RESULT_CODE      CHAR(4)         NOT NULL,
    -- SUCC, FAIL, DENY, ABND
    TERMINAL_ID      CHAR(4),
    CONSTRAINT PK_EDMARC PRIMARY KEY (SEQ_NO)
);

-- No UPDATE or DELETE on EDMARC — enforce at application layer
-- and via database grant: REVOKE UPDATE, DELETE ON EDMARC FROM PUBLIC

-- ---------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------
CREATE INDEX IX_EDMMST_NAME
    ON EDMMST (LAST_NAME, FIRST_NAME);

CREATE INDEX IX_EDMMST_STATUS
    ON EDMMST (STATUS, LOCATION);

CREATE INDEX IX_EDMORD_CLIENT
    ON EDMORD (CLIENT_ID, ORDER_DATE);

CREATE INDEX IX_EDMORD_STATUS
    ON EDMORD (ORDER_STATUS, ORDER_DATE);

CREATE INDEX IX_EDMINV_CLIENT
    ON EDMINV (CLIENT_ID);

CREATE INDEX IX_EDMACT_CLIENT
    ON EDMACT (CLIENT_ID, TRANS_DATE);

CREATE INDEX IX_EDMARC_TS
    ON EDMARC (TRANS_TIMESTAMP);

CREATE INDEX IX_EDMARC_USERID
    ON EDMARC (USERID, TRANS_TIMESTAMP);
