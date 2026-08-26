-- =============================================================================
-- run_pgmoe.sql
-- Convenience runner for the PGMOE IV price-increase job.
-- Assumes tt_increase has already been loaded from PGMOE.input.
-- =============================================================================
SET SERVEROUTPUT ON

-- Normalize codes in case the load did not (safe to re-run; idempotent).
UPDATE tt_increase SET
   division = CASE WHEN LENGTH(division) = 1 THEN '0'||division ELSE division END,
   area     = CASE WHEN LENGTH(area)     = 1 THEN '0'||area     ELSE area     END,
   district = CASE WHEN LENGTH(district) = 1 THEN '0'||district ELSE district END
WHERE LENGTH(division) = 1 OR LENGTH(area) = 1 OR LENGTH(district) = 1;
COMMIT;

BEGIN
   pgmoe_pkg.run;
END;
/

-- Review the run log.
SELECT log_ts, msg FROM pgmoe_log ORDER BY log_ts;
