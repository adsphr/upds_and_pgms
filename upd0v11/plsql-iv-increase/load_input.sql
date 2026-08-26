-- =============================================================================
-- load_input.sql
-- Loads the space-delimited PGMOE.input rule file into tt_increase.
--
-- The Progress "import" reads whitespace-delimited tokens where quoted strings
-- may contain spaces and the unknown value "?" maps to NULL. The equivalent
-- Oracle load uses an external table (or SQL*Loader). Below is a SQL*Loader
-- control file plus a truncate; alternatively use the external table further down.
--
-- Field order in PGMOE.input:
--   version field2 division area district sales_nbr dept subdept_cd cat_cd field10 pct
-- Example row:  "IV" ? 8 1 3 ? "11" "" "" "" 6
-- =============================================================================

-- Clear staging table before each load (Progress recreates the temp-table).
TRUNCATE TABLE tt_increase;

-- After loading, normalize division/area/district to 2 chars with a leading
-- zero, exactly as the Progress code does after import.
-- (Run this UPDATE after the SQL*Loader step below completes.)

/*
UPDATE tt_increase SET
   division = CASE WHEN LENGTH(division) = 1 THEN '0' || division ELSE division END,
   area     = CASE WHEN LENGTH(area)     = 1 THEN '0' || area     ELSE area     END,
   district = CASE WHEN LENGTH(district) = 1 THEN '0' || district ELSE district END;
COMMIT;
*/
