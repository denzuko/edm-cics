-- EDM-MAILQ.sql -- Email outbox queue for EDM ARG helpdesk and
-- customer notifications. Pattern: BRICKS transactions INSERT into
-- edm_mailq; an external process (pg_smtp_client trigger, pg_cron
-- job, or sidecar) drains the queue and delivers via SMTP.
--
-- This keeps SMTP configuration out of BRICKS_TS entirely.
-- Run against the edm database after EDM-DDL.sql.

BEGIN;

-- -------------------------------------------------------------------
-- edm_mailq -- outbound email queue (append by BRICKS, drain by relay)
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_mailq (
    msg_id          BIGSERIAL       PRIMARY KEY,
    queued_at       TIMESTAMP       NOT NULL DEFAULT NOW(),
    sent_at         TIMESTAMP,
    status          CHAR(1)         NOT NULL DEFAULT 'P',
    -- P=Pending S=Sent F=Failed R=Retry
    retry_count     SMALLINT        NOT NULL DEFAULT 0,
    from_addr       VARCHAR(120)    NOT NULL DEFAULT 'helpdesk@ellisondm.net',
    to_addr         VARCHAR(120)    NOT NULL,
    -- Recipient: looked up from edm_clients.email or explicit address
    client_id       CHAR(8),
    -- NULL for non-client messages (e.g. admin alerts)
    subject         VARCHAR(254)    NOT NULL,
    body_text       TEXT            NOT NULL,
    transid         CHAR(4)         NOT NULL DEFAULT '',
    -- Which BRICKS transaction queued this message
    userid          CHAR(8)         NOT NULL DEFAULT '',
    error_detail    VARCHAR(254)    NOT NULL DEFAULT '',
    CONSTRAINT fk_mailq_client
        FOREIGN KEY (client_id) REFERENCES edm_clients(client_id)
);

CREATE INDEX IF NOT EXISTS edm_mailq_status_idx
    ON edm_mailq (status, queued_at)
    WHERE status IN ('P', 'R');

-- -------------------------------------------------------------------
-- edm_maillists -- mailing list registry
-- Lists that BRICKS transactions can send to by list name.
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edm_maillists (
    list_name       VARCHAR(40)     PRIMARY KEY,
    -- e.g. 'helpdesk', 'customers-active', 'compliance-notices'
    description     VARCHAR(120)    NOT NULL DEFAULT '',
    list_addr       VARCHAR(120)    NOT NULL,
    -- External list address (Mailman, Listmonk, etc.)
    owner_userid    CHAR(8)         NOT NULL,
    status          CHAR(1)         NOT NULL DEFAULT 'A',
    -- A=Active S=Suspended
    created_date    DATE            NOT NULL DEFAULT CURRENT_DATE
);

-- Seed EDM ARG mailing lists
INSERT INTO edm_maillists (list_name, description, list_addr, owner_userid)
VALUES
    ('helpdesk',          'EDM Helpdesk queue',
     'helpdesk@ellisondm.net', 'BOFH    '),
    ('customers-active',  'All active acquisition specialists',
     'customers@ellisondm.net', 'BOFH    '),
    ('compliance',        'Compliance notices and Annoyance Rank alerts',
     'compliance@ellisondm.net', 'BOFH    ')
ON CONFLICT DO NOTHING;

COMMIT;
