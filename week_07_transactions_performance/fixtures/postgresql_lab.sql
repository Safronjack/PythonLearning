-- Teacher-owned PostgreSQL fixture for week 7.
-- Run only in a confirmed disposable learning database.
-- The script intentionally fails if schema week7_lab already exists.
-- It never drops, truncates, or recreates an existing schema.

\set ON_ERROR_STOP on

SELECT current_database() AS confirmed_learning_database,
       current_user AS connected_user,
       version() AS server_version;

CREATE SCHEMA week7_lab;
SET search_path TO week7_lab, public;

CREATE SEQUENCE learning_id_sequence START WITH 1000;

CREATE TABLE dealership (
    id bigint PRIMARY KEY,
    name text NOT NULL UNIQUE,
    country_code text NOT NULL,
    location point NOT NULL,
    balance numeric(14, 2) NOT NULL
        CONSTRAINT dealership_balance_non_negative CHECK (balance >= 0),
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE supplier (
    id bigint PRIMARY KEY,
    name text NOT NULL UNIQUE,
    external_ref text NOT NULL,
    balance numeric(14, 2) NOT NULL
        CONSTRAINT supplier_balance_non_negative CHECK (balance >= 0),
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE customer (
    id bigint PRIMARY KEY,
    email text NOT NULL UNIQUE,
    display_name text NOT NULL,
    balance numeric(14, 2) NOT NULL
        CONSTRAINT customer_balance_non_negative CHECK (balance >= 0),
    email_verified boolean NOT NULL,
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE car_model (
    id bigint PRIMARY KEY,
    make_name text NOT NULL,
    model_name text NOT NULL,
    body_style text NOT NULL,
    tags text[] NOT NULL DEFAULT '{}',
    specs jsonb NOT NULL DEFAULT '{}',
    is_active boolean NOT NULL DEFAULT true,
    CONSTRAINT car_model_business_key UNIQUE (make_name, model_name)
);

CREATE TABLE dealership_inventory (
    dealership_id bigint NOT NULL REFERENCES dealership(id),
    car_model_id bigint NOT NULL REFERENCES car_model(id),
    quantity integer NOT NULL
        CONSTRAINT dealership_inventory_quantity_non_negative CHECK (quantity >= 0),
    sale_price numeric(14, 2) NOT NULL
        CONSTRAINT dealership_inventory_price_positive CHECK (sale_price > 0),
    updated_at timestamptz NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    PRIMARY KEY (dealership_id, car_model_id)
);

CREATE TABLE supplier_catalog_item (
    supplier_id bigint NOT NULL REFERENCES supplier(id),
    car_model_id bigint NOT NULL REFERENCES car_model(id),
    base_price numeric(14, 2) NOT NULL
        CONSTRAINT supplier_catalog_price_positive CHECK (base_price > 0),
    quantity integer NOT NULL
        CONSTRAINT supplier_catalog_quantity_non_negative CHECK (quantity >= 0),
    discount_percent numeric(5, 2) NOT NULL DEFAULT 0
        CONSTRAINT supplier_catalog_discount_range CHECK (
            discount_percent >= 0 AND discount_percent <= 100
        ),
    updated_at timestamptz NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    PRIMARY KEY (supplier_id, car_model_id)
);

CREATE TABLE customer_offer (
    id bigint PRIMARY KEY,
    customer_id bigint NOT NULL REFERENCES customer(id),
    car_model_id bigint NOT NULL REFERENCES car_model(id),
    max_price numeric(14, 2) NOT NULL
        CONSTRAINT customer_offer_max_price_positive CHECK (max_price > 0),
    status text NOT NULL
        CONSTRAINT customer_offer_status_allowed CHECK (
            status IN ('pending', 'processing', 'completed', 'rejected', 'cancelled')
        ),
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE retail_sale (
    id bigint PRIMARY KEY,
    dealership_id bigint NOT NULL REFERENCES dealership(id),
    customer_id bigint NOT NULL REFERENCES customer(id),
    car_model_id bigint NOT NULL REFERENCES car_model(id),
    quantity integer NOT NULL
        CONSTRAINT retail_sale_quantity_positive CHECK (quantity > 0),
    unit_price numeric(14, 2) NOT NULL
        CONSTRAINT retail_sale_unit_price_positive CHECK (unit_price > 0),
    total_amount numeric(14, 2) NOT NULL
        CONSTRAINT retail_sale_total_non_negative CHECK (total_amount >= 0),
    sold_at timestamptz NOT NULL,
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE promotion (
    id bigint PRIMARY KEY,
    dealership_id bigint NOT NULL REFERENCES dealership(id),
    car_model_id bigint NOT NULL REFERENCES car_model(id),
    active_period tstzrange NOT NULL,
    discount_percent numeric(5, 2) NOT NULL
        CONSTRAINT promotion_discount_range CHECK (
            discount_percent > 0 AND discount_percent <= 100
        ),
    is_active boolean NOT NULL DEFAULT true
);

CREATE TABLE work_item (
    id bigint PRIMARY KEY,
    offer_id bigint NOT NULL REFERENCES customer_offer(id),
    status text NOT NULL
        CONSTRAINT work_item_status_allowed CHECK (
            status IN ('pending', 'processing', 'completed', 'failed')
        ),
    priority integer NOT NULL,
    created_at timestamptz NOT NULL,
    claimed_at timestamptz,
    worker_name text
);

-- Two independent rows for demonstrating write skew. The cross-row rule
-- "at least one officer is on duty" cannot be expressed by a row CHECK.
CREATE TABLE approval_officer (
    id bigint PRIMARY KEY,
    name text NOT NULL UNIQUE,
    is_on_duty boolean NOT NULL
);

INSERT INTO dealership (
    id, name, country_code, location, balance, is_active
)
SELECT sequence_number,
       'Dealership ' || lpad(sequence_number::text, 2, '0'),
       CASE sequence_number % 3
           WHEN 0 THEN 'AM'
           WHEN 1 THEN 'GE'
           ELSE 'TR'
       END,
       point(
           (40 + sequence_number::numeric / 10)::double precision,
           (41 + sequence_number::numeric / 20)::double precision
       ),
       1000000.00 + sequence_number * 10000.00,
       sequence_number <> 20
FROM generate_series(1, 20) AS source(sequence_number);

INSERT INTO supplier (
    id, name, external_ref, balance, is_active
)
SELECT sequence_number,
       'Supplier ' || lpad(sequence_number::text, 2, '0'),
       'region-' || (sequence_number % 8)::text,
       2000000.00 + sequence_number * 5000.00,
       sequence_number <> 50
FROM generate_series(1, 50) AS source(sequence_number);

INSERT INTO customer (
    id, email, display_name, balance, email_verified, is_active
)
SELECT sequence_number,
       'buyer' || lpad(sequence_number::text, 5, '0') || '@example.test',
       'Buyer ' || sequence_number,
       100000.00 + (sequence_number % 100) * 1000.00,
       sequence_number % 17 <> 0,
       sequence_number % 101 <> 0
FROM generate_series(1, 10000) AS source(sequence_number);

INSERT INTO car_model (
    id, make_name, model_name, body_style, tags, specs, is_active
)
SELECT sequence_number,
       'Make ' || ((sequence_number - 1) / 20 + 1),
       'Model ' || sequence_number,
       CASE sequence_number % 4
           WHEN 0 THEN 'sedan'
           WHEN 1 THEN 'suv'
           WHEN 2 THEN 'wagon'
           ELSE 'hatchback'
       END,
       ARRAY[
           CASE WHEN sequence_number % 4 = 1 THEN 'suv' ELSE 'passenger' END,
           CASE WHEN sequence_number % 3 = 0 THEN 'hybrid' ELSE 'petrol' END
       ],
       jsonb_build_object(
           'horsepower', 100 + sequence_number % 250,
           'doors', 3 + sequence_number % 3,
           'year', 2022 + sequence_number % 5
       ),
       sequence_number <> 200
FROM generate_series(1, 200) AS source(sequence_number);

INSERT INTO dealership_inventory (
    dealership_id, car_model_id, quantity, sale_price, updated_at, is_active
)
SELECT dealership_number,
       model_number,
       CASE
           WHEN dealership_number = 1 AND model_number = 1 THEN 1
           ELSE (dealership_number + model_number) % 12
       END,
       25000.00 + model_number * 125.00 + dealership_number * 10.00,
       TIMESTAMPTZ '2026-01-01 00:00:00+00'
           + ((dealership_number * model_number) % 90) * INTERVAL '1 day',
       NOT (dealership_number = 20 OR model_number = 100)
FROM generate_series(1, 20) AS dealerships(dealership_number)
CROSS JOIN generate_series(1, 100) AS models(model_number);

INSERT INTO supplier_catalog_item (
    supplier_id, car_model_id, base_price, quantity,
    discount_percent, updated_at, is_active
)
SELECT supplier_number,
       model_number,
       19000.00 + model_number * 110.00 + supplier_number * 5.00,
       (supplier_number * model_number) % 30,
       (supplier_number + model_number) % 12,
       TIMESTAMPTZ '2026-01-01 00:00:00+00'
           + ((supplier_number + model_number) % 120) * INTERVAL '1 day',
       supplier_number <> 50
FROM generate_series(1, 50) AS suppliers(supplier_number)
CROSS JOIN generate_series(1, 200) AS models(model_number)
WHERE (supplier_number + model_number) % 4 = 0;

INSERT INTO customer_offer (
    id, customer_id, car_model_id, max_price, status,
    created_at, updated_at, is_active
)
SELECT sequence_number,
       ((sequence_number - 1) % 10000) + 1,
       ((sequence_number - 1) % 200) + 1,
       27000.00 + (sequence_number % 200) * 150.00,
       CASE
           WHEN sequence_number % 20 = 0 THEN 'pending'
           WHEN sequence_number % 20 IN (1, 2) THEN 'processing'
           WHEN sequence_number % 20 IN (3, 4, 5) THEN 'rejected'
           WHEN sequence_number % 20 IN (6, 7) THEN 'cancelled'
           ELSE 'completed'
       END,
       TIMESTAMPTZ '2025-01-01 00:00:00+00'
           + sequence_number * INTERVAL '10 minutes',
       TIMESTAMPTZ '2025-01-01 00:00:00+00'
           + sequence_number * INTERVAL '10 minutes',
       sequence_number % 97 <> 0
FROM generate_series(1, 30000) AS source(sequence_number);

INSERT INTO retail_sale (
    id, dealership_id, customer_id, car_model_id, quantity,
    unit_price, total_amount, sold_at, is_active
)
SELECT sequence_number,
       ((sequence_number - 1) % 20) + 1,
       ((sequence_number * 7 - 1) % 10000) + 1,
       ((sequence_number * 11 - 1) % 200) + 1,
       1,
       25000.00 + ((sequence_number * 11 - 1) % 200 + 1) * 125.00,
       25000.00 + ((sequence_number * 11 - 1) % 200 + 1) * 125.00,
       TIMESTAMPTZ '2024-01-01 00:00:00+00'
           + sequence_number * INTERVAL '1 minute',
       true
FROM generate_series(1, 100000) AS source(sequence_number);

INSERT INTO promotion (
    id, dealership_id, car_model_id, active_period,
    discount_percent, is_active
)
SELECT sequence_number,
       ((sequence_number - 1) % 20) + 1,
       ((sequence_number * 3 - 1) % 200) + 1,
       tstzrange(
           TIMESTAMPTZ '2026-01-01 00:00:00+00'
               + (sequence_number % 180) * INTERVAL '1 day',
           TIMESTAMPTZ '2026-01-01 00:00:00+00'
               + (sequence_number % 180 + 14) * INTERVAL '1 day',
           '[)'
       ),
       5 + sequence_number % 20,
       sequence_number % 23 <> 0
FROM generate_series(1, 500) AS source(sequence_number);

INSERT INTO work_item (
    id, offer_id, status, priority, created_at, claimed_at, worker_name
)
SELECT sequence_number,
       sequence_number,
       CASE WHEN sequence_number % 8 = 0 THEN 'completed' ELSE 'pending' END,
       sequence_number % 10,
       TIMESTAMPTZ '2026-01-01 00:00:00+00'
           + sequence_number * INTERVAL '1 minute',
       NULL,
       NULL
FROM generate_series(1, 1000) AS source(sequence_number);

INSERT INTO approval_officer (id, name, is_on_duty) VALUES
    (1, 'Officer A', true),
    (2, 'Officer B', true);

ANALYZE week7_lab.dealership,
        week7_lab.supplier,
        week7_lab.customer,
        week7_lab.car_model,
        week7_lab.dealership_inventory,
        week7_lab.supplier_catalog_item,
        week7_lab.customer_offer,
        week7_lab.retail_sale,
        week7_lab.promotion,
        week7_lab.work_item,
        week7_lab.approval_officer;

SELECT 'dealership' AS table_name, count(*) AS row_count FROM dealership
UNION ALL
SELECT 'supplier', count(*) FROM supplier
UNION ALL
SELECT 'customer', count(*) FROM customer
UNION ALL
SELECT 'car_model', count(*) FROM car_model
UNION ALL
SELECT 'dealership_inventory', count(*) FROM dealership_inventory
UNION ALL
SELECT 'supplier_catalog_item', count(*) FROM supplier_catalog_item
UNION ALL
SELECT 'customer_offer', count(*) FROM customer_offer
UNION ALL
SELECT 'retail_sale', count(*) FROM retail_sale
UNION ALL
SELECT 'promotion', count(*) FROM promotion
UNION ALL
SELECT 'work_item', count(*) FROM work_item
UNION ALL
SELECT 'approval_officer', count(*) FROM approval_officer
ORDER BY table_name;
