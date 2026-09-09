-- Instructor-owned fixture for days 1-5.
-- It uses a portable SQLite subset so SQL can be executed without a server.
-- Money is integer cents in this fixture only. The final PostgreSQL prototype
-- uses numeric(14, 2). Dates are ISO text because this is SQLite.

PRAGMA foreign_keys = ON;

CREATE TABLE car_make (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    country_code TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

CREATE TABLE car_model (
    id INTEGER PRIMARY KEY,
    make_id INTEGER NOT NULL REFERENCES car_make(id),
    name TEXT NOT NULL,
    body_style TEXT NOT NULL,
    production_year INTEGER NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE (make_id, name, production_year)
);

CREATE TABLE dealership (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    country_code TEXT NOT NULL,
    balance_cents INTEGER NOT NULL CHECK (balance_cents >= 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    UNIQUE (name, country_code)
);

CREATE TABLE supplier (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    country_code TEXT NOT NULL,
    founded_year INTEGER,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

CREATE TABLE customer (
    id INTEGER PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    balance_cents INTEGER NOT NULL CHECK (balance_cents >= 0),
    email_verified INTEGER NOT NULL DEFAULT 0 CHECK (email_verified IN (0, 1)),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

CREATE TABLE dealership_inventory (
    dealership_id INTEGER NOT NULL REFERENCES dealership(id),
    car_model_id INTEGER NOT NULL REFERENCES car_model(id),
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    sale_price_cents INTEGER NOT NULL CHECK (sale_price_cents > 0),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    PRIMARY KEY (dealership_id, car_model_id)
);

CREATE TABLE supplier_catalog_item (
    supplier_id INTEGER NOT NULL REFERENCES supplier(id),
    car_model_id INTEGER NOT NULL REFERENCES car_model(id),
    base_price_cents INTEGER NOT NULL CHECK (base_price_cents > 0),
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    discount_percent INTEGER NOT NULL DEFAULT 0
        CHECK (discount_percent BETWEEN 0 AND 100),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    PRIMARY KEY (supplier_id, car_model_id)
);

CREATE TABLE customer_offer (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customer(id),
    car_model_id INTEGER NOT NULL REFERENCES car_model(id),
    max_price_cents INTEGER NOT NULL CHECK (max_price_cents > 0),
    status TEXT NOT NULL CHECK (
        status IN ('pending', 'processing', 'completed', 'rejected', 'cancelled')
    ),
    created_at TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

CREATE TABLE retail_sale (
    id INTEGER PRIMARY KEY,
    dealership_id INTEGER NOT NULL REFERENCES dealership(id),
    customer_id INTEGER NOT NULL REFERENCES customer(id),
    car_model_id INTEGER NOT NULL REFERENCES car_model(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents > 0),
    discount_cents INTEGER NOT NULL DEFAULT 0 CHECK (discount_cents >= 0),
    total_cents INTEGER NOT NULL CHECK (total_cents >= 0),
    sold_at TEXT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
);

INSERT INTO car_make (id, name, country_code) VALUES
    (1, 'Toyota', 'JP'),
    (2, 'Volvo', 'SE'),
    (3, 'BMW', 'DE'),
    (4, 'Lada', 'RU');

INSERT INTO car_model (
    id, make_id, name, body_style, production_year, is_active
) VALUES
    (1, 1, 'Camry', 'sedan', 2024, 1),
    (2, 1, 'RAV4', 'suv', 2025, 1),
    (3, 2, 'XC60', 'suv', 2024, 1),
    (4, 3, '320i', 'sedan', 2025, 1),
    (5, 3, 'X5', 'suv', 2025, 1),
    (6, 4, 'Vesta', 'sedan', 2022, 0);

INSERT INTO dealership (
    id, name, country_code, balance_cents, is_active
) VALUES
    (1, 'Tbilisi Motors', 'GE', 25000000, 1),
    (2, 'Batumi Auto', 'GE', 9000000, 1),
    (3, 'Yerevan Cars', 'AM', 15000000, 1),
    (4, 'Kutaisi Garage', 'GE', 1000000, 0),
    (5, 'Rustavi New Auto', 'GE', 5000000, 1);

INSERT INTO supplier (
    id, name, country_code, founded_year, is_active
) VALUES
    (1, 'East Cars Supply', 'GE', 2012, 1),
    (2, 'Nordic Vehicles', 'SE', 2005, 1),
    (3, 'Global Motors', 'DE', 1998, 1),
    (4, 'Old Parts Limited', 'GB', NULL, 0);

INSERT INTO customer (
    id, email, display_name, balance_cents, email_verified, is_active
) VALUES
    (1, 'anna@example.test', 'Anna', 8000000, 1, 1),
    (2, 'boris@example.test', 'Boris', 3500000, 1, 1),
    (3, 'chen@example.test', 'Chen', 12000000, 0, 1),
    (4, 'daria@example.test', 'Daria', 2800000, 1, 1),
    (5, 'inactive@example.test', 'Inactive', 9000000, 1, 0);

INSERT INTO dealership_inventory (
    dealership_id, car_model_id, quantity, sale_price_cents, is_active
) VALUES
    (1, 1, 3, 3100000, 1),
    (1, 2, 0, 3800000, 1),
    (1, 3, 2, 5200000, 1),
    (2, 1, 1, 3050000, 1),
    (2, 4, 2, 4700000, 1),
    (3, 2, 4, 3650000, 1),
    (3, 3, 1, 5100000, 0),
    (4, 1, 9, 2500000, 1);

INSERT INTO supplier_catalog_item (
    supplier_id, car_model_id, base_price_cents, quantity,
    discount_percent, is_active
) VALUES
    (1, 1, 2500000, 8, 0, 1),
    (2, 1, 2450000, 5, 0, 1),
    (3, 1, 2500000, 9, 2, 1),
    (1, 2, 3000000, 4, 5, 1),
    (3, 2, 2925000, 7, 0, 1),
    (2, 3, 4100000, 3, 0, 1),
    (3, 3, 4200000, 10, 5, 1),
    (3, 4, 3800000, 6, 0, 1),
    (4, 5, 5000000, 1, 25, 0);

INSERT INTO customer_offer (
    id, customer_id, car_model_id, max_price_cents, status, created_at
) VALUES
    (1, 1, 1, 3150000, 'pending', '2026-09-01T09:00:00Z'),
    (2, 2, 2, 3500000, 'rejected', '2026-09-02T10:00:00Z'),
    (3, 3, 3, 5300000, 'pending', '2026-09-03T11:00:00Z'),
    (4, 4, 1, 3000000, 'completed', '2026-09-04T12:00:00Z');

INSERT INTO retail_sale (
    id, dealership_id, customer_id, car_model_id, quantity,
    unit_price_cents, discount_cents, total_cents, sold_at
) VALUES
    (1, 1, 1, 1, 1, 3100000, 100000, 3000000, '2026-08-01T10:00:00Z'),
    (2, 1, 2, 3, 1, 5200000, 200000, 5000000, '2026-08-03T11:00:00Z'),
    (3, 2, 1, 1, 1, 3050000, 0, 3050000, '2026-08-05T12:00:00Z'),
    (4, 1, 1, 2, 1, 3800000, 300000, 3500000, '2026-08-08T13:00:00Z'),
    (5, 3, 4, 2, 1, 3650000, 0, 3650000, '2026-08-09T14:00:00Z'),
    (6, 2, 2, 4, 1, 4700000, 500000, 4200000, '2026-08-12T15:00:00Z'),
    (7, 1, 4, 1, 1, 3100000, 0, 3100000, '2026-09-01T09:30:00Z'),
    (8, 3, 1, 3, 1, 5100000, 100000, 5000000, '2026-09-03T16:00:00Z'),
    (9, 1, 2, 1, 2, 3100000, 200000, 6000000, '2026-09-05T17:00:00Z'),
    (10, 2, 1, 1, 1, 3050000, 50000, 3000000, '2026-09-06T18:00:00Z');
