import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Verificar autenticación del manager
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: callerProfile } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (!callerProfile || callerProfile.role !== "manager") {
      return new Response(JSON.stringify({ error: "Solo los managers pueden eliminar trabajadores." }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { workerId } = await req.json();

    if (!workerId) {
      return new Response(JSON.stringify({ error: "workerId es requerido." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verificar que el trabajador pertenece a un tenant del manager
    const { data: workerRow } = await supabaseAdmin
      .from("workers")
      .select("tenant_id")
      .eq("profile_id", workerId)
      .single();

    if (!workerRow) {
      return new Response(JSON.stringify({ error: "Trabajador no encontrado." }), {
        status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: tenantRow } = await supabaseAdmin
      .from("tenants")
      .select("owner_id")
      .eq("id", workerRow.tenant_id)
      .single();

    if (!tenantRow || tenantRow.owner_id !== user.id) {
      return new Response(JSON.stringify({ error: "No tienes permiso para eliminar este trabajador." }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Eliminar de la tabla workers
    await supabaseAdmin.from("workers").delete().eq("profile_id", workerId);

    // Eliminar perfil
    await supabaseAdmin.from("profiles").delete().eq("id", workerId);

    // Eliminar de auth.users (requiere Admin API)
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(workerId);
    if (deleteAuthError) {
      // No es crítico si ya fue eliminado de las tablas
      console.warn("Warning: no se pudo eliminar de auth.users:", deleteAuthError.message);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
