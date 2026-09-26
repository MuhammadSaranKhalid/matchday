-- Fix: private.get_ably_auth_header() base64 newline corruption
--
-- Postgres encode(bytea, 'base64') inserts a '\n' character every 76 chars
-- of output (per MIME base64 spec). For a 57-byte Ably API key the base64
-- output is exactly 76 chars followed by a trailing newline, producing an
-- Authorization header value of the form:
--
--   Basic <76-char-base64>\n
--
-- Ably's REST API rejects this with HTTP 400 "invalid request: invalid body"
-- because a raw newline in a header value is illegal in HTTP/1.1 (RFC 7230).
--
-- Fix: strip all embedded '\n' (chr(10)) characters from the base64 output
-- before prepending 'Basic '. This is safe because base64 newlines are purely
-- cosmetic line-wrapping with no semantic meaning.

create or replace function private.get_ably_auth_header()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_api_key text;
begin
  select
    decrypted_secret
  into v_api_key
  from vault.decrypted_secrets
  where name = 'ABLY_API_KEY'
  limit 1;
  if v_api_key is null then
    v_api_key := current_setting('app.settings.ably_api_key', true);
  end if;
  if v_api_key is null or v_api_key = '' then
    return null;
  end if;
  -- Strip MIME-style line-wrapping newlines inserted by Postgres encode().
  return 'Basic ' || replace(encode(v_api_key::bytea, 'base64'), chr(10), '');
end;
$$;

-- Grants are inherited from the original function definition; no change needed.
revoke all on function private.get_ably_auth_header() from public, anon, authenticated;
grant execute on function private.get_ably_auth_header() to service_role;
