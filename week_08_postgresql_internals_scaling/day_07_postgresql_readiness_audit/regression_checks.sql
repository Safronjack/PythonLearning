-- Final audit: 30 safe scenarios from PRACTICE.md.
-- Every mutating check must use rollback or explicit fixture cleanup.

-- 01-06. Environment, row counts, transaction baseline, table stats


-- 07-12. Sizes, maintenance, autovacuum and freeze ages


-- 13-18. WAL/recovery/backup decisions


-- 19-20. TOAST inventory and narrow projections


-- 21-24. Routine and trigger contracts


-- 25-27. Partition routing, pruning and uniqueness


-- 28-29. Read routing, sharding and PostGIS decisions


-- 30. Re-run accepted business invariants from weeks 6-7


-- Final reconciliation: no changed business state and no open transaction
