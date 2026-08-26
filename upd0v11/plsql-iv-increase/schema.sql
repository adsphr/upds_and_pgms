-- =============================================================================
-- schema.sql
-- Oracle schema for the PL/SQL port of the Progress PGMOE IV price-increase job.
--
-- These tables mirror the Progress database tables referenced by PGMOE:
--   pos-parm, store, prl-hdr, prl-dtl, prod, fd-chng
-- plus a staging table for the space-delimited PGMOE.input rule file.
--
-- Column names use underscores in place of Progress hyphens. Only the columns
-- actually used by the job are modelled; add others as needed for your site.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Staging table for the increase rules (loaded from PGMOE.input).
-- Progress temp-table tt-increase.
-- ---------------------------------------------------------------------------
CREATE TABLE tt_increase (
   version      VARCHAR2(10),
   field2       VARCHAR2(10),
   division     VARCHAR2(4),
   area         VARCHAR2(4),
   district     VARCHAR2(4),
   sales_nbr    VARCHAR2(30),
   dept         VARCHAR2(4),
   subdept_cd   VARCHAR2(4),
   cat_cd       VARCHAR2(6),
   field10      VARCHAR2(10),
   pct          NUMBER(5)
);

-- ---------------------------------------------------------------------------
-- POS parameter table (drives which store/cost-center is current).
-- ---------------------------------------------------------------------------
CREATE TABLE pos_parm (
   p_eff_dt     DATE,
   cost_center  VARCHAR2(20)
);

-- ---------------------------------------------------------------------------
-- Store table.
-- ---------------------------------------------------------------------------
CREATE TABLE store (
   cost_center   VARCHAR2(20),
   division      VARCHAR2(4),
   area          VARCHAR2(4),
   ccn_district  VARCHAR2(4),
   dist          VARCHAR2(20)
);

-- ---------------------------------------------------------------------------
-- Price list header. Progress prl-hdr.
-- ---------------------------------------------------------------------------
CREATE TABLE prl_hdr (
   version     VARCHAR2(20),
   prl_typ_cd  VARCHAR2(10),
   eff_dt      DATE,
   exp_dt      DATE
);

-- ---------------------------------------------------------------------------
-- Price list detail. Progress prl-dtl. pr[1] is modelled as pr1.
-- ---------------------------------------------------------------------------
CREATE TABLE prl_dtl (
   version    VARCHAR2(20),
   sales_nbr  VARCHAR2(30),
   min_qty    NUMBER,
   pr1        NUMBER(15,4)
);

-- ---------------------------------------------------------------------------
-- Product master. Progress prod. dsc holds dept(2)+subdept(2)+cat(3).
-- ---------------------------------------------------------------------------
CREATE TABLE prod (
   sales_nbr  VARCHAR2(30),
   dsc        VARCHAR2(40)
);

-- ---------------------------------------------------------------------------
-- Field-change audit table. Progress fd-chng.
-- ---------------------------------------------------------------------------
CREATE TABLE fd_chng (
   fd_nm      VARCHAR2(30),
   dt         DATE,
   tm         NUMBER,
   seq_nbr    NUMBER,
   chng_typ   VARCHAR2(10),
   chng_user  VARCHAR2(30),
   src_fd     VARCHAR2(30),
   cmnt       VARCHAR2(200)
);

-- ---------------------------------------------------------------------------
-- Run log. Replaces the Progress "output stream log to log/PGMOE.lg".
-- ---------------------------------------------------------------------------
CREATE TABLE pgmoe_log (
   log_ts   TIMESTAMP DEFAULT SYSTIMESTAMP,
   msg      VARCHAR2(4000)
);

-- ---------------------------------------------------------------------------
-- Before/after dump of effective IV/SS schedules. Replaces the file dumps
-- /usr/preserve/prl-dtl.before.PGMOE and .after.PGMOE.
-- ---------------------------------------------------------------------------
CREATE TABLE prl_dtl_dump (
   dump_phase  VARCHAR2(10),   -- 'BEFORE' or 'AFTER'
   dump_ts     TIMESTAMP DEFAULT SYSTIMESTAMP,
   version     VARCHAR2(20),
   sales_nbr   VARCHAR2(30),
   min_qty     NUMBER,
   pr1         NUMBER(15,4)
);
