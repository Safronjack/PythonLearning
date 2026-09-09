-- Read-only diagnostics and documented expected failures.
-- Unexpected failures must stop the PostgreSQL check session.

-- C01. Expected table/seed row counts


-- C02. Duplicate business keys (expect zero rows)


-- C03. Orphan relations (expect zero rows)


-- C04. Invalid money/quantity/percent/date/status values (expect zero rows)


-- C05. Transaction total reconciliation


-- C06. Inventory/stock movement reconciliation


-- C07. Balance/ledger reconciliation


-- C08. Expected constraint failures
-- Keep failing INSERT/UPDATE statements commented after individual research.


-- C09. Final zero-violation summary
