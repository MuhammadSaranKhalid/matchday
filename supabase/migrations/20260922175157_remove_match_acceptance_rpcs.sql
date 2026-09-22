-- Migration: remove_match_acceptance_rpcs
-- Description: Drop obsolete accept_match_request and accept_pool_application RPCs.
-- Match acceptance is now routed through the match-request-action transactional Edge Function.

revoke execute on function public.accept_match_request(uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid) from authenticated, service_role, public;
drop function if exists public.accept_match_request(uuid, timestamptz, text, jsonb, text, uuid, uuid[], uuid);

revoke execute on function public.accept_pool_application(uuid, text) from authenticated, service_role, public;
drop function if exists public.accept_pool_application(uuid, text);
