# plsql-iv-increase

PL/SQL port of the Progress program **PGMOE** (`upd0v11/runpgms/PGMOE`).

## What it does

Increases **IV** price-schedule prices by a percentage defined per
`division / area / district / department` in the rule file `PGMOE.input`,
capping each new price at the current **list price**.

High-level flow (matching the original Progress logic):

1. Load the increase rules from `PGMOE.input` into `tt_increase`, normalizing
   `division`/`area`/`district` to 2 characters (leading zero).
2. Determine the current store from the latest effective `pos_parm` row.
3. If the store matches any rule (`area`/`district` of `00` = wildcard):
   - Dump the effective IV/SS schedules (**BEFORE**) into `prl_dtl_dump`.
   - For every detail row of every effective `IV%` schedule:
     - Resolve the product's `dept/subdept/cat` from `prod.dsc`.
     - Match a rule for this store + product prefix.
     - Compute `new_pr = pr1 * (1 + pct/100)`.
     - Determine the list price via `get_list` (dept prefix schedule, then NS).
     - Apply `new_pr` when below the list price (or no list price), else cap at list.
   - Dump the schedules again (**AFTER**).
4. Write an `fd_chng` audit row and log completion.

The Progress side effects `sod/priceSchedules.p("IV")` and `notify.sh 142`
are left as log markers / hooks to wire up to your environment.

## Files

| File | Purpose |
|------|---------|
| `schema.sql` | Creates all tables (`tt_increase`, `pos_parm`, `store`, `prl_hdr`, `prl_dtl`, `prod`, `fd_chng`, `pgmoe_log`, `prl_dtl_dump`). |
| `PGMOE.input` | The increase rule data file (copied from the original). |
| `pgmoe.ctl` | SQL*Loader control file to load `PGMOE.input` into `tt_increase`. |
| `load_input.sql` | Alternative/notes for loading + code normalization. |
| `pgmoe_pkg.sql` | The `pgmoe_pkg` package (main logic + `get_list` + `dumper`). |
| `run_pgmoe.sql` | Runner: normalizes codes, executes `pgmoe_pkg.run`, shows the log. |

## Usage

```sh
# 1. Create schema
sqlplus user/pwd@db @schema.sql

# 2. Load rule file
sqlldr user/pwd@db control=pgmoe.ctl log=pgmoe_load.log

# 3. Compile package
sqlplus user/pwd@db @pgmoe_pkg.sql

# 4. Run the job
sqlplus user/pwd@db @run_pgmoe.sql
```

## Notes / mapping from Progress

- Progress `pr[1]` -> column `pr1`.
- Progress unknown value `?` -> SQL `NULL`.
- `today` -> `TRUNC(SYSDATE)`.
- `find last ... no-error` -> `ORDER BY ROWID DESC` + `ROWNUM = 1`.
- File-based `output stream log` -> `pgmoe_log` table (autonomous inserts).
- Before/after file dumps -> `prl_dtl_dump` table with a `dump_phase` column.
- The `x-ref-dept` string list -> the `g_xref` associative array in the package.
