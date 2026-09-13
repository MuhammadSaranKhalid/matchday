-- Metadata only. Intended for a disposable database replayed from this checkout.
with relations as (
 select c.oid, n.nspname schema, c.relname name, c.relkind kind,
   c.relrowsecurity rls, c.relforcerowsecurity force_rls, c.reloptions options,
   obj_description(c.oid, 'pg_class') description
 from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind in ('r','p','v','m')
 and not exists (select 1 from pg_depend d where d.classid='pg_class'::regclass and d.objid=c.oid and d.deptype='e')
), functions as (
 select p.*, n.nspname schema, l.lanname language
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace join pg_language l on l.oid=p.prolang
 where n.nspname='public' and p.prokind='f'
 and not exists (select 1 from pg_depend d where d.classid='pg_proc'::regclass and d.objid=p.oid and d.deptype='e')
)
select jsonb_build_object(
 'postgres_version', current_setting('server_version'),
 'relations', (select jsonb_agg(jsonb_build_object(
  'schema',r.schema,'name',r.name,'kind',r.kind,'rls',r.rls,'force_rls',r.force_rls,'options',r.options,'description',r.description,
  'view_sql',case when r.kind in ('v','m') then pg_get_viewdef(r.oid,true) end,
  'columns',(select jsonb_agg(jsonb_build_object('name',a.attname,'type',format_type(a.atttypid,a.atttypmod),
    'nullable',not a.attnotnull,'default',pg_get_expr(ad.adbin,ad.adrelid),'generated',a.attgenerated,'identity',a.attidentity,
    'description',col_description(r.oid,a.attnum)) order by a.attnum)
    from pg_attribute a left join pg_attrdef ad on ad.adrelid=a.attrelid and ad.adnum=a.attnum
    where a.attrelid=r.oid and a.attnum>0 and not a.attisdropped),
  'constraints',(select coalesce(jsonb_agg(jsonb_build_object('name',c.conname,'type',c.contype,
    'definition',pg_get_constraintdef(c.oid,true),'deferrable',c.condeferrable,'initially_deferred',c.condeferred,
    'columns',(select jsonb_agg(a.attname order by k.ord) from unnest(c.conkey) with ordinality k(num,ord) join pg_attribute a on a.attrelid=c.conrelid and a.attnum=k.num),
    'foreign_table',case when c.contype='f' then c.confrelid::regclass::text end,
    'foreign_columns',(select jsonb_agg(a.attname order by k.ord) from unnest(c.confkey) with ordinality k(num,ord) join pg_attribute a on a.attrelid=c.confrelid and a.attnum=k.num)) order by c.conname),'[]'::jsonb)
    from pg_constraint c where c.conrelid=r.oid),
  'indexes',(select coalesce(jsonb_agg(jsonb_build_object('name',ic.relname,'definition',pg_get_indexdef(i.indexrelid),'unique',i.indisunique,'primary',i.indisprimary) order by ic.relname),'[]'::jsonb)
    from pg_index i join pg_class ic on ic.oid=i.indexrelid where i.indrelid=r.oid),
  'triggers',(select coalesce(jsonb_agg(jsonb_build_object('name',t.tgname,'definition',pg_get_triggerdef(t.oid,true),'function',t.tgfoid::regprocedure::text) order by t.tgname),'[]'::jsonb)
    from pg_trigger t where t.tgrelid=r.oid and not t.tgisinternal),
  'policies',(select coalesce(jsonb_agg(to_jsonb(p) - 'schemaname' - 'tablename' order by p.policyname),'[]'::jsonb) from pg_policies p where p.schemaname=r.schema and p.tablename=r.name),
  'grants',(select coalesce(jsonb_agg(jsonb_build_object('role',role,'select',has_table_privilege(role,r.oid,'select'),
    'insert',has_table_privilege(role,r.oid,'insert'),'update',has_table_privilege(role,r.oid,'update'),
    'delete',has_table_privilege(role,r.oid,'delete'),'truncate',has_table_privilege(role,r.oid,'truncate'),'references',has_table_privilege(role,r.oid,'references'),'trigger',has_table_privilege(role,r.oid,'trigger'))),'[]'::jsonb)
    from unnest(array['anon','authenticated','service_role']) role),
  'column_grants',(select coalesce(jsonb_agg(jsonb_build_object('role',cp.grantee,'column',cp.column_name,'privilege',cp.privilege_type) order by cp.grantee,cp.column_name,cp.privilege_type),'[]'::jsonb)
    from information_schema.column_privileges cp where cp.table_schema=r.schema and cp.table_name=r.name and cp.grantee in ('anon','authenticated','service_role'))
 ) order by r.name) from relations r),
 'functions',(select jsonb_agg(jsonb_build_object('name',p.proname,'identity',pg_get_function_identity_arguments(p.oid),
   'arguments',pg_get_function_arguments(p.oid),'returns',pg_get_function_result(p.oid),'language',p.language,
   'security_definer',p.prosecdef,'volatility',p.provolatile,'config',p.proconfig,
   'description',obj_description(p.oid,'pg_proc'),'definition',pg_get_functiondef(p.oid),
   'execute',(select jsonb_object_agg(role,has_function_privilege(role,p.oid,'execute')) from unnest(array['anon','authenticated','service_role']) role))
   order by p.proname,pg_get_function_identity_arguments(p.oid)) from functions p),
 'enums',(select jsonb_agg(x order by x->>'name') from (select jsonb_build_object('name',t.typname,'values',jsonb_agg(e.enumlabel order by e.enumsortorder)) x
   from pg_type t join pg_namespace n on n.oid=t.typnamespace join pg_enum e on e.enumtypid=t.oid
   where n.nspname='public' group by t.typname) enums),
 'extensions',(select jsonb_agg(jsonb_build_object('name',e.extname,'version',e.extversion,'schema',n.nspname) order by e.extname) from pg_extension e join pg_namespace n on n.oid=e.extnamespace),
 'realtime_policies',(select jsonb_agg(to_jsonb(p) order by p.policyname) from pg_policies p where p.schemaname='realtime'),
 'storage_policies',(select jsonb_agg(to_jsonb(p) order by p.policyname) from pg_policies p where p.schemaname='storage'),
 'buckets',(select jsonb_agg(jsonb_build_object('id',id,'public',public,'file_size_limit',file_size_limit,'allowed_mime_types',allowed_mime_types) order by id) from storage.buckets),
 'cron',(select jsonb_agg(jsonb_build_object('name',jobname,'schedule',schedule,'command',command,'active',active) order by jobname) from cron.job),
 'publications',(select jsonb_agg(to_jsonb(p) order by pubname,schemaname,tablename) from pg_publication_tables p where schemaname='public'),
 'catalogues',jsonb_build_object(
   'roles',(select jsonb_agg(to_jsonb(t) order by scope,key) from public.roles t),
   'permissions',(select jsonb_agg(to_jsonb(t) order by permission_key) from public.permissions t),
   'permission_scopes',(select jsonb_agg(to_jsonb(t) order by permission_key,scope) from public.permission_scopes t),
   'notification_types',(select jsonb_agg(to_jsonb(t)-'created_at' order by key) from public.notification_types t),
   'notification_categories',(select jsonb_agg(to_jsonb(t) order by sort_order) from public.notification_categories t),
   'notification_icons',(select jsonb_agg(to_jsonb(t) order by key) from public.notification_icons t)
 )
);
