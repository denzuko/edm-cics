-- EDM-PRINT.sql -- PostScript report generation and print queue
-- Architecture:
--   BRICKS REXX/COBOL transactions INSERT into print_queue
--   PL/PgSQL function generates PostScript from query results
--   pg_notify('print_ready', job_id) fires for each job
--   Listener (pg_cron or external) picks up and spools/emails
--
-- PostScript generation: pure PL/PgSQL string assembly.
-- No Python, no JavaScript, no external dependencies.
-- Run after EDM-DDL.sql against the edm database.

BEGIN;

-- -------------------------------------------------------------------
-- print_queue -- outbound print/report job queue
-- -------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS print_queue (
    job_id          BIGSERIAL       PRIMARY KEY,
    queued_at       TIMESTAMP       NOT NULL DEFAULT NOW(),
    processed_at    TIMESTAMP,
    status          CHAR(1)         NOT NULL DEFAULT 'P',
    -- P=Pending R=Running C=Complete F=Failed
    report_type     VARCHAR(20)     NOT NULL,
    -- CLNT_RPT, ORDR_RPT, AUDT_RPT, BLNG_RPT, TICK_RPT, DPR_RPT
    requested_by    CHAR(8)         NOT NULL,
    destination     VARCHAR(4)      NOT NULL DEFAULT 'PRNT',
    -- PRNT=printer spool, MAIL=email via edm_mailq
    mail_list       VARCHAR(40),
    -- edm_maillists.list_name when destination=MAIL
    parameters      JSONB           NOT NULL DEFAULT '{}',
    -- Report-specific parameters (date range, client filter, etc.)
    postscript_doc  TEXT,
    -- Generated PostScript output
    error_detail    VARCHAR(254)    NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS print_queue_status_idx
    ON print_queue (status, queued_at)
    WHERE status IN ('P','R');

-- -------------------------------------------------------------------
-- ps_header() -- common PostScript document header
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ps_header(
    p_title     TEXT,
    p_date      TEXT DEFAULT TO_CHAR(NOW(), 'YYYY-MM-DD'),
    p_pagesize  TEXT DEFAULT 'letter'
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    v_width  INTEGER := 612;   -- letter width in points
    v_height INTEGER := 792;   -- letter height in points
BEGIN
    RETURN
        '%!PS-Adobe-3.0' || CHR(10) ||
        '%%Title: ' || p_title || CHR(10) ||
        '%%CreationDate: ' || p_date || CHR(10) ||
        '%%Creator: EDM CICS Report Generator' || CHR(10) ||
        '%%DocumentMedia: ' || p_pagesize ||
            ' ' || v_width || ' ' || v_height || ' 0 () ()' || CHR(10) ||
        '%%Pages: (atend)' || CHR(10) ||
        '%%EndComments' || CHR(10) ||
        CHR(10) ||
        '%%BeginProlog' || CHR(10) ||
        -- Font definitions
        '/Courier findfont 10 scalefont setfont' || CHR(10) ||
        '/HeaderFont /Helvetica-Bold findfont 12 scalefont def' || CHR(10) ||
        '/TitleFont  /Helvetica-Bold findfont 14 scalefont def' || CHR(10) ||
        -- Utility procedures
        '/showat { moveto show } def' || CHR(10) ||
        '/hline  { newpath moveto lineto stroke } def' || CHR(10) ||
        '/newpage { showpage } def' || CHR(10) ||
        '%%EndProlog' || CHR(10) ||
        '%%BeginSetup' || CHR(10) ||
        '%%EndSetup' || CHR(10);
END;
$$;

-- -------------------------------------------------------------------
-- ps_page_header() -- per-page header block
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ps_page_header(
    p_page_num  INTEGER,
    p_title     TEXT,
    p_date      TEXT DEFAULT TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI')
) RETURNS TEXT LANGUAGE plpgsql AS $$
BEGIN
    RETURN
        '%%Page: ' || p_page_num || ' ' || p_page_num || CHR(10) ||
        'TitleFont setfont' || CHR(10) ||
        '(' || REPLACE(p_title, '(', '\(') || ') 72 740 showat' || CHR(10) ||
        '/Courier findfont 8 scalefont setfont' || CHR(10) ||
        '(' || p_date || ') 430 740 showat' || CHR(10) ||
        -- Rule under header
        '72 730 540 730 hline' || CHR(10) ||
        '/Courier findfont 10 scalefont setfont' || CHR(10);
END;
$$;

-- -------------------------------------------------------------------
-- ps_footer() -- document trailer
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ps_footer(p_total_pages INTEGER)
RETURNS TEXT LANGUAGE plpgsql AS $$
BEGIN
    RETURN
        'showpage' || CHR(10) ||
        '%%Trailer' || CHR(10) ||
        '%%Pages: ' || p_total_pages || CHR(10) ||
        '%%EOF' || CHR(10);
END;
$$;

-- -------------------------------------------------------------------
-- rpt_client_list() -- CLNT_RPT: active client listing
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpt_client_list(
    p_location  CHAR(3) DEFAULT NULL,
    p_status    CHAR(1) DEFAULT 'A'
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    v_doc       TEXT := '';
    v_y         INTEGER;
    v_page      INTEGER := 1;
    v_linecount INTEGER := 0;
    v_lpp       INTEGER := 50;  -- lines per page
    rec         RECORD;
BEGIN
    v_doc := ps_header('EDM Client Registry Report');
    v_doc := v_doc || ps_page_header(v_page, 'EDM CLIENT REGISTRY');

    -- Column headers
    v_y := 710;
    v_doc := v_doc ||
        '/Helvetica-Bold findfont 9 scalefont setfont' || CHR(10) ||
        '(CLIENT ID) 72 ' || v_y || ' showat' || CHR(10) ||
        '(NAME                        ) 130 ' || v_y || ' showat' || CHR(10) ||
        '(DEPT           ) 330 ' || v_y || ' showat' || CHR(10) ||
        '(LOC) 450 ' || v_y || ' showat' || CHR(10) ||
        '(RISK) 490 ' || v_y || ' showat' || CHR(10) ||
        '(ST) 530 ' || v_y || ' showat' || CHR(10) ||
        '72 705 540 705 hline' || CHR(10) ||
        '/Courier findfont 9 scalefont setfont' || CHR(10);
    v_y := 695;

    FOR rec IN
        SELECT client_id,
               RPAD(last_name || ', ' || first_name, 28) AS name,
               RPAD(COALESCE(department,''), 15)         AS dept,
               location,
               risk_tier,
               status
        FROM   edm_clients
        WHERE  status = COALESCE(p_status, status)
          AND  location = COALESCE(p_location, location)
        ORDER  BY last_name, first_name
    LOOP
        IF v_linecount >= v_lpp THEN
            v_doc := v_doc || 'showpage' || CHR(10);
            v_page := v_page + 1;
            v_linecount := 0;
            v_doc := v_doc || ps_page_header(v_page, 'EDM CLIENT REGISTRY (cont.)');
            v_y := 695;
        END IF;

        v_doc := v_doc ||
            '(' || REPLACE(TRIM(rec.client_id),'(','\(') || ') 72 ' || v_y || ' showat' || CHR(10) ||
            '(' || REPLACE(rec.name,           '(','\(') || ') 130 '|| v_y || ' showat' || CHR(10) ||
            '(' || REPLACE(rec.dept,           '(','\(') || ') 330 '|| v_y || ' showat' || CHR(10) ||
            '(' || TRIM(rec.location)                     || ') 450 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.risk_tier::TEXT                    || ') 490 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.status                             || ') 530 '|| v_y || ' showat' || CHR(10);

        v_y := v_y - 13;
        v_linecount := v_linecount + 1;
    END LOOP;

    v_doc := v_doc || ps_footer(v_page);
    RETURN v_doc;
END;
$$;

-- -------------------------------------------------------------------
-- rpt_audit_log() -- AUDT_RPT: audit log for date range
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpt_audit_log(
    p_from_date TIMESTAMP DEFAULT NOW() - INTERVAL '24 hours',
    p_to_date   TIMESTAMP DEFAULT NOW()
) RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    v_doc       TEXT := '';
    v_y         INTEGER;
    v_page      INTEGER := 1;
    v_linecount INTEGER := 0;
    v_lpp       INTEGER := 48;
    rec         RECORD;
BEGIN
    v_doc := ps_header('EDM Audit Log Report');
    v_doc := v_doc || ps_page_header(v_page, 'EDM AUDIT LOG');

    v_y := 710;
    v_doc := v_doc ||
        '/Helvetica-Bold findfont 9 scalefont setfont' || CHR(10) ||
        '(TIMESTAMP          ) 72 ' || v_y || ' showat' || CHR(10) ||
        '(USER    ) 200 '           || v_y || ' showat' || CHR(10) ||
        '(TRANS) 260 '              || v_y || ' showat' || CHR(10) ||
        '(ACTION) 310 '             || v_y || ' showat' || CHR(10) ||
        '(RESULT) 360 '             || v_y || ' showat' || CHR(10) ||
        '(CLIENT ) 410 '            || v_y || ' showat' || CHR(10) ||
        '72 705 540 705 hline'      || CHR(10) ||
        '/Courier findfont 8 scalefont setfont' || CHR(10);
    v_y := 695;

    FOR rec IN
        SELECT TO_CHAR(trans_timestamp,'YYYY-MM-DD HH24:MI:SS') AS ts,
               RPAD(TRIM(userid),8)    AS uid,
               transid,
               action_code,
               result_code,
               COALESCE(TRIM(client_id),'') AS cid
        FROM   edm_audit
        WHERE  trans_timestamp BETWEEN p_from_date AND p_to_date
        ORDER  BY trans_timestamp
    LOOP
        IF v_linecount >= v_lpp THEN
            v_doc := v_doc || 'showpage' || CHR(10);
            v_page := v_page + 1;
            v_linecount := 0;
            v_doc := v_doc || ps_page_header(v_page, 'EDM AUDIT LOG (cont.)');
            v_y := 695;
        END IF;

        v_doc := v_doc ||
            '(' || rec.ts          || ') 72 ' || v_y || ' showat' || CHR(10) ||
            '(' || rec.uid         || ') 200 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.transid     || ') 260 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.action_code || ') 310 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.result_code || ') 360 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.cid         || ') 410 '|| v_y || ' showat' || CHR(10);

        v_y := v_y - 11;
        v_linecount := v_linecount + 1;
    END LOOP;

    v_doc := v_doc || ps_footer(v_page);
    RETURN v_doc;
END;
$$;

-- -------------------------------------------------------------------
-- rpt_open_orders() -- ORDR_RPT: open acquisition orders
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpt_open_orders() RETURNS TEXT LANGUAGE plpgsql AS $$
DECLARE
    v_doc       TEXT := '';
    v_y         INTEGER;
    v_page      INTEGER := 1;
    v_linecount INTEGER := 0;
    v_lpp       INTEGER := 45;
    rec         RECORD;
BEGIN
    v_doc := ps_header('EDM Open Orders Report');
    v_doc := v_doc || ps_page_header(v_page, 'EDM OPEN ACQUISITION ORDERS');

    v_y := 710;
    v_doc := v_doc ||
        '/Helvetica-Bold findfont 9 scalefont setfont' || CHR(10) ||
        '(ORDER ID  ) 72 ' || v_y || ' showat' || CHR(10) ||
        '(CLIENT   ) 150 ' || v_y || ' showat' || CHR(10) ||
        '(TYPE) 220 '      || v_y || ' showat' || CHR(10) ||
        '(DATE      ) 260 '|| v_y || ' showat' || CHR(10) ||
        '(VALUE          ) 350 ' || v_y || ' showat' || CHR(10) ||
        '(ST) 470 '        || v_y || ' showat' || CHR(10) ||
        '72 705 540 705 hline' || CHR(10) ||
        '/Courier findfont 9 scalefont setfont' || CHR(10);
    v_y := 695;

    FOR rec IN
        SELECT o.order_id,
               TRIM(o.client_id)          AS cid,
               o.order_type,
               TO_CHAR(o.order_date,'YYYY-MM-DD') AS odate,
               TO_CHAR(o.order_value,'FM$999,999,990.00') AS oval,
               o.order_status
        FROM   edm_orders o
        WHERE  o.order_status IN ('P','A')
        ORDER  BY o.order_date DESC
    LOOP
        IF v_linecount >= v_lpp THEN
            v_doc := v_doc || 'showpage' || CHR(10);
            v_page := v_page + 1;
            v_linecount := 0;
            v_doc := v_doc || ps_page_header(v_page, 'EDM OPEN ORDERS (cont.)');
            v_y := 695;
        END IF;

        v_doc := v_doc ||
            '(' || TRIM(rec.order_id)  || ') 72 ' || v_y || ' showat' || CHR(10) ||
            '(' || rec.cid             || ') 150 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.order_type      || ') 220 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.odate           || ') 260 '|| v_y || ' showat' || CHR(10) ||
            '(' || REPLACE(rec.oval,'(','\(') || ') 350 '|| v_y || ' showat' || CHR(10) ||
            '(' || rec.order_status    || ') 470 '|| v_y || ' showat' || CHR(10);

        v_y := v_y - 13;
        v_linecount := v_linecount + 1;
    END LOOP;

    v_doc := v_doc || ps_footer(v_page);
    RETURN v_doc;
END;
$$;

-- -------------------------------------------------------------------
-- process_print_queue() -- dequeue, generate PS, notify/email
-- Called by pg_cron or explicit CALL from BRICKS REXX
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_print_queue() RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE
    rec         RECORD;
    v_ps        TEXT;
    v_processed INTEGER := 0;
BEGIN
    FOR rec IN
        SELECT * FROM print_queue
        WHERE  status = 'P'
        ORDER  BY queued_at
        FOR UPDATE SKIP LOCKED
    LOOP
        BEGIN
            -- Mark running
            UPDATE print_queue SET status='R' WHERE job_id=rec.job_id;

            -- Generate PostScript by report type
            v_ps := CASE rec.report_type
                WHEN 'CLNT_RPT' THEN rpt_client_list(
                    (rec.parameters->>'location')::CHAR(3),
                    COALESCE(rec.parameters->>'status','A')::CHAR(1))
                WHEN 'ORDR_RPT' THEN rpt_open_orders()
                WHEN 'AUDT_RPT' THEN rpt_audit_log(
                    COALESCE((rec.parameters->>'from_date')::TIMESTAMP,
                             NOW()-INTERVAL '24 hours'),
                    COALESCE((rec.parameters->>'to_date')::TIMESTAMP, NOW()))
                ELSE '% Unknown report type: ' || rec.report_type || CHR(10)
            END;

            -- Store generated PostScript
            UPDATE print_queue
            SET    postscript_doc = v_ps,
                   status         = 'C',
                   processed_at   = NOW()
            WHERE  job_id = rec.job_id;

            -- Route: email via edm_mailq if destination=MAIL
            IF rec.destination = 'MAIL' AND rec.mail_list IS NOT NULL THEN
                INSERT INTO edm_mailq
                    (to_addr, subject, body_text, transid, userid)
                SELECT list_addr,
                       'EDM Report: ' || rec.report_type || ' ' ||
                           TO_CHAR(NOW(),'YYYY-MM-DD'),
                       v_ps,
                       'REPT',
                       rec.requested_by
                FROM   edm_maillists
                WHERE  list_name = rec.mail_list
                  AND  status    = 'A';
            END IF;

            -- pg_notify for printer spool listener
            IF rec.destination = 'PRNT' THEN
                PERFORM pg_notify('print_ready', rec.job_id::TEXT);
            END IF;

            v_processed := v_processed + 1;

        EXCEPTION WHEN OTHERS THEN
            UPDATE print_queue
            SET    status       = 'F',
                   error_detail = SQLERRM,
                   processed_at = NOW()
            WHERE  job_id = rec.job_id;
        END;
    END LOOP;

    RETURN v_processed;
END;
$$;

-- -------------------------------------------------------------------
-- Trigger: auto-process queue on INSERT if destination is immediate
-- For batch jobs use pg_cron: SELECT cron.schedule('print-queue',
--   '* * * * *', 'SELECT process_print_queue()');
-- -------------------------------------------------------------------
CREATE OR REPLACE FUNCTION print_queue_notify() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM pg_notify('print_job_queued', NEW.job_id::TEXT);
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_print_queue_notify ON print_queue;
CREATE TRIGGER trg_print_queue_notify
    AFTER INSERT ON print_queue
    FOR EACH ROW EXECUTE FUNCTION print_queue_notify();

COMMIT;
