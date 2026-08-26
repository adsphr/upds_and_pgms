-- =============================================================================
-- pgmoe.ctl  -  SQL*Loader control file for PGMOE.input
--
-- Usage:
--   sqlldr <user>/<pwd>@<db> control=pgmoe.ctl log=pgmoe_load.log
--
-- Parses the whitespace-delimited rule file. Optionally-enclosed by double
-- quotes so quoted empty strings ("") and quoted values ("11") load cleanly.
-- The Progress unknown value "?" is converted to NULL via NULLIF.
-- The leading-zero normalization for division/area/district is applied inline.
-- =============================================================================
LOAD DATA
INFILE 'PGMOE.input'
TRUNCATE
INTO TABLE tt_increase
FIELDS TERMINATED BY WHITESPACE OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
   version    "NULLIF :version = '?'",
   field2     "NULLIF :field2 = '?'",
   division   "LPAD(NULLIF(:division,'?'), 2, '0')",
   area       "LPAD(NULLIF(:area,'?'), 2, '0')",
   district   "LPAD(NULLIF(:district,'?'), 2, '0')",
   sales_nbr  "NULLIF :sales_nbr = '?'",
   dept       "NULLIF :dept = '?'",
   subdept_cd,
   cat_cd,
   field10,
   pct        "TO_NUMBER(NULLIF(:pct,'?'))"
)
