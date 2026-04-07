// ==============================================
// Supabase Edge Function: contaazul-auth
// Gerencia fluxo OAuth 2.0 com Conta Azul API v2
// ==============================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CONTAAZUL_AUTH_URL = "https://auth.contaazul.com/login";
const CONTAAZUL_TOKEN_URL = "https://auth.contaazul.com/oauth2/token";
const CONTAAZUL_API_BASE = "https://api-v2.contaazul.com";
const SCOPE = "openid+profile+aws.cognito.signin.user.admin";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const action = url.searchParams.get("action");
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    switch (action) {
      case "authorize": {
        const empresaId = url.searchParams.get("empresa_id");
        if (!empresaId) return jsonResponse({ error: "empresa_id obrigatorio" }, 400);

        const { data: tokenData, error } = await supabase
          .from("contaazul_tokens")
          .select("client_id, redirect_uri")
          .eq("empresa_id", empresaId)
          .single();

        if (error || !tokenData) return jsonResponse({ error: "Credenciais nao encontradas" }, 404);

        const state = crypto.randomUUID();
        await supabase.from("contaazul_tokens")
          .update({ status: "authorizing", updated_at: new Date().toISOString() })
          .eq("empresa_id", empresaId);

        const authUrl = `${CONTAAZUL_AUTH_URL}?response_type=code&client_id=${tokenData.client_id}&redirect_uri=${encodeURIComponent(tokenData.redirect_uri)}&state=${state}&scope=${SCOPE}`;
        return jsonResponse({ auth_url: authUrl, state });
      }

      case "callback": {
        const body = await req.json();
        const { code, empresa_id } = body;
        if (!code || !empresa_id) return jsonResponse({ error: "code e empresa_id obrigatorios" }, 400);

        const { data: tokenData, error } = await supabase
          .from("contaazul_tokens")
          .select("client_id, client_secret, redirect_uri")
          .eq("empresa_id", empresa_id)
          .single();

        if (error || !tokenData) return jsonResponse({ error: "Credenciais nao encontradas" }, 404);

        const basicAuth = btoa(`${tokenData.client_id}:${tokenData.client_secret}`);
        const tokenResponse = await fetch(CONTAAZUL_TOKEN_URL, {
          method: "POST",
          headers: {
            "Authorization": `Basic ${basicAuth}`,
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: new URLSearchParams({
            grant_type: "authorization_code",
            code: code,
            redirect_uri: tokenData.redirect_uri,
          }),
        });

        const tokens = await tokenResponse.json();
        if (!tokenResponse.ok || !tokens.access_token) {
          return jsonResponse({ error: "Falha ao obter tokens", details: tokens.error || tokens.message }, 400);
        }

        const expiresAt = new Date(Date.now() + (tokens.expires_in * 1000)).toISOString();
        await supabase.from("contaazul_tokens")
          .update({
            access_token: tokens.access_token,
            refresh_token: tokens.refresh_token,
            token_expires_at: expiresAt,
            status: "active",
            updated_at: new Date().toISOString(),
          })
          .eq("empresa_id", empresa_id);

        return jsonResponse({ success: true, expires_at: expiresAt, message: "Integracao com Conta Azul ativada com sucesso" });
      }

      case "refresh": {
        const empresaId = url.searchParams.get("empresa_id");
        if (!empresaId) return jsonResponse({ error: "empresa_id obrigatorio" }, 400);
        const refreshedTokens = await refreshAccessToken(supabase, empresaId);
        if (!refreshedTokens) return jsonResponse({ error: "Falha ao renovar token" }, 500);
        return jsonResponse({ success: true, expires_at: refreshedTokens.expires_at });
      }

      case "status": {
        const empresaId = url.searchParams.get("empresa_id");
        if (!empresaId) return jsonResponse({ error: "empresa_id obrigatorio" }, 400);

        const { data, error } = await supabase
          .from("contaazul_tokens")
          .select("status, token_expires_at, updated_at")
          .eq("empresa_id", empresaId)
          .single();

        if (error || !data) return jsonResponse({ connected: false, status: "not_configured" });
        const isExpired = data.token_expires_at && new Date(data.token_expires_at) < new Date();
        return jsonResponse({
          connected: data.status === "active" && !isExpired,
          status: isExpired ? "expired" : data.status,
          expires_at: data.token_expires_at,
          last_updated: data.updated_at,
        });
      }

      case "test": {
        const empresaId = url.searchParams.get("empresa_id");
        if (!empresaId) return jsonResponse({ error: "empresa_id obrigatorio" }, 400);
        const token = await getValidToken(supabase, empresaId);
        if (!token) return jsonResponse({ success: false, error: "Token invalido ou expirado" }, 401);

        const testResponse = await fetch(`${CONTAAZUL_API_BASE}/v1/categorias?page=0&size=1`, {
          headers: { "Authorization": `Bearer ${token}` },
        });
        return jsonResponse({
          success: testResponse.ok,
          api_status: testResponse.status,
          message: testResponse.ok ? "Conexao com Conta Azul OK" : "Falha na conexao",
        });
      }

      default:
        return jsonResponse({ error: "action invalida. Use: authorize, callback, refresh, status, test" }, 400);
    }
  } catch (err) {
    console.error("Erro na Edge Function contaazul-auth:", err);
    return jsonResponse({ error: "Erro interno", details: err.message }, 500);
  }
});

async function getValidToken(supabase: any, empresaId: string): Promise<string | null> {
  const { data, error } = await supabase
    .from("contaazul_tokens")
    .select("access_token, refresh_token, token_expires_at, client_id, client_secret")
    .eq("empresa_id", empresaId)
    .single();

  if (error || !data) return null;
  const expiresAt = new Date(data.token_expires_at);
  const bufferMs = 5 * 60 * 1000;
  if (expiresAt.getTime() - bufferMs > Date.now()) return data.access_token;
  const refreshed = await refreshAccessToken(supabase, empresaId);
  return refreshed ? refreshed.access_token : null;
}

async function refreshAccessToken(supabase: any, empresaId: string) {
  const { data, error } = await supabase
    .from("contaazul_tokens")
    .select("client_id, client_secret, refresh_token")
    .eq("empresa_id", empresaId)
    .single();

  if (error || !data || !data.refresh_token) return null;
  const basicAuth = btoa(`${data.client_id}:${data.client_secret}`);

  const response = await fetch(CONTAAZUL_TOKEN_URL, {
    method: "POST",
    headers: {
      "Authorization": `Basic ${basicAuth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: data.refresh_token,
    }),
  });

  const tokens = await response.json();
  if (!response.ok || !tokens.access_token) {
    console.error("Falha ao refresh token:", tokens);
    await supabase.from("contaazul_tokens").update({ status: "expired" }).eq("empresa_id", empresaId);
    return null;
  }

  const expiresAt = new Date(Date.now() + (tokens.expires_in * 1000)).toISOString();
  await supabase.from("contaazul_tokens")
    .update({
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token || data.refresh_token,
      token_expires_at: expiresAt,
      status: "active",
      updated_at: new Date().toISOString(),
    })
    .eq("empresa_id", empresaId);

  return { access_token: tokens.access_token, expires_at: expiresAt };
}

function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
      }
