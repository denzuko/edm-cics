-- EDM-DPR.sql -- DPR radio back-office schema
-- ACL group: DPR
-- Run after EDM-DDL.sql against the edm database.

BEGIN;

-- -------------------------------------------------------------------
-- dpr_shows -- show schedule
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_shows (
    show_id         CHAR(8)         PRIMARY KEY,
    show_name       VARCHAR(60)     NOT NULL,
    host_userid     CHAR(8)         NOT NULL,
    day_of_week     CHAR(3)         NOT NULL,
    -- MON TUE WED THU FRI SAT SUN
    start_time      TIME            NOT NULL,
    duration_mins   SMALLINT        NOT NULL DEFAULT 60,
    status          CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active S=Suspended H=Hiatus
    description     VARCHAR(254)    NOT NULL DEFAULT '',
    stream_url      VARCHAR(120)    NOT NULL DEFAULT '',
    reserved1       VARCHAR(80)     NOT NULL DEFAULT ''
);

-- Seed default show
INSERT INTO dpr_shows
    (show_id, show_name, host_userid, day_of_week,
     start_time, duration_mins, description, stream_url)
VALUES
    ('DPRMAIN ', 'Da Planet Radio', 'DPRHOST ', 'FRI',
     '21:00', 120, '', 'https://klaxon.dapla.net')
ON CONFLICT DO NOTHING;

-- -------------------------------------------------------------------
-- dpr_playlist -- audio track library
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_playlist (
    track_id        CHAR(12)        PRIMARY KEY,
    show_id         CHAR(8)         REFERENCES dpr_shows(show_id),
    track_title     VARCHAR(120)    NOT NULL,
    artist          VARCHAR(80)     NOT NULL DEFAULT '',
    duration_secs   INTEGER         NOT NULL DEFAULT 0,
    file_path       VARCHAR(254)    NOT NULL DEFAULT '',
    -- Liquidsoap-compatible file path
    track_type      CHAR(4)         NOT NULL DEFAULT 'MUSC',
    -- MUSC JING SPOT NEWS LIIV
    queued_at       TIMESTAMP,
    played_at       TIMESTAMP,
    play_count      INTEGER         NOT NULL DEFAULT 0,
    reserved1       VARCHAR(80)     NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS dpr_playlist_show_idx
    ON dpr_playlist (show_id, queued_at);

-- -------------------------------------------------------------------
-- dpr_oncall -- on-air session log
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dpr_oncall (
    session_id      BIGSERIAL       PRIMARY KEY,
    show_id         CHAR(8)         NOT NULL
                                    REFERENCES dpr_shows(show_id),
    host_userid     CHAR(8)         NOT NULL,
    on_air_at       TIMESTAMP       NOT NULL DEFAULT NOW(),
    off_air_at      TIMESTAMP,
    listener_peak   INTEGER         NOT NULL DEFAULT 0,
    notes           TEXT            NOT NULL DEFAULT ''
);

COMMIT;
