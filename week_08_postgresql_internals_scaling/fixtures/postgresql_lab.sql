-- Week 8 PostgreSQL laboratory fixture.
-- Run only in a dedicated learning database after verifying current_database().
-- This script creates schema week8_lab and stops if that schema already exists.
-- It does not drop databases/schemas, change roles or modify server settings.

\set ON_ERROR_STOP on

SELECT
    version() AS postgres_version,
    current_database() AS database_name,
    current_user AS database_user;

BEGIN;

SET LOCAL application_name = 'week8_fixture';

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_namespace
        WHERE nspname = 'week8_lab'
    ) THEN
        RAISE EXCEPTION
            'Schema week8_lab already exists. Use a fresh learning database or agree on cleanup with the mentor.';
    END IF;
END;
$$;

CREATE SCHEMA week8_lab;

CREATE TABLE week8_lab.inventory (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku text NOT NULL UNIQUE,
    dealership_id integer NOT NULL,
    quantity integer NOT NULL CHECK (quantity >= 0),
    unit_price numeric(12, 2) NOT NULL CHECK (unit_price >= 0),
    status text NOT NULL CHECK (status IN ('active', 'paused')),
    note text NOT NULL DEFAULT '',
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX inventory_status_idx
    ON week8_lab.inventory (status);

INSERT INTO week8_lab.inventory (
    sku,
    dealership_id,
    quantity,
    unit_price,
    status,
    note
)
SELECT
    'SKU-' || to_char(item_no, 'FM0000'),
    ((item_no - 1) % 20) + 1,
    (item_no * 7) % 31,
    15000 + (item_no * 137 % 70000),
    CASE WHEN item_no % 11 = 0 THEN 'paused' ELSE 'active' END,
    'fixture row ' || item_no
FROM generate_series(1, 200) AS source(item_no);

CREATE TABLE week8_lab.sales_log (
    sale_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sold_at timestamptz NOT NULL,
    dealership_id integer NOT NULL,
    inventory_id bigint NOT NULL REFERENCES week8_lab.inventory(id),
    customer_id bigint NOT NULL,
    amount numeric(12, 2) NOT NULL CHECK (amount >= 0),
    status text NOT NULL CHECK (status IN ('completed', 'refunded')),
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX sales_log_sold_at_idx
    ON week8_lab.sales_log (sold_at);

CREATE INDEX sales_log_dealership_sold_at_idx
    ON week8_lab.sales_log (dealership_id, sold_at DESC);

INSERT INTO week8_lab.sales_log (
    sold_at,
    dealership_id,
    inventory_id,
    customer_id,
    amount,
    status,
    metadata
)
SELECT
    TIMESTAMPTZ '2025-01-01 00:00:00+00'
        + ((sale_no - 1) % 730) * INTERVAL '1 day'
        + ((sale_no * 37) % 86400) * INTERVAL '1 second',
    ((sale_no - 1) % 20) + 1,
    ((sale_no - 1) % 200) + 1,
    ((sale_no * 13) % 5000) + 1,
    17000 + (sale_no * 97 % 80000),
    CASE WHEN sale_no % 29 = 0 THEN 'refunded' ELSE 'completed' END,
    jsonb_build_object('fixture_sale', sale_no)
FROM generate_series(1, 12000) AS source(sale_no);

CREATE TABLE week8_lab.churn_probe (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    stable_key integer NOT NULL,
    changing_value integer NOT NULL,
    payload text NOT NULL,
    updated_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX churn_probe_stable_key_idx
    ON week8_lab.churn_probe (stable_key);

INSERT INTO week8_lab.churn_probe (stable_key, changing_value, payload)
SELECT
    item_no % 100,
    item_no,
    repeat('payload-', 20) || item_no
FROM generate_series(1, 5000) AS source(item_no);

CREATE TABLE week8_lab.wal_probe (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    batch_no integer NOT NULL,
    payload text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE week8_lab.large_notes (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title text NOT NULL,
    description text NOT NULL
);

INSERT INTO week8_lab.large_notes (title, description)
VALUES
    ('small', 'Короткое описание автомобиля.'),
    ('compressible', repeat('AUTO-DEALERSHIP-', 900)),
    ('unicode', repeat('автомобиль-🚗-', 800));

INSERT INTO week8_lab.large_notes (title, description)
SELECT
    'poorly-compressible',
    string_agg(md5(value_no::text || '-week8-seed'), '' ORDER BY value_no)
FROM generate_series(1, 450) AS source(value_no);

CREATE TABLE week8_lab.inventory_audit (
    audit_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    inventory_id bigint NOT NULL,
    old_quantity integer,
    new_quantity integer,
    operation text NOT NULL,
    changed_at timestamptz NOT NULL DEFAULT clock_timestamp(),
    changed_by text NOT NULL
);

ANALYZE week8_lab.inventory;
ANALYZE week8_lab.sales_log;
ANALYZE week8_lab.churn_probe;
ANALYZE week8_lab.large_notes;

SELECT 'inventory' AS relation_name, count(*) AS row_count
FROM week8_lab.inventory
UNION ALL
SELECT 'sales_log', count(*)
FROM week8_lab.sales_log
UNION ALL
SELECT 'churn_probe', count(*)
FROM week8_lab.churn_probe
UNION ALL
SELECT 'wal_probe', count(*)
FROM week8_lab.wal_probe
UNION ALL
SELECT 'large_notes', count(*)
FROM week8_lab.large_notes
UNION ALL
SELECT 'inventory_audit', count(*)
FROM week8_lab.inventory_audit
ORDER BY relation_name;

COMMIT;
