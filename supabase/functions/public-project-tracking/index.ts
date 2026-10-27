import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const responseHeaders = (origin: string | null) => ({
  "Access-Control-Allow-Origin": origin === "https://damoc1519-lang.github.io" || /^http:\/\/localhost:(5173|4173)$/.test(origin || "") ? origin! : "https://damoc1519-lang.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
  "Cache-Control": "no-store",
});

Deno.serve(async (req: Request) => {
  const headers = responseHeaders(req.headers.get("origin"));
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers });
  try {
    const body = await req.json();
    const token = typeof body?.token === "string" ? body.token : "";
    if (!/^[A-Za-z0-9_-]{43}$/.test(token)) return new Response(JSON.stringify({ error: "Invalid link" }), { status: 404, headers });
    const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
    const tokenHash = Array.from(new Uint8Array(bytes)).map((x) => x.toString(16).padStart(2, "0")).join("");
    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !serviceKey) return new Response(JSON.stringify({ error: "Service unavailable" }), { status: 503, headers });
    const db = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: project, error } = await db.from("client_projects")
      .select("id,client_name,title,event_date,updated_at")
      .eq("tracking_token_hash", tokenHash).maybeSingle();
    if (error || !project) return new Response(JSON.stringify({ error: "Invalid link" }), { status: 404, headers });
    const { data: stages, error: stageError } = await db.from("client_project_stages")
      .select("id,title,status,sort_order,updated_at")
      .eq("project_id", project.id).order("sort_order", { ascending: true });
    if (stageError) return new Response(JSON.stringify({ error: "Could not load project" }), { status: 500, headers });
    return new Response(JSON.stringify({
      project: { client_name: project.client_name, title: project.title, event_date: project.event_date, updated_at: project.updated_at },
      stages: (stages || []).map((s) => ({ id: s.id, title: s.title, status: s.status, sort_order: s.sort_order, updated_at: s.updated_at })),
    }), { status: 200, headers });
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request" }), { status: 400, headers });
  }
});
