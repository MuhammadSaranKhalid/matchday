begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, private, extensions;

select plan(12);

select has_table('private', 'tournament_command_receipts', 'private.tournament_command_receipts exists');
select has_pk('private', 'tournament_command_receipts', 'receipts table has primary key');
select has_column('private', 'tournament_command_receipts', 'command_id', 'command_id exists');
select has_column('private', 'tournament_command_receipts', 'actor_id', 'actor_id exists');
select has_column('private', 'tournament_command_receipts', 'action', 'action exists');
select has_column('private', 'tournament_command_receipts', 'tournament_id', 'tournament_id exists');
select has_column('private', 'tournament_command_receipts', 'request_fingerprint', 'request_fingerprint exists');
select has_column('private', 'tournament_command_receipts', 'response_payload', 'response_payload exists');
select has_column('private', 'tournament_command_receipts', 'created_at', 'created_at exists');
select has_column('private', 'tournament_command_receipts', 'completed_at', 'completed_at exists');

select ok(
  not has_table_privilege('anon', 'private.tournament_command_receipts', 'select')
  and not has_table_privilege('anon', 'private.tournament_command_receipts', 'insert')
  and not has_table_privilege('anon', 'private.tournament_command_receipts', 'update')
  and not has_table_privilege('anon', 'private.tournament_command_receipts', 'delete'),
  'anon role cannot select/insert/update/delete tournament_command_receipts'
);

select ok(
  not has_table_privilege('authenticated', 'private.tournament_command_receipts', 'select')
  and not has_table_privilege('authenticated', 'private.tournament_command_receipts', 'insert')
  and not has_table_privilege('authenticated', 'private.tournament_command_receipts', 'update')
  and not has_table_privilege('authenticated', 'private.tournament_command_receipts', 'delete'),
  'authenticated role cannot select/insert/update/delete tournament_command_receipts'
);

select * from finish();
rollback;
