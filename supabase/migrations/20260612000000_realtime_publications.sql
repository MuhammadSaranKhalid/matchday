-- =============================================================================
-- Add tables to the supabase_realtime publication for table CDC replication
-- =============================================================================

do $$
begin
  alter publication supabase_realtime add table public.teams;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.team_members;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.unclaimed_players;
exception when duplicate_object then null;
end $$;

do $$
begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object then null;
end $$;
