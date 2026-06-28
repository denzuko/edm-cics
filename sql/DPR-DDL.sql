-- DPR-DDL.sql -- Da Planet Radio back-office schema
-- Replaces EDM-DPR.sql (which conflated back-office with automation layer).
-- Liquidsoap owns playout. This schema owns the business layer:
-- traffic, spots, music library, advertiser CRM, talent, billing, licensing.
-- ACL group: DPR
-- Run after EDM-DDL.sql against the edm database.

BEGIN;

-- -------------------------------------------------------------------
-- dpr_shows -- show schedule (kept from EDM-DPR.sql, expanded)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_shows (
    show_id         CHAR(8)         PRIMARY KEY,
    show_name       VARCHAR(60)     NOT NULL,
    host_userid     CHAR(8)         NOT NULL,
    day_of_week     CHAR(3)         NOT NULL,
    -- MON TUE WED THU FRI SAT SUN
    start_time      TIME            NOT NULL,
    duration_mins   SMALLINT        NOT NULL DEFAULT 60,
    format_clock    CHAR(8),
    -- FK to dpr_format_clocks.clock_id
    status          CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active S=Suspended H=Hiatus
    description     VARCHAR(254)    NOT NULL DEFAULT '',
    stream_url      VARCHAR(120)    NOT NULL DEFAULT '',
    reserved1       VARCHAR(80)     NOT NULL DEFAULT ''
);

INSERT INTO dpr_shows
    (show_id, show_name, host_userid, day_of_week,
     start_time, duration_mins, description, stream_url)
VALUES
    ('DPRMAIN ', 'Da Planet Radio', 'DPRHOST ', 'FRI',
     '21:00', 120, '', 'https://klaxon.dapla.net')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------------
-- dpr_format_clocks -- music format / rotation clocks
-- Defines what types of content play in each segment of a show hour.
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_format_clocks (
    clock_id        CHAR(8)         PRIMARY KEY,
    clock_name      VARCHAR(40)     NOT NULL,
    description     VARCHAR(120)    NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS dpr_clock_segments (
    clock_id        CHAR(8)         NOT NULL
                                    REFERENCES dpr_format_clocks(clock_id),
    position        SMALLINT        NOT NULL,
    -- 1-based segment position within the hour
    content_type    CHAR(4)         NOT NULL,
    -- MUSC=Music SPOT=Commercial JING=Jingle NEWS=News TLKB=Talk Break
    duration_secs   SMALLINT        NOT NULL DEFAULT 180,
    category        VARCHAR(20)     NOT NULL DEFAULT '',
    -- Music category for MUSC segments (e.g. ROCK TALK INFO)
    CONSTRAINT pk_clock_seg PRIMARY KEY (clock_id, position)
);

-- -------------------------------------------------------------------
-- dpr_music_library -- physical and digital asset catalog (MLIB)
-- Liquidsoap reads file_path for playout.
-- The mainframe owns the catalog metadata.
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_music_library (
    track_id        CHAR(12)        PRIMARY KEY,
    title           VARCHAR(120)    NOT NULL,
    artist          VARCHAR(80)     NOT NULL DEFAULT '',
    album           VARCHAR(80)     NOT NULL DEFAULT '',
    duration_secs   INTEGER         NOT NULL DEFAULT 0,
    file_path       VARCHAR(254)    NOT NULL DEFAULT '',
    -- Liquidsoap-compatible path; empty = physical media only
    media_type      CHAR(4)         NOT NULL DEFAULT 'DGTL',
    -- DGTL=Digital PHYS=Physical Vinyl CD CASS
    category        VARCHAR(20)     NOT NULL DEFAULT '',
    -- Rotation category matching dpr_clock_segments.category
    added_date      DATE            NOT NULL DEFAULT CURRENT_DATE,
    last_played     TIMESTAMP,
    play_count      INTEGER         NOT NULL DEFAULT 0,
    dnr_hours       SMALLINT        NOT NULL DEFAULT 2,
    -- Do-Not-Repeat window in hours
    status          CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active S=Suspended P=Pending review
    notes           VARCHAR(254)    NOT NULL DEFAULT '',
    reserved1       VARCHAR(80)     NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS dpr_mlib_category_idx
    ON dpr_music_library (category, status, last_played);

-- -------------------------------------------------------------------
-- dpr_traffic -- daily broadcast log (TRAF)
-- The traffic log is the authoritative schedule of what airs when.
-- Exported to Liquidsoap annotation file or SQL table for playout.
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_traffic (
    log_id          BIGSERIAL       PRIMARY KEY,
    log_date        DATE            NOT NULL,
    show_id         CHAR(8)         NOT NULL
                                    REFERENCES dpr_shows(show_id),
    position        SMALLINT        NOT NULL,
    -- Sequence within the day's log
    scheduled_time  TIME            NOT NULL,
    content_type    CHAR(4)         NOT NULL,
    -- SPOT MUSC JING NEWS TLKB LIIV
    content_id      VARCHAR(12),
    -- spot_id, track_id, or NULL for live
    content_title   VARCHAR(120)    NOT NULL DEFAULT '',
    duration_secs   INTEGER         NOT NULL DEFAULT 0,
    status          CHAR(1)         NOT NULL DEFAULT 'S',
    -- S=Scheduled A=Aired M=Missed
    aired_time      TIMESTAMP,
    CONSTRAINT uq_traffic_pos UNIQUE (log_date, show_id, position)
);

CREATE INDEX IF NOT EXISTS dpr_traffic_date_idx
    ON dpr_traffic (log_date, show_id, status);

-- -------------------------------------------------------------------
-- dpr_advertisers -- advertiser and agency CRM (ADVT)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_advertisers (
    advertiser_id   CHAR(8)         PRIMARY KEY,
    company_name    VARCHAR(60)     NOT NULL,
    contact_name    VARCHAR(40)     NOT NULL DEFAULT '',
    contact_email   VARCHAR(120)    NOT NULL DEFAULT '',
    contact_phone   VARCHAR(20)     NOT NULL DEFAULT '',
    agency_name     VARCHAR(60)     NOT NULL DEFAULT '',
    status          CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active I=Inactive P=Prospect
    created_date    DATE            NOT NULL DEFAULT CURRENT_DATE,
    notes           VARCHAR(254)    NOT NULL DEFAULT '',
    reserved1       VARCHAR(80)     NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------------
-- dpr_spots -- commercial/underwriting spot copy (SPOT)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_spots (
    spot_id         CHAR(10)        PRIMARY KEY,
    advertiser_id   CHAR(8)         NOT NULL
                                    REFERENCES dpr_advertisers(advertiser_id),
    spot_title      VARCHAR(80)     NOT NULL,
    duration_secs   SMALLINT        NOT NULL DEFAULT 30,
    file_path       VARCHAR(254)    NOT NULL DEFAULT '',
    copy_text       TEXT            NOT NULL DEFAULT '',
    isci_code       CHAR(8)         NOT NULL DEFAULT '',
    -- Industry Standard Commercial Identifier
    flight_start    DATE,
    flight_end      DATE,
    max_per_day     SMALLINT        NOT NULL DEFAULT 0,
    -- 0 = no daily cap
    status          CHAR(1)         NOT NULL DEFAULT 'P',
    -- P=Pending production A=Air-ready S=Suspended E=Expired
    air_ready_by    CHAR(8),
    -- userid who signed off air-ready
    air_ready_at    TIMESTAMP,
    created_date    DATE            NOT NULL DEFAULT CURRENT_DATE,
    reserved1       VARCHAR(80)     NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------------
-- dpr_traffic_orders -- spot booking against traffic (SPOT booking)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_traffic_orders (
    order_id        CHAR(10)        PRIMARY KEY,
    advertiser_id   CHAR(8)         NOT NULL
                                    REFERENCES dpr_advertisers(advertiser_id),
    spot_id         CHAR(10)        NOT NULL
                                    REFERENCES dpr_spots(spot_id),
    show_id         CHAR(8)         REFERENCES dpr_shows(show_id),
    -- NULL = run in any show
    flight_start    DATE            NOT NULL,
    flight_end      DATE            NOT NULL,
    spots_per_week  SMALLINT        NOT NULL DEFAULT 1,
    rate_per_spot   NUMERIC(10,2)   NOT NULL DEFAULT 0,
    total_value     NUMERIC(12,2)   NOT NULL DEFAULT 0,
    status          CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active C=Complete X=Cancelled
    booked_by       CHAR(8)         NOT NULL,
    booked_date     DATE            NOT NULL DEFAULT CURRENT_DATE,
    notes           VARCHAR(254)    NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------------
-- dpr_talent -- DJ and host roster (TLNT)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_talent (
    talent_id       CHAR(8)         PRIMARY KEY,
    stage_name      VARCHAR(40)     NOT NULL,
    real_name       VARCHAR(40)     NOT NULL DEFAULT '',
    contact_email   VARCHAR(120)    NOT NULL DEFAULT '',
    contact_phone   VARCHAR(20)     NOT NULL DEFAULT '',
    talent_type     CHAR(4)         NOT NULL DEFAULT 'DJ',
    -- DJ=DJ HOST=Show host NEWS=News reader PROD=Producer
    status          CHAR(1)         NOT NULL DEFAULT 'A',
    hire_date       DATE,
    notes           VARCHAR(254)    NOT NULL DEFAULT '',
    reserved1       VARCHAR(80)     NOT NULL DEFAULT ''
);

-- Map talent to shows
CREATE TABLE IF NOT EXISTS dpr_show_talent (
    show_id         CHAR(8)         NOT NULL
                                    REFERENCES dpr_shows(show_id),
    talent_id       CHAR(8)         NOT NULL
                                    REFERENCES dpr_talent(talent_id),
    role            CHAR(4)         NOT NULL DEFAULT 'HOST',
    -- HOST COHO PROD
    CONSTRAINT pk_show_talent PRIMARY KEY (show_id, talent_id)
);

-- -------------------------------------------------------------------
-- dpr_oncall -- on-air session log (kept and expanded)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_oncall (
    session_id      BIGSERIAL       PRIMARY KEY,
    show_id         CHAR(8)         NOT NULL
                                    REFERENCES dpr_shows(show_id),
    talent_id       CHAR(8)         REFERENCES dpr_talent(talent_id),
    on_air_at       TIMESTAMP       NOT NULL DEFAULT NOW(),
    off_air_at      TIMESTAMP,
    listener_peak   INTEGER         NOT NULL DEFAULT 0,
    log_date        DATE            NOT NULL DEFAULT CURRENT_DATE,
    notes           TEXT            NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------------
-- dpr_billing -- traffic billing: invoices from aired log (TBIL)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_billing (
    invoice_id      CHAR(10)        PRIMARY KEY,
    advertiser_id   CHAR(8)         NOT NULL
                                    REFERENCES dpr_advertisers(advertiser_id),
    order_id        CHAR(10)        REFERENCES dpr_traffic_orders(order_id),
    invoice_date    DATE            NOT NULL DEFAULT CURRENT_DATE,
    period_start    DATE            NOT NULL,
    period_end      DATE            NOT NULL,
    spots_aired     INTEGER         NOT NULL DEFAULT 0,
    spots_contracted INTEGER        NOT NULL DEFAULT 0,
    amount_due      NUMERIC(12,2)   NOT NULL DEFAULT 0,
    amount_paid     NUMERIC(12,2)   NOT NULL DEFAULT 0,
    status          CHAR(1)         NOT NULL DEFAULT 'O',
    -- O=Open P=Partial F=Paid V=Void
    due_date        DATE,
    notes           VARCHAR(254)    NOT NULL DEFAULT ''
);

-- -------------------------------------------------------------------
-- dpr_licensing -- play log for ASCAP/BMI/SESAC reporting (LCNS)
-- Append-only. Populated from dpr_traffic when status='A' (aired).
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_licensing (
    log_id          BIGSERIAL       PRIMARY KEY,
    aired_at        TIMESTAMP       NOT NULL,
    show_id         CHAR(8)         NOT NULL
                                    REFERENCES dpr_shows(show_id),
    track_id        CHAR(12)        REFERENCES dpr_music_library(track_id),
    title           VARCHAR(120)    NOT NULL DEFAULT '',
    artist          VARCHAR(80)     NOT NULL DEFAULT '',
    duration_secs   INTEGER         NOT NULL DEFAULT 0,
    licensing_body  CHAR(5)         NOT NULL DEFAULT '',
    -- ASCAP BMI SESAC PRO
    reported        BOOLEAN         NOT NULL DEFAULT FALSE
);

REVOKE UPDATE, DELETE ON dpr_licensing FROM PUBLIC;

CREATE INDEX IF NOT EXISTS dpr_licensing_date_idx
    ON dpr_licensing (aired_at, reported);

-- -------------------------------------------------------------------
-- dpr_alog -- on-air log from automation feed (ALOG)
-- What actually aired (fed from Liquidsoap via tmp_dir or SQL INSERT).
-- Reconciliation source against dpr_traffic.
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_alog (
    alog_id         BIGSERIAL       PRIMARY KEY,
    aired_at        TIMESTAMP       NOT NULL DEFAULT NOW(),
    show_id         CHAR(8)         REFERENCES dpr_shows(show_id),
    content_type    CHAR(4)         NOT NULL,
    content_id      VARCHAR(12),
    content_title   VARCHAR(120)    NOT NULL DEFAULT '',
    duration_secs   INTEGER         NOT NULL DEFAULT 0,
    source          CHAR(4)         NOT NULL DEFAULT 'AUTO',
    -- AUTO=Liquidsoap MANU=Manual entry
    traffic_log_id  BIGINT          REFERENCES dpr_traffic(log_id)
    -- NULL until reconciled against dpr_traffic
);

CREATE INDEX IF NOT EXISTS dpr_alog_date_idx
    ON dpr_alog (aired_at);

-- -------------------------------------------------------------------
-- dpr_copy -- spot production copy tracking (COPY)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_copy (
    copy_id         CHAR(10)        PRIMARY KEY,
    spot_id         CHAR(10)        NOT NULL
                                    REFERENCES dpr_spots(spot_id),
    version         SMALLINT        NOT NULL DEFAULT 1,
    status          CHAR(1)         NOT NULL DEFAULT 'D',
    -- D=Draft R=Review A=Approved X=Rejected
    copy_text       TEXT            NOT NULL DEFAULT '',
    reviewed_by     CHAR(8),
    reviewed_at     TIMESTAMP,
    notes           VARCHAR(254)    NOT NULL DEFAULT ''
);

COMMIT;
