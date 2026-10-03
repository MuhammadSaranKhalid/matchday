begin;

create extension if not exists pgtap with schema extensions;

set search_path = public, private, extensions;

select plan(9);


-- 1. Payment capability exists.

select ok(
  exists (
    select 1
    from public.permissions
    where permission_key = 'tournament.payment.manage'
      and resource = 'payment'
      and action = 'manage'
  ),
  'tournament.payment.manage is registered'
);


-- 2. Squad review capability exists.

select ok(
  exists (
    select 1
    from public.permissions
    where permission_key = 'tournament.squad.review'
      and resource = 'squad'
      and action = 'review'
  ),
  'tournament.squad.review is registered'
);


-- 3. Payment capability is valid in Tournament scope.

select ok(
  exists (
    select 1
    from public.permission_scopes
    where permission_key = 'tournament.payment.manage'
      and scope = 'tournament'
  ),
  'tournament.payment.manage is registered for tournament scope'
);


-- 4. Squad review capability is valid in Tournament scope.

select ok(
  exists (
    select 1
    from public.permission_scopes
    where permission_key = 'tournament.squad.review'
      and scope = 'tournament'
  ),
  'tournament.squad.review is registered for tournament scope'
);


-- 5. Tournament manager receives payment authority.

select ok(
  exists (
    select 1
    from public.role_permissions
    where team_id is null
      and scope = 'tournament'
      and role_key = 'manager'
      and permission_key = 'tournament.payment.manage'
      and granted
  ),
  'tournament manager receives tournament.payment.manage'
);


-- 6. Tournament manager receives squad review authority.

select ok(
  exists (
    select 1
    from public.role_permissions
    where team_id is null
      and scope = 'tournament'
      and role_key = 'manager'
      and permission_key = 'tournament.squad.review'
      and granted
  ),
  'tournament manager receives tournament.squad.review'
);


-- 7. Tournament owner role matrix reflects both capabilities.

select ok(
  (
    select count(*)
    from public.role_permissions
    where team_id is null
      and scope = 'tournament'
      and role_key = 'owner'
      and permission_key in (
        'tournament.payment.manage',
        'tournament.squad.review'
      )
      and granted
  ) = 2,
  'tournament owner role matrix contains both Phase 6 capabilities'
);


-- 8. Transitional finance capability must not become a second authority.

select ok(
  not exists (
    select 1
    from public.permission_scopes
    where permission_key = 'tournament.finance.view'
      and scope = 'tournament'
  ),
  'legacy tournament.finance.view is not a Tournament authority'
);


-- 9. Fee ledger uses canonical payment capability.

select ok(
  position(
    'tournament.payment.manage'
    in pg_get_functiondef(
      'public.tournament_fee_ledger(uuid)'::regprocedure
    )
  ) > 0
  and position(
    'tournament.finance.view'
    in pg_get_functiondef(
      'public.tournament_fee_ledger(uuid)'::regprocedure
    )
  ) = 0,
  'fee ledger authorizes with tournament.payment.manage only'
);


select * from finish();

rollback;