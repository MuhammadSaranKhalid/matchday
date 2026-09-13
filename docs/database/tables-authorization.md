# Authorization catalogue: table reference

> Generated from a disposable migration replay on 2026-09-13. PostgreSQL 17.6. This describes source, not hosted deployment. Regenerate with `scripts/database/generate_docs.py`.


[Handbook](README.md) · [Architecture](architecture.md) · [Relationship diagrams](relationships.md)

## roles

Role definitions, display rank, singleton behavior and account requirements.

Canonical declaration: [20260101000201_roles.sql](../../supabase/migrations/20260101000201_roles.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| scope | text | False | 'team'::text |
| key | text | False | — |
| name | text | False | — |
| rank | integer | False | — |
| is_system | boolean | False | false |
| is_singleton | boolean | False | false |
| allows_unclaimed | boolean | False | false |
| display_group | text | True | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| roles_key_check | CHECK (key ~ '^[a-z][a-z_]{1,30}$'::text) | False / False |
| roles_pkey | PRIMARY KEY (scope, key) | False / False |
| roles_rank_check | CHECK (rank >= 0 AND rank <= 1000) | False / False |
| roles_scope_check | CHECK (scope = ANY (ARRAY['team'::text, 'match'::text, 'tournament'::text, 'club'::text])) | False / False |
| roles_scope_key_is_singleton_key | UNIQUE (scope, key, is_singleton) | False / False |
| unclaimed_roles_are_powerless | CHECK (NOT allows_unclaimed OR rank = 0 OR key = 'player'::text) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| roles_pkey | CREATE UNIQUE INDEX roles_pkey ON public.roles USING btree (scope, key) |
| roles_scope_key_is_singleton_key | CREATE UNIQUE INDEX roles_scope_key_is_singleton_key ON public.roles USING btree (scope, key, is_singleton) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| roles_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## role_exclusion_sets

Limits on mutually restricted role combinations per member.

Canonical declaration: [20260101000202_role_exclusion_sets.sql](../../supabase/migrations/20260101000202_role_exclusion_sets.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| set_id | uuid | False | gen_random_uuid() |
| scope | text | False | 'team'::text |
| name | text | False | — |
| max_roles | integer | False | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| role_exclusion_sets_max_roles_check | CHECK (max_roles >= 1) | False / False |
| role_exclusion_sets_pkey | PRIMARY KEY (set_id) | False / False |
| role_exclusion_sets_scope_name_key | UNIQUE (scope, name) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| role_exclusion_sets_pkey | CREATE UNIQUE INDEX role_exclusion_sets_pkey ON public.role_exclusion_sets USING btree (set_id) |
| role_exclusion_sets_scope_name_key | CREATE UNIQUE INDEX role_exclusion_sets_scope_name_key ON public.role_exclusion_sets USING btree (scope, name) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| role_exclusion_sets_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## role_exclusion_members

Membership of roles in exclusion sets.

Canonical declaration: [20260101000203_role_exclusion_members.sql](../../supabase/migrations/20260101000203_role_exclusion_members.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| set_id | uuid | False | — |
| scope | text | False | — |
| role_key | text | False | — |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| role_exclusion_members_pkey | PRIMARY KEY (set_id, scope, role_key) | False / False |
| role_exclusion_members_sane | TRIGGER DEFERRABLE INITIALLY DEFERRED | True / True |
| role_exclusion_members_scope_role_key_fkey | FOREIGN KEY (scope, role_key) REFERENCES roles(scope, key) ON DELETE CASCADE | False / False |
| role_exclusion_members_set_id_fkey | FOREIGN KEY (set_id) REFERENCES role_exclusion_sets(set_id) ON DELETE CASCADE | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_role_exclusion_members_role | CREATE INDEX idx_role_exclusion_members_role ON public.role_exclusion_members USING btree (scope, role_key) |
| role_exclusion_members_pkey | CREATE UNIQUE INDEX role_exclusion_members_pkey ON public.role_exclusion_members USING btree (set_id, scope, role_key) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| role_exclusion_members_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

| Name | Definition |
| --- | --- |
| role_exclusion_members_sane | CREATE CONSTRAINT TRIGGER role_exclusion_members_sane AFTER INSERT OR DELETE OR UPDATE ON role_exclusion_members DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION guard_exclusion_set_sane() |

## permissions

Named actions evaluated by the authorization engine.

Canonical declaration: [20260101000204_permissions.sql](../../supabase/migrations/20260101000204_permissions.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| permission_key | text | False | — |
| resource | text | False | — |
| action | text | False | — |
| description | text | False | — |
| min_rank | integer | True | — |
| direct_grantable | boolean | False | false |
| sort_order | integer | False | 0 |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| permissions_min_rank_check | CHECK (min_rank IS NULL OR min_rank >= 0 AND min_rank <= 1000) | False / False |
| permissions_permission_key_check | CHECK (permission_key ~ '^[a-z]+(\.[a-z_]+){1,2}$'::text) | False / False |
| permissions_pkey | PRIMARY KEY (permission_key) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| permissions_pkey | CREATE UNIQUE INDEX permissions_pkey ON public.permissions USING btree (permission_key) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| permissions_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## permission_scopes

Valid entity scopes for each permission, shared by role rules and direct grants.

Canonical declaration: [20260101000205_permission_scopes.sql](../../supabase/migrations/20260101000205_permission_scopes.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| permission_key | text | False | — |
| scope | text | False | — |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| permission_scopes_permission_key_fkey | FOREIGN KEY (permission_key) REFERENCES permissions(permission_key) ON DELETE CASCADE | False / False |
| permission_scopes_pkey | PRIMARY KEY (permission_key, scope) | False / False |
| permission_scopes_scope_check | CHECK (scope = ANY (ARRAY['team'::text, 'match'::text, 'tournament'::text, 'club'::text])) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| permission_scopes_pkey | CREATE UNIQUE INDEX permission_scopes_pkey ON public.permission_scopes USING btree (permission_key, scope) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| permission_scopes_read_all | SELECT | ["anon", "authenticated"] | true | — |

### Triggers

No non-system triggers attached.

## role_permissions

Default permission matrix plus per-team overrides; explicit denial is meaningful.

Canonical declaration: [20260101000206_role_permissions.sql](../../supabase/migrations/20260101000206_role_permissions.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| team_id | uuid | True | — |
| scope | text | False | 'team'::text |
| role_key | text | False | — |
| permission_key | text | False | — |
| granted | boolean | False | true |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| role_permissions_permission_key_scope_fkey | FOREIGN KEY (permission_key, scope) REFERENCES permission_scopes(permission_key, scope) ON DELETE CASCADE | False / False |
| role_permissions_scope_role_key_fkey | FOREIGN KEY (scope, role_key) REFERENCES roles(scope, key) ON DELETE CASCADE | False / False |
| role_permissions_team_id_fkey | FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE | False / False |
| role_permissions_team_id_scope_role_key_permission_key_key | UNIQUE NULLS NOT DISTINCT (team_id, scope, role_key, permission_key) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| idx_role_permissions_lookup | CREATE INDEX idx_role_permissions_lookup ON public.role_permissions USING btree (scope, role_key, permission_key) |
| idx_role_permissions_perm | CREATE INDEX idx_role_permissions_perm ON public.role_permissions USING btree (permission_key) |
| idx_role_permissions_team | CREATE INDEX idx_role_permissions_team ON public.role_permissions USING btree (team_id) |
| role_permissions_team_id_scope_role_key_permission_key_key | CREATE UNIQUE INDEX role_permissions_team_id_scope_role_key_permission_key_key ON public.role_permissions USING btree (team_id, scope, role_key, permission_key) NULLS NOT DISTINCT |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| role_permissions_read | SELECT | ["authenticated"] | ((team_id IS NULL) OR ( SELECT is_team_member(role_permissions.team_id) AS is_team_member)) | — |
| role_permissions_read_anon | SELECT | ["anon"] | (team_id IS NULL) | — |
| role_permissions_write_team | ALL | ["authenticated"] | ((team_id IS NOT NULL) AND ( SELECT team_can(role_permissions.team_id, 'team.permissions.manage'::text) AS team_can)) | ((team_id IS NOT NULL) AND ( SELECT team_can(role_permissions.team_id, 'team.permissions.manage'::text) AS team_can)) |

### Triggers

| Name | Definition |
| --- | --- |
| role_permissions_min_rank | CREATE TRIGGER role_permissions_min_rank BEFORE INSERT OR UPDATE ON role_permissions FOR EACH ROW EXECUTE FUNCTION guard_permission_min_rank() |

## grants

Direct permission assignment on a scoped entity, subject to grantability and scope rules.

Canonical declaration: [20260101000207_grants.sql](../../supabase/migrations/20260101000207_grants.sql)

RLS enabled: **True**. Forced RLS: **False**. Table grants do not replace row policies.

| Column | PostgreSQL type | Nullable | Default / generated expression |
| --- | --- | --- | --- |
| grant_id | uuid | False | gen_random_uuid() |
| subject_id | uuid | False | — |
| scope | text | False | — |
| entity_id | uuid | False | — |
| permission_key | text | False | — |
| granted_by | uuid | True | — |
| expires_at | timestamp with time zone | True | — |
| created_at | timestamp with time zone | False | now() |

### Constraints

| Name | Definition | Deferrable / initially deferred |
| --- | --- | --- |
| grants_granted_by_fkey | FOREIGN KEY (granted_by) REFERENCES profiles(user_id) ON DELETE SET NULL | False / False |
| grants_permission_key_scope_fkey | FOREIGN KEY (permission_key, scope) REFERENCES permission_scopes(permission_key, scope) ON DELETE CASCADE | False / False |
| grants_pkey | PRIMARY KEY (grant_id) | False / False |
| grants_subject_id_fkey | FOREIGN KEY (subject_id) REFERENCES profiles(user_id) ON DELETE CASCADE | False / False |
| grants_subject_id_scope_entity_id_permission_key_key | UNIQUE (subject_id, scope, entity_id, permission_key) | False / False |

### Indexes

| Name | Definition |
| --- | --- |
| grants_pkey | CREATE UNIQUE INDEX grants_pkey ON public.grants USING btree (grant_id) |
| grants_subject_id_scope_entity_id_permission_key_key | CREATE UNIQUE INDEX grants_subject_id_scope_entity_id_permission_key_key ON public.grants USING btree (subject_id, scope, entity_id, permission_key) |
| idx_grants_granted_by | CREATE INDEX idx_grants_granted_by ON public.grants USING btree (granted_by) |
| idx_grants_lookup | CREATE INDEX idx_grants_lookup ON public.grants USING btree (scope, entity_id, permission_key) |
| idx_grants_perm | CREATE INDEX idx_grants_perm ON public.grants USING btree (permission_key) |
| idx_grants_subject | CREATE INDEX idx_grants_subject ON public.grants USING btree (subject_id) |

### Effective API grants

| Role | SELECT | INSERT | UPDATE table | DELETE | TRUNCATE | REFERENCES | TRIGGER |
| --- | --- | --- | --- | --- | --- | --- | --- |
| anon | True | False | False | False | True | True | True |
| authenticated | True | True | True | True | True | True | True |
| service_role | True | True | True | True | True | True | True |

### Row policies

| Policy | Command | Roles | USING | WITH CHECK |
| --- | --- | --- | --- | --- |
| grants_read | SELECT | ["authenticated"] | ((( SELECT auth.uid() AS uid) = subject_id) OR ((scope = 'team'::text) AND ( SELECT team_can(grants.entity_id, 'team.roster.role'::text) AS team_can))) | — |
| grants_write_rpc_only | ALL | ["authenticated"] | false | false |

### Triggers

| Name | Definition |
| --- | --- |
| grants_grantable | CREATE TRIGGER grants_grantable BEFORE INSERT OR UPDATE ON grants FOR EACH ROW EXECUTE FUNCTION guard_grant_is_grantable() |
