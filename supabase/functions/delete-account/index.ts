import { createClient } from "npm:@supabase/supabase-js@2.116.0";
const headers = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info", "Content-Type": "application/json" };
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers });
  const respond = (status: number, message: string) => new Response(JSON.stringify({ message }), { status, headers });
  if (req.method !== "POST") return respond(405, "Use POST");
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return respond(401, "Sign in again");
  const url = Deno.env.get("SUPABASE_URL")!;
  const userClient = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, { global: { headers: { Authorization: authorization } }, auth: { persistSession: false } });
  const { data: { user }, error } = await userClient.auth.getUser();
  if (error || !user) return respond(401, "Sign in again");
  const payload = await req.json().catch(() => ({}));
  if (payload.confirmation !== "DELETE") return respond(400, "Confirm account deletion");
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  // Never accept a user ID, bucket, or file path from the caller.
  for (let batch = 0; batch < 100; batch++) {
    const { data: objects, error: listError } = await userClient.rpc("my_deletion_objects");
    if (listError) return respond(503, "Deletion could not be completed. Please retry or contact support.");
    if (!objects?.length) {
      const { error: deleteError } = await userClient.rpc("delete_user");
      if (deleteError) return respond(503, "Deletion could not be completed. Please retry or contact support.");
      return respond(200, "Account deleted");
    }
    const groups = new Map<string, string[]>();
    for (const object of objects) groups.set(object.bucket_id, [...(groups.get(object.bucket_id) ?? []), object.name]);
    for (const [bucket, paths] of groups) {
      const { error: removeError } = await admin.storage.from(bucket).remove(paths);
      if (removeError) return respond(503, "Some files could not be removed. Please retry or contact support.");
    }
  }
  return respond(503, "More files remain. Please retry to continue deletion.");
});
