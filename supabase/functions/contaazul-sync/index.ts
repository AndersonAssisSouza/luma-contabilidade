// ==============================================
// Supabase Edge Function: contaazul-sync
// Sincroniza dados da Conta Azul API v2 -> Supabase
// ==============================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CONTAAZUL_API_BASE = "https://api-v2.contaazul.com";
const CONTAAZUL_TOKEN_URL = "https://auth.contaazul.com/oauth2/token";
const PAGE_SIZE = 50;
const DATA_INICIO_HISTORICO = "2024-09-01";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

class RateLimiter {
  private timestamps: number[] = [];
  private readonly maxPerSecond = 8;
  private readonly maxPerMinute = 500;

  async waitIfNeeded(): Promise<void> {
    const now = Date.now();
    this.timestamps = this.timestamps.filter((t) => now - t < 60000);
    const lastSecond = this.timestamps.filter((t) => now - t < 1000);
    if (lastSecond.length >= this.maxPerSecond) {
      const waitMs = 1000 - (now - lastSecond[0]);
      await new Promise((r) => setTimeout(r, waitMs + 50));
    }
    if (this.timestamps.length >= this.maxPerMinute) {
      const waitMs = 60000 - (now - this.timestamps[0]);
      await new Promise((r) => setTimeout(r, waitMs + 100));
    }
    this.timestamps.push(Date.now());
  }
}

const rateLimiter = new RateLimiter();

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const action = url.searchParams.get("action");
    const empresaId = url.searchParams.get("empresa_id");
    if (!empresaId) return jsonResponse({ error: "empresa_id obrigatorio" }, 400);

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const token = await getValidToken(supabase, empresaId);
    if (!token) return jsonResponse({ error: "Token invalido. Reconectar integracao." }, 401);

    switch (action) {
      case "full": {
        const results: Record<string, any> = {};
        const syncFunctions = [
          { name: "categorias", fn: () => syncCategorias(supabase, token, empresaId) },
          { name: "categorias_dre", fn: () => syncCategoriasDre(supabase, token, empresaId) },
          { name: "centro_custos", fn: () => syncCentroCustos(supabase, token, empresaId) },
          { name: "contas_financeiras", fn: () => syncContasFinanceiras(supabase, token, empresaId) },
          { name: "pessoas", fn: () => syncPessoas(supabase, token, empresaId) },
          { name: "produtos", fn: () => syncProdutos(supabase, token, empresaId) },
          { name: "servicos", fn: () => syncServicos(supabase, token, empresaId) },
          { name: "contas_receber", fn: () => syncContasReceber(supabase, token, empresaId) },
          { name: "contas_pagar", fn: () => syncContasPagar(supabase, token, empresaId) },
        ];
        for (const { name, fn } of syncFunctions) {
          const logId = await startSyncLog(supabase, empresaId, "full", name);
          try {
            const count = await fn();
            results[name] = { status: "ok", registros: count };
            await finishSyncLog(supabase, logId, "success", count);
          } catch (err) {
            results[name] = { status: "error", error: err.message };
            await finishSyncLog(supabase, logId, "error", 0, err.message);
          }
        }
        return jsonResponse({ success: true, results });
      }

      case "categorias": return await runSingleSync(supabase, token, empresaId, "categorias", syncCategorias);
      case "categorias_dre": return await runSingleSync(supabase, token, empresaId, "categorias_dre", syncCategoriasDre);
      case "centro_custos": return await runSingleSync(supabase, token, empresaId, "centro_custos", syncCentroCustos);
      case "contas_financeiras": return await runSingleSync(supabase, token, empresaId, "contas_financeiras", syncContasFinanceiras);
      case "pessoas": return await runSingleSync(supabase, token, empresaId, "pessoas", syncPessoas);
      case "produtos": return await runSingleSync(supabase, token, empresaId, "produtos", syncProdutos);
      case "servicos": return await runSingleSync(supabase, token, empresaId, "servicos", syncServicos);
      case "contas_receber": return await runSingleSync(supabase, token, empresaId, "contas_receber", syncContasReceber);
      case "contas_pagar": return await runSingleSync(supabase, token, empresaId, "contas_pagar", syncContasPagar);
      case "vendas": return await runSingleSync(supabase, token, empresaId, "vendas", syncVendas);

      case "incremental": {
        // Sync incremental: only financial data that changed recently
        const results: Record<string, any> = {};
        const incrementalFunctions = [
          { name: "contas_financeiras", fn: () => syncContasFinanceiras(supabase, token, empresaId) },
          { name: "contas_receber", fn: () => syncContasReceber(supabase, token, empresaId) },
          { name: "contas_pagar", fn: () => syncContasPagar(supabase, token, empresaId) },
        ];
        for (const { name, fn } of incrementalFunctions) {
          const logId = await startSyncLog(supabase, empresaId, "incremental", name);
          try {
            const count = await fn();
            results[name] = { status: "ok", registros: count };
            await finishSyncLog(supabase, logId, "success", count);
          } catch (err: any) {
            results[name] = { status: "error", error: err.message };
            await finishSyncLog(supabase, logId, "error", 0, err.message);
          }
        }
        return jsonResponse({ success: true, type: "incremental", results });
      }

      case "scheduled": {
        // Scheduled sync: 3x/dia nos horarios BRT
        // 6:00 BRT (09:00 UTC) = full sync
        // 11:00 BRT (14:00 UTC) = incremental
        // 16:00 BRT (19:00 UTC) = incremental
        const now = new Date();
        const hour = now.getUTCHours();
        const isFullSync = hour === 9; // 6:00 BRT

        if (isFullSync) {
          const results: Record<string, any> = {};
          const allFunctions = [
            { name: "categorias", fn: () => syncCategorias(supabase, token, empresaId) },
            { name: "categorias_dre", fn: () => syncCategoriasDre(supabase, token, empresaId) },
            { name: "centro_custos", fn: () => syncCentroCustos(supabase, token, empresaId) },
            { name: "contas_financeiras", fn: () => syncContasFinanceiras(supabase, token, empresaId) },
            { name: "pessoas", fn: () => syncPessoas(supabase, token, empresaId) },
            { name: "produtos", fn: () => syncProdutos(supabase, token, empresaId) },
            { name: "servicos", fn: () => syncServicos(supabase, token, empresaId) },
            { name: "contas_receber", fn: () => syncContasReceber(supabase, token, empresaId) },
            { name: "contas_pagar", fn: () => syncContasPagar(supabase, token, empresaId) },
            { name: "vendas", fn: () => syncVendas(supabase, token, empresaId) },
          ];
          for (const { name, fn } of allFunctions) {
            const logId = await startSyncLog(supabase, empresaId, "scheduled_full", name);
            try {
              const count = await fn();
              results[name] = { status: "ok", registros: count };
              await finishSyncLog(supabase, logId, "success", count);
            } catch (err: any) {
              results[name] = { status: "error", error: err.message };
              await finishSyncLog(supabase, logId, "error", 0, err.message);
            }
          }
          return jsonResponse({ success: true, type: "scheduled_full", results });
        } else {
          // Incremental: only financial data (11h e 16h BRT)
          const results: Record<string, any> = {};
          const incFunctions = [
            { name: "contas_financeiras", fn: () => syncContasFinanceiras(supabase, token, empresaId) },
            { name: "contas_receber", fn: () => syncContasReceber(supabase, token, empresaId) },
            { name: "contas_pagar", fn: () => syncContasPagar(supabase, token, empresaId) },
          ];
          for (const { name, fn } of incFunctions) {
            const logId = await startSyncLog(supabase, empresaId, "scheduled_incremental", name);
            try {
              const count = await fn();
              results[name] = { status: "ok", registros: count };
              await finishSyncLog(supabase, logId, "success", count);
            } catch (err: any) {
              results[name] = { status: "error", error: err.message };
              await finishSyncLog(supabase, logId, "error", 0, err.message);
            }
          }
          return jsonResponse({ success: true, type: "scheduled_incremental", results });
        }
      }

      case "query": {
        const endpoint = url.searchParams.get("endpoint");
        if (!endpoint) return jsonResponse({ error: "endpoint obrigatorio" }, 400);
        const params = new URLSearchParams();
        url.searchParams.forEach((v, k) => {
          if (!["action", "empresa_id", "endpoint"].includes(k)) params.set(k, v);
        });
        await rateLimiter.waitIfNeeded();
        const apiUrl = `${CONTAAZUL_API_BASE}${endpoint}?${params.toString()}`;
        const response = await fetch(apiUrl, { headers: { "Authorization": `Bearer ${token}` } });
        const data = await response.json();
        return jsonResponse(data, response.status);
      }

      default:
        return jsonResponse({ error: "action invalida", available: ["full", "categorias", "categorias_dre", "centro_custos", "contas_financeiras", "pessoas", "produtos", "servicos", "contas_receber", "contas_pagar", "vendas", "query"] }, 400);
    }
  } catch (err) {
    console.error("Erro na Edge Function contaazul-sync:", err);
    return jsonResponse({ error: "Erro interno", details: err.message }, 500);
  }
});

// =========================================
// SYNC FUNCTIONS
// =========================================

async function syncCategorias(supabase: any, token: string, empresaId: string): Promise<number> {
  // 1) Fetch from CA API (returns top-level tree nodes)
  const allItems = await fetchAllPages(token, "/v1/categorias", "itens");
  const records = allItems.map((item: any) => ({
    id: item.id, empresa_id: empresaId, versao: item.versao || 0, nome: item.nome,
    categoria_pai: item.categoria_pai || null, tipo: item.tipo,
    entrada_saida: item.entrada_saida || null, ativo: item.ativo !== false,
    dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_categorias").upsert(records, { onConflict: "id" });

  // 2) Extract inline categories from dados_raw of contas (catches sub-categories not returned by /v1/categorias)
  await supabase.rpc("upsert_categorias_from_contas_raw", { p_empresa_id: empresaId });

  return records.length;
}

async function syncCategoriasDre(supabase: any, token: string, empresaId: string): Promise<number> {
  await rateLimiter.waitIfNeeded();
  const response = await fetch(`${CONTAAZUL_API_BASE}/v1/financeiro/categorias-dre`, { headers: { "Authorization": `Bearer ${token}` } });
  const data = await response.json();
  const items = data.itens || data.items || [];
  const records = items.map((item: any) => ({
    id: item.id, empresa_id: empresaId, descricao: item.descricao, codigo: item.codigo,
    posicao: item.posicao, indica_totalizador: item.indica_totalizador || false,
    representacao: item.representacao || null, dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_categorias_dre").upsert(records, { onConflict: "id" });
  return records.length;
}

async function syncCentroCustos(supabase: any, token: string, empresaId: string): Promise<number> {
  await rateLimiter.waitIfNeeded();
  const response = await fetch(`${CONTAAZUL_API_BASE}/v1/centro-de-custo`, { headers: { "Authorization": `Bearer ${token}` } });
  const data = await response.json();
  const items = data.itens || data.items || [];
  const records = items.map((item: any) => ({
    id: item.id, empresa_id: empresaId, nome: item.nome, ativo: item.ativo !== false,
    dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_centro_custos").upsert(records, { onConflict: "id" });
  return records.length;
}

async function syncContasFinanceiras(supabase: any, token: string, empresaId: string): Promise<number> {
  await rateLimiter.waitIfNeeded();
  const response = await fetch(`${CONTAAZUL_API_BASE}/v1/conta-financeira`, { headers: { "Authorization": `Bearer ${token}` } });
  const data = await response.json();
  const items = data.itens || data.items || [];
  const records = items.map((item: any) => ({
    id: item.id, empresa_id: empresaId, nome: item.nome, tipo: item.tipo || null,
    saldo_atual: item.saldo_atual || 0, ativo: item.ativo !== false,
    dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_contas_financeiras").upsert(records, { onConflict: "id" });
  return records.length;
}

async function syncPessoas(supabase: any, token: string, empresaId: string): Promise<number> {
  const allItems = await fetchAllPages(token, "/v1/pessoas", "items");
  const records = allItems.map((item: any) => ({
    id: item.id, empresa_id: empresaId, nome: item.nome, documento: item.documento || null,
    email: item.email || null, telefone: item.telefone || item.celular || null,
    tipo_pessoa: item.tipo_pessoa || null, tipo_relacao: item.tipo_relacao || item.tipos || [],
    ativo: item.ativo !== false,
    endereco_logradouro: item.endereco?.logradouro || null, endereco_numero: item.endereco?.numero || null,
    endereco_complemento: item.endereco?.complemento || null, endereco_bairro: item.endereco?.bairro || null,
    endereco_cidade: item.endereco?.cidade || null, endereco_uf: item.endereco?.uf || null,
    endereco_cep: item.endereco?.cep || null, dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_pessoas").upsert(records, { onConflict: "id" });
  return records.length;
}

async function syncProdutos(supabase: any, token: string, empresaId: string): Promise<number> {
  const allItems = await fetchAllPages(token, "/v1/produtos", "items");
  const records = allItems.map((item: any) => ({
    id: item.id, empresa_id: empresaId, id_legado: item.id_legado || null, nome: item.nome,
    codigo: item.codigo || null, preco_venda: item.preco_venda || item.valor_venda || 0,
    preco_custo: item.preco_custo || item.valor_custo || 0, ncm: item.ncm || null,
    unidade_medida: item.unidade_medida || null, estoque_atual: item.estoque_atual || item.quantidade_estoque || 0,
    ativo: item.ativo !== false, dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_produtos").upsert(records, { onConflict: "id" });
  return records.length;
}

async function syncServicos(supabase: any, token: string, empresaId: string): Promise<number> {
  await rateLimiter.waitIfNeeded();
  const response = await fetch(`${CONTAAZUL_API_BASE}/v1/servicos?page=0&size=${PAGE_SIZE}`, { headers: { "Authorization": `Bearer ${token}` } });
  const data = await response.json();
  const items = data.itens || data.items || [];
  const records = items.map((item: any) => ({
    id: item.id, empresa_id: empresaId, id_servico: item.id_servico || null,
    codigo: item.codigo || null, descricao: item.descricao, preco: item.preco || item.valor || 0,
    ativo: item.ativo !== false, dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_servicos").upsert(records, { onConflict: "id" });
  return records.length;
}

async function syncContasReceber(supabase: any, token: string, empresaId: string): Promise<number> {
  const dataFim = new Date();
  dataFim.setMonth(dataFim.getMonth() + 6);
  let allItems: any[] = [];
  let pagina = 1;
  let hasMore = true;
  while (hasMore) {
    await rateLimiter.waitIfNeeded();
    const params = new URLSearchParams({
      data_vencimento_de: DATA_INICIO_HISTORICO,
      data_vencimento_ate: dataFim.toISOString().split("T")[0],
      pagina: String(pagina),
      tamanho_pagina: String(PAGE_SIZE),
    });
    const response = await fetch(
      `${CONTAAZUL_API_BASE}/v1/financeiro/eventos-financeiros/contas-a-receber/buscar?${params}`,
      { headers: { "Authorization": `Bearer ${token}` } }
    );
    if (!response.ok) {
      console.error(`syncContasReceber page ${pagina} failed: ${response.status}`);
      break;
    }
    const data = await response.json();
    const items = data.itens || [];
    allItems = allItems.concat(items);
    hasMore = items.length >= PAGE_SIZE;
    pagina++;
  }
  const records = allItems.map((item: any) => {
    const emissao = item.data_emissao || null;
    const competencia = item.data_competencia || item.data_emissao || null;
    return {
      id: item.id, empresa_id: empresaId, descricao: item.descricao || null, status: item.status,
      status_traduzido: item.status_traduzido || null, total: item.total || 0,
      pago: item.pago || 0, nao_pago: item.nao_pago || 0, data_vencimento: item.data_vencimento || null,
      data_emissao: emissao, data_competencia: competencia,
      data_criacao: item.data_criacao || null, data_alteracao: item.data_alteracao || null,
      pessoa_id: item.pessoa?.id || item.cliente?.id || null,
      categoria_id: item.categorias?.[0]?.id || item.categoria?.id || null,
      conta_financeira_id: item.conta_financeira?.id || null,
      dados_raw: item, sync_at: new Date().toISOString(),
    };
  });
  if (records.length > 0) {
    for (let i = 0; i < records.length; i += 500) {
      const batch = records.slice(i, i + 500);
      await supabase.from("ca_contas_receber").upsert(batch, { onConflict: "id" });
    }
  }
  return records.length;
}

async function syncContasPagar(supabase: any, token: string, empresaId: string): Promise<number> {
  const dataFim = new Date();
  dataFim.setMonth(dataFim.getMonth() + 6);
  let allItems: any[] = [];
  let pagina = 1;
  let hasMore = true;
  while (hasMore) {
    await rateLimiter.waitIfNeeded();
    const params = new URLSearchParams({
      data_vencimento_de: DATA_INICIO_HISTORICO,
      data_vencimento_ate: dataFim.toISOString().split("T")[0],
      pagina: String(pagina),
      tamanho_pagina: String(PAGE_SIZE),
    });
    const response = await fetch(
      `${CONTAAZUL_API_BASE}/v1/financeiro/eventos-financeiros/contas-a-pagar/buscar?${params}`,
      { headers: { "Authorization": `Bearer ${token}` } }
    );
    if (!response.ok) {
      console.error(`syncContasPagar page ${pagina} failed: ${response.status}`);
      break;
    }
    const data = await response.json();
    const items = data.itens || [];
    allItems = allItems.concat(items);
    hasMore = items.length >= PAGE_SIZE;
    pagina++;
  }
  const records = allItems.map((item: any) => {
    const emissao = item.data_emissao || null;
    const competencia = item.data_competencia || item.data_emissao || null;
    return {
      id: item.id, empresa_id: empresaId, descricao: item.descricao || null, status: item.status,
      status_traduzido: item.status_traduzido || null, total: item.total || 0,
      pago: item.pago || 0, nao_pago: item.nao_pago || 0, data_vencimento: item.data_vencimento || null,
      data_emissao: emissao, data_competencia: competencia,
      data_criacao: item.data_criacao || null, data_alteracao: item.data_alteracao || null,
      pessoa_id: item.fornecedor?.id || item.pessoa?.id || null,
      categoria_id: item.categorias?.[0]?.id || item.categoria?.id || null,
      conta_financeira_id: item.conta_financeira?.id || null,
      dados_raw: item, sync_at: new Date().toISOString(),
    };
  });
  if (records.length > 0) {
    for (let i = 0; i < records.length; i += 500) {
      const batch = records.slice(i, i + 500);
      await supabase.from("ca_contas_pagar").upsert(batch, { onConflict: "id" });
    }
  }
  return records.length;
}

async function syncVendas(supabase: any, token: string, empresaId: string): Promise<number> {
  const dataFim = new Date();
  const params = new URLSearchParams({
    data_inicio: DATA_INICIO_HISTORICO,
    data_fim: dataFim.toISOString().split("T")[0], page: "0", size: String(PAGE_SIZE),
  });
  await rateLimiter.waitIfNeeded();
  const response = await fetch(`${CONTAAZUL_API_BASE}/v1/venda/busca?${params}`, { headers: { "Authorization": `Bearer ${token}` } });
  if (!response.ok) return 0;
  const data = await response.json();
  const items = data.itens || data.items || [];
  const records = items.map((item: any) => ({
    id: item.id, empresa_id: empresaId, numero: item.numero || null,
    data_venda: item.data_venda || item.data || null, status: item.status || null,
    valor_total: item.valor_total || item.total || 0,
    pessoa_id: item.pessoa?.id || item.id_pessoa || null, vendedor_id: item.vendedor?.id || null,
    dados_raw: item, sync_at: new Date().toISOString(),
  }));
  if (records.length > 0) await supabase.from("ca_vendas").upsert(records, { onConflict: "id" });
  return records.length;
}

// =========================================
// HELPERS
// =========================================

async function fetchAllPages(token: string, endpoint: string, itemsKey: string): Promise<any[]> {
  let allItems: any[] = []; let page = 0; let hasMore = true;
  while (hasMore) {
    await rateLimiter.waitIfNeeded();
    const response = await fetch(`${CONTAAZUL_API_BASE}${endpoint}?page=${page}&size=${PAGE_SIZE}`, { headers: { "Authorization": `Bearer ${token}` } });
    if (!response.ok) break;
    const data = await response.json();
    const items = data[itemsKey] || data.itens || data.items || [];
    allItems = allItems.concat(items);
    const totalItems = data.totalItems || data.itens_totais || 0;
    hasMore = items.length >= PAGE_SIZE && allItems.length < totalItems;
    page++;
  }
  return allItems;
}

async function getValidToken(supabase: any, empresaId: string): Promise<string | null> {
  const { data, error } = await supabase.from("contaazul_tokens")
    .select("access_token, refresh_token, token_expires_at, client_id, client_secret")
    .eq("empresa_id", empresaId).single();
  if (error || !data) return null;
  const expiresAt = new Date(data.token_expires_at);
  const bufferMs = 5 * 60 * 1000;
  if (expiresAt.getTime() - bufferMs > Date.now()) return data.access_token;

  const basicAuth = btoa(`${data.client_id}:${data.client_secret}`);
  const response = await fetch(CONTAAZUL_TOKEN_URL, {
    method: "POST",
    headers: { "Authorization": `Basic ${basicAuth}`, "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "refresh_token", refresh_token: data.refresh_token }),
  });
  const tokens = await response.json();
  if (!response.ok || !tokens.access_token) return null;
  const newExpiresAt = new Date(Date.now() + (tokens.expires_in * 1000)).toISOString();
  await supabase.from("contaazul_tokens").update({
    access_token: tokens.access_token, refresh_token: tokens.refresh_token || data.refresh_token,
    token_expires_at: newExpiresAt, status: "active",
  }).eq("empresa_id", empresaId);
  return tokens.access_token;
}

async function runSingleSync(supabase: any, token: string, empresaId: string, entityName: string, syncFn: (s: any, t: string, e: string) => Promise<number>) {
  const logId = await startSyncLog(supabase, empresaId, "manual", entityName);
  try {
    const count = await syncFn(supabase, token, empresaId);
    await finishSyncLog(supabase, logId, "success", count);
    return jsonResponse({ success: true, entity: entityName, records: count });
  } catch (err) {
    await finishSyncLog(supabase, logId, "error", 0, err.message);
    return jsonResponse({ success: false, entity: entityName, error: err.message }, 500);
  }
}

async function startSyncLog(supabase: any, empresaId: string, tipo: string, entidade: string): Promise<string> {
  const { data } = await supabase.from("contaazul_sync_log")
    .insert({ empresa_id: empresaId, tipo_sync: tipo, entidade, status: "running" })
    .select("id").single();
  return data?.id;
}

async function finishSyncLog(supabase: any, logId: string, status: string, count: number, erro?: string) {
  if (!logId) return;
  await supabase.from("contaazul_sync_log").update({
    status, registros_sincronizados: count, erro: erro || null, fim: new Date().toISOString(),
  }).eq("id", logId);
}

function jsonResponse(data: any, status = 200) {
  return new Response(JSON.stringify(data), {
    status, headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
