import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Manejar preflight CORS
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

    // Cliente con service_role para operaciones admin
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { auth: { autoRefreshToken: false, persistSession: false } }
    );

    // Cliente con el token del manager para verificar identidad
    const supabaseUser = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    // Verificar que el solicitante es un manager autenticado
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
      return new Response(JSON.stringify({ error: "Solo los managers pueden crear trabajadores." }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Leer datos del body
    const { firstName, lastName, email, phone, password, tenantId } = await req.json();

    if (!firstName || !lastName || !email || !password || !tenantId) {
      return new Response(JSON.stringify({ error: "Faltan campos requeridos." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verificar límite de trabajadores según el subscription_tier
    const { data: tenantData } = await supabaseAdmin
      .from("tenants")
      .select("id, owner_id, subscription_tier")
      .eq("id", tenantId)
      .single();

    if (!tenantData || tenantData.owner_id !== user.id) {
      return new Response(JSON.stringify({ error: "No tienes permiso para este negocio." }), {
        status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let workerLimit = 2; // Default freemium
    switch (tenantData.subscription_tier) {
      case "freemium": workerLimit = 2; break;
      case "low": workerLimit = 3; break;
      case "mid": workerLimit = 5; break;
      case "high": workerLimit = 999999; break; // Ilimitado
      default: workerLimit = 1;
    }

    const { count: currentWorkersCount, error: countError } = await supabaseAdmin
      .from("workers")
      .select("id", { count: "exact", head: true })
      .eq("tenant_id", tenantId);

    if (currentWorkersCount !== null && currentWorkersCount >= workerLimit) {
      return new Response(
        JSON.stringify({ error: `Has alcanzado el límite de ${workerLimit} trabajador(es) para tu plan actual.` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verificar que el email no esté en uso
    const { data: existingProfile } = await supabaseAdmin
      .from("profiles")
      .select("id")
      .eq("email", email)
      .maybeSingle();

    if (existingProfile) {
      return new Response(JSON.stringify({ error: "Este correo ya está en uso. Prueba con otro." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Crear usuario en auth.users con Admin API (NO afecta la sesión del manager)
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // Confirmar email automáticamente
      user_metadata: { role: "worker", phone },
    });

    if (createError || !newUser?.user) {
      return new Response(
        JSON.stringify({ error: createError?.message ?? "Error al crear el trabajador." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const workerId = newUser.user.id;

    // Insertar perfil del trabajador
    const { error: profileError } = await supabaseAdmin.from("profiles").insert({
      id: workerId,
      email,
      phone,
      role: "worker",
      first_name: firstName,
      last_name: lastName,
    });

    if (profileError) {
      // Limpiar el usuario de auth si falla el perfil
      await supabaseAdmin.auth.admin.deleteUser(workerId);
      return new Response(JSON.stringify({ error: "Error al crear el perfil del trabajador." }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Registrar en tabla workers
    const { error: workerError } = await supabaseAdmin.from("workers").insert({
      tenant_id: tenantId,
      profile_id: workerId,
      first_name: firstName,
      last_name: lastName,
      email,
    });

    if (workerError) {
      // Limpiar si falla
      await supabaseAdmin.auth.admin.deleteUser(workerId);
      await supabaseAdmin.from("profiles").delete().eq("id", workerId);
      return new Response(JSON.stringify({ error: "Error al registrar el trabajador." }), {
        status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ success: true, worker_id: workerId, email }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: String(error) }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
