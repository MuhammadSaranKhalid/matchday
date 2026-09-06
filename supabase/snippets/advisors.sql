-- =============================================================================
-- Local Supabase advisor checks
-- =============================================================================
-- Reimplements the Supabase Advisor lints (supabase/splinter) as plain SQL so
-- they can be run against the LOCAL database, without a linked project.
--
--   docker exec -i supabase_db_crick psql -U postgres -f - < supabase/snippets/advisors.sql
--
-- Run it after `supabase db reset` whenever migrations change. Every row
-- returned is a finding; the expected steady state is documented per check.
--
-- Note `supabase db lint` is a DIFFERENT tool (plpgsql-check: unused variables,
-- dynamic-SQL warnings). It is mostly PostGIS noise here and does not cover any
-- of the rules below.
-- =============================================================================
\pset pager off

\echo '── 0013_rls_disabled_in_public ── expected: spatial_ref_sys only (PostGIS-owned, cannot ALTER)'
select c.relname
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity
 order by 1;

\echo ''
\echo '── 0008_rls_enabled_no_policy ── expected: none (RLS on with no policy blocks all API access)'
select c.relname
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
   and not exists (select 1 from pg_policy p where p.polrelid = c.oid)
 order by 1;

\echo ''
\echo '── 0003_auth_rls_initplan ── expected: none. Use (select auth.uid()), not auth.uid():'
\echo '   the subquery is evaluated once per statement (InitPlan) instead of once per row.'
select tablename || ' :: ' || policyname
  from pg_policies
 where schemaname = 'public'
   and ( (coalesce(qual,'')       ~ 'auth\.(uid|jwt|role)\(\)'
          and coalesce(qual,'')       !~ '\(\s*SELECT\s+auth\.')
      or (coalesce(with_check,'') ~ 'auth\.(uid|jwt|role)\(\)'
          and coalesce(with_check,'') !~ '\(\s*SELECT\s+auth\.') )
 order by 1;

\echo ''
\echo '── 0011_function_search_path_mutable ── expected: none.'
\echo '   SECURITY DEFINER + unpinned search_path = privilege escalation.'
select p.proname
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.prokind in ('f','p')
   and not exists (select 1 from unnest(coalesce(p.proconfig,'{}')) c where c like 'search_path=%')
   and not exists (select 1 from pg_depend d join pg_extension e on e.oid = d.refobjid
                    where d.objid = p.oid and d.classid = 'pg_proc'::regclass and d.deptype = 'e')
 order by 1;

\echo ''
\echo '── 0010_security_definer_view ── expected: none of ours.'
\echo '   A view defaults to its owner''s privileges and reads past the RLS of its base table.'
select c.relname
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public' and c.relkind = 'v'
   and c.relname in ('balls','format_presets')
   and coalesce(array_to_string(c.reloptions,','),'') not like '%security_invoker=%'
 order by 1;

\echo ''
\echo '── 0028/0029_security_definer_function_executable ── expected: get_follow_list only'
\echo '   (deliberate: follower lists on a public /u/<username> profile).'
select p.proname
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.prosecdef
   and has_function_privilege('anon', p.oid, 'execute')
   and not exists (select 1 from pg_depend d join pg_extension e on e.oid = d.refobjid
                    where d.objid = p.oid and d.classid = 'pg_proc'::regclass and d.deptype = 'e')
 order by 1;

\echo ''
\echo '── 0001_unindexed_foreign_keys ── expected: none.'
\echo '   Postgres does not index the referencing side; every parent delete seq-scans the child.'
select c.relname || '.' || a.attname
  from pg_constraint con
  join pg_class c      on c.oid = con.conrelid
  join pg_namespace n  on n.oid = c.relnamespace
  join pg_attribute a  on a.attrelid = con.conrelid and a.attnum = con.conkey[1]
 where con.contype = 'f' and n.nspname = 'public' and array_length(con.conkey,1) = 1
   and not exists (select 1 from pg_index i
                    where i.indrelid = con.conrelid and i.indkey[0] = con.conkey[1])
 order by 1;

\echo ''
\echo '── 0006_multiple_permissive_policies ── expected: none (all are OR-ed and tested per row)'
select tablename || '  cmd=' || cmd || '  n=' || count(*)::text
       || '  [' || string_agg(policyname, ', ') || ']'
  from pg_policies
 where schemaname = 'public' and permissive = 'PERMISSIVE'
 group by tablename, cmd, roles::text
having count(*) > 1
 order by 1;

\echo ''
\echo '── 0009_duplicate_index ── expected: none (access-method aware; btree vs gin is not a dup)'
select c.relname || ' :: ' || string_agg(ic.relname, ' == ' order by ic.relname)
  from pg_index i
  join pg_class c     on c.oid = i.indrelid
  join pg_class ic    on ic.oid = i.indexrelid
  join pg_am am       on am.oid = ic.relam
  join pg_namespace n on n.oid = c.relnamespace
 where n.nspname = 'public'
 group by c.relname, array_to_string(i.indkey,' '), am.amname,
          coalesce(pg_get_expr(i.indpred, i.indrelid),'')
having count(*) > 1;

\echo ''
\echo '── UPDATE/ALL policies with no WITH CHECK ── expected: none.'
\echo '   USING picks the rows you may target; WITH CHECK constrains what you may turn them into.'
select tablename || ' :: ' || policyname || '  cmd=' || cmd
  from pg_policies
 where schemaname = 'public' and cmd in ('UPDATE','ALL')
   and with_check is null and coalesce(qual,'') <> 'false'
 order by 1;

\echo ''
\echo '── policies with no TO clause ── expected: none.'
\echo '   Without TO, the policy is evaluated for every role including anon.'
select tablename || ' :: ' || policyname
  from pg_policies
 where schemaname = 'public' and roles::text = '{public}'
 order by 1;
