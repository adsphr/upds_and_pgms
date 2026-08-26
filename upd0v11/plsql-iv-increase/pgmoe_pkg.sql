-- =============================================================================
-- pgmoe_pkg.sql
-- PL/SQL port of the Progress program PGMOE (upd0v11/runpgms/PGMOE).
--
-- Purpose: increase IV price-schedule prices by a percentage defined per
-- division/area/district/department in the rule file PGMOE.input, capped at
-- the current list price.
--
-- Prerequisites:
--   * schema.sql has created the tables.
--   * tt_increase has been loaded from PGMOE.input (pgmoe.ctl / load_input.sql)
--     with division/area/district already normalized to 2 chars.
--
-- Entry point: pgmoe_pkg.run.
-- =============================================================================
CREATE OR REPLACE PACKAGE pgmoe_pkg AS
   PROCEDURE run;
END pgmoe_pkg;
/

CREATE OR REPLACE PACKAGE BODY pgmoe_pkg AS

   -- department -> price-list-type-code cross reference (Progress x-ref-dept).
   -- Even entries are dept codes, following entry is the prl_typ_cd prefix.
   TYPE t_xref IS TABLE OF VARCHAR2(4) INDEX BY VARCHAR2(4);
   g_xref t_xref;

   g_pgm_nm CONSTANT VARCHAR2(30) := 'PGMOE';

   -- ------------------------------------------------------------------
   PROCEDURE log(p_msg IN VARCHAR2) IS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      INSERT INTO pgmoe_log (msg)
      VALUES (TO_CHAR(SYSDATE,'YYYY-MM-DD HH24:MI:SS')||' : '||p_msg);
      COMMIT;
   END log;

   -- ------------------------------------------------------------------
   PROCEDURE init_xref IS
   BEGIN
      g_xref('11') := 'AC';
      g_xref('18') := 'IM';
      g_xref('21') := 'CC';
      g_xref('25') := 'AU';
      g_xref('50') := 'AP';
      g_xref('53') := 'SE';
      g_xref('80') := 'BR';
      g_xref('2')  := 'xx';
   END init_xref;

   -- ------------------------------------------------------------------
   -- Dump effective IV/SS schedules (Progress procedure "dumper").
   -- ------------------------------------------------------------------
   PROCEDURE dumper(p_phase IN VARCHAR2) IS
   BEGIN
      INSERT INTO prl_dtl_dump (dump_phase, version, sales_nbr, min_qty, pr1)
      SELECT p_phase, d.version, d.sales_nbr, d.min_qty, d.pr1
      FROM   prl_dtl d
      JOIN   prl_hdr h ON h.version = d.version
      WHERE  (h.version LIKE 'IV%' OR h.version LIKE 'SS%')
      AND    h.exp_dt >= TRUNC(SYSDATE);
      COMMIT;
   END dumper;

   -- ------------------------------------------------------------------
   -- Determine the effective list price for a product/min-qty
   -- (Progress procedure "get-list"). Returns the list price, and the
   -- resolved dept prefix via out param (informational only).
   -- ------------------------------------------------------------------
   FUNCTION get_list(
      p_dsc       IN VARCHAR2,
      p_dept      IN VARCHAR2,
      p_sales_nbr IN VARCHAR2,
      p_min_qty   IN NUMBER
   ) RETURN NUMBER IS
      v_prefix   VARCHAR2(4) := 'xx';
      v_hdr_ver  prl_hdr.version%TYPE;
      v_list_pr  NUMBER := 0;
   BEGIN
      IF g_xref.EXISTS(p_dept) THEN
         v_prefix := g_xref(p_dept);
      ELSE
         v_prefix := 'xx';
      END IF;

      -- last matching prl_hdr for this dept prefix, effective today.
      BEGIN
         SELECT version INTO v_hdr_ver
         FROM (
            SELECT version
            FROM   prl_hdr
            WHERE  prl_typ_cd = v_prefix
            AND    eff_dt <= TRUNC(SYSDATE)
            AND    exp_dt >= TRUNC(SYSDATE)
            ORDER BY ROWID DESC
         ) WHERE ROWNUM = 1;

         SELECT pr1 INTO v_list_pr
         FROM (
            SELECT pr1
            FROM   prl_dtl
            WHERE  version  = v_hdr_ver
            AND    sales_nbr = p_sales_nbr
            AND    min_qty  <= p_min_qty
            ORDER BY ROWID DESC
         ) WHERE ROWNUM = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN v_list_pr := NVL(v_list_pr, 0);
      END;

      IF v_list_pr > 0 THEN
         RETURN v_list_pr;
      END IF;

      -- Fall back to NS schedules.
      BEGIN
         SELECT version INTO v_hdr_ver
         FROM (
            SELECT version
            FROM   prl_hdr
            WHERE  version LIKE 'NS%'
            AND    eff_dt <= TRUNC(SYSDATE)
            AND    exp_dt >= TRUNC(SYSDATE)
            ORDER BY ROWID DESC
         ) WHERE ROWNUM = 1;

         SELECT pr1 INTO v_list_pr
         FROM (
            SELECT pr1
            FROM   prl_dtl
            WHERE  version  = v_hdr_ver
            AND    sales_nbr = p_sales_nbr
            AND    min_qty  <= p_min_qty
            ORDER BY ROWID DESC
         ) WHERE ROWNUM = 1;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN NULL;
      END;

      RETURN NVL(v_list_pr, 0);
   END get_list;

   -- ------------------------------------------------------------------
   -- Main entry point (Progress main block).
   -- ------------------------------------------------------------------
   PROCEDURE run IS
      v_store      store%ROWTYPE;
      v_found      PLS_INTEGER := 0;
      v_cnt        PLS_INTEGER := 0;
      v_has_changes BOOLEAN := FALSE;
      v_dept       VARCHAR2(4);
      v_subdept    VARCHAR2(4);
      v_cat        VARCHAR2(6);
      v_pct        tt_increase.pct%TYPE;
      v_list_pr    NUMBER;
      v_new_pr     NUMBER;
   BEGIN
      init_xref;
      log('Start');

      -- Determine current store from latest pos_parm.
      BEGIN
         SELECT s.* INTO v_store
         FROM store s
         WHERE s.cost_center = (
            SELECT cost_center FROM (
               SELECT cost_center
               FROM   pos_parm
               WHERE  p_eff_dt <= TRUNC(SYSDATE)
               ORDER BY p_eff_dt DESC, ROWID DESC
            ) WHERE ROWNUM = 1
         );
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            log('Could not determine store dist');
            RETURN;
      END;

      log('Store '||v_store.cost_center||' : DAD '||v_store.division||' '||
          v_store.area||' '||v_store.ccn_district||' '||v_store.dist);

      -- Is this store covered by any increase rule?
      SELECT COUNT(*) INTO v_found
      FROM   tt_increase t
      WHERE  t.division = v_store.division
      AND   (t.area     = v_store.area         OR t.area     = '00')
      AND   (t.district = v_store.ccn_district  OR t.district = '00')
      AND    ROWNUM = 1;

      IF v_found = 0 THEN
         log('store NOT in bump dad');
      ELSE
         log('store in bump');

         -- Dump before.
         log('Dump before');
         dumper('BEFORE');

         log('Increase block start');

         -- Iterate effective IV schedules and their detail rows.
         FOR h IN (
            SELECT version
            FROM   prl_hdr
            WHERE  version LIKE 'IV%'
            AND    exp_dt >= TRUNC(SYSDATE)
         ) LOOP
            log('prl_hdr.version '||h.version);

            FOR d IN (
               SELECT ROWID rid, version, sales_nbr, min_qty, pr1
               FROM   prl_dtl
               WHERE  version = h.version
            ) LOOP
               v_dept := NULL;

               -- Look up the product to get dept/subdept/cat from dsc.
               BEGIN
                  SELECT SUBSTR(dsc,1,2), SUBSTR(dsc,3,2), SUBSTR(dsc,5,3)
                  INTO   v_dept, v_subdept, v_cat
                  FROM   prod
                  WHERE  sales_nbr = d.sales_nbr;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     v_dept := NULL;
                     CONTINUE; -- no product -> tt-increase not available -> next
               END;

               -- Find the first matching increase rule for this store + product.
               BEGIN
                  SELECT pct INTO v_pct
                  FROM (
                     SELECT t.pct
                     FROM   tt_increase t, prod p
                     WHERE  p.sales_nbr = d.sales_nbr
                     AND    t.division = v_store.division
                     AND   (t.area     = v_store.area        OR t.area     = '00')
                     AND   (t.district = v_store.ccn_district OR t.district = '00')
                     AND    t.version  = SUBSTR(h.version,1,2)
                     AND    p.dsc LIKE t.dept||t.subdept_cd||t.cat_cd||'%'
                     ORDER BY ROWID
                  ) WHERE ROWNUM = 1;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     CONTINUE; -- not available -> next
               END;

               -- Resolve list price (cap).
               v_list_pr := get_list(NULL, v_dept, d.sales_nbr, d.min_qty);

               v_cnt   := v_cnt + 1;
               v_new_pr := d.pr1 * (1 + v_pct / 100);

               log(v_cnt||' '||d.sales_nbr||' dept:'||v_dept||
                   ' bump:'||v_new_pr||' lp:'||v_list_pr||
                   ' pct:'||v_pct||' b4:'||d.pr1);

               IF (v_new_pr < v_list_pr AND d.pr1 <> v_new_pr)
                  OR (v_new_pr > v_list_pr AND d.pr1 <> v_list_pr) THEN
                  v_has_changes := TRUE;
               END IF;

               -- Apply: use new price if below list (or no list), else cap at list.
               IF v_new_pr < v_list_pr OR v_list_pr = 0 THEN
                  UPDATE prl_dtl SET pr1 = v_new_pr WHERE ROWID = d.rid;
               ELSE
                  UPDATE prl_dtl SET pr1 = v_list_pr WHERE ROWID = d.rid;
               END IF;
            END LOOP;
         END LOOP;

         IF v_has_changes THEN
            -- Progress: run sod/priceSchedules.p(input "IV").
            -- Port or call the equivalent post-processing here if applicable.
            log('priceSchedules(IV) would run here');
         END IF;

         log('bump count : '||v_cnt);
         log('Increase block complete');

         -- Dump after.
         log('Dump after');
         dumper('AFTER');
      END IF;

      -- Audit row (Progress fd-chng).
      INSERT INTO fd_chng (fd_nm, dt, tm, seq_nbr, chng_typ, chng_user, src_fd, cmnt)
      VALUES (g_pgm_nm, TRUNC(SYSDATE),
              (SYSDATE - TRUNC(SYSDATE)) * 86400, 1,
              'PGM', 'CENTRAL', g_pgm_nm, g_pgm_nm);

      COMMIT;

      log('Call notify');
      -- Progress: unix silent notify.sh 142.  Invoke external notify here if needed.

      log('Complete');
   EXCEPTION
      WHEN OTHERS THEN
         log('ERROR: '||SQLERRM);
         ROLLBACK;
         RAISE;
   END run;

END pgmoe_pkg;
/
