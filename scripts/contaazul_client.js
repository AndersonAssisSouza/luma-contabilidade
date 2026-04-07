import { supabase } from './supabase_client_contab.js';

/**
 * Conta Azul API v2 integration module for LUMA Contabilidade
 * Handles OAuth flow, token management, and API queries via Supabase Edge Functions
 *
 * API Base: https://api-v2.contaazul.com
 * Auth: OAuth 2.0 Authorization Code (Cognito JWT)
 */

const CONTAAZUL_AUTH_URL = 'https://auth.contaazul.com/login';
const CONTAAZUL_API_BASE = 'https://api-v2.contaazul.com';

export function getContaAzulAuthUrl(clientId, redirectUri, state = '') {
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: clientId,
    redirect_uri: redirectUri,
    scope: 'openid profile aws.cognito.signin.user.admin'
  });
  if (state) params.append('state', state);
  return `${CONTAAZUL_AUTH_URL}?${params.toString()}`;
}

export async function contaAzulAuthorize(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    const { data, error } = await supabase.functions.invoke('contaazul-auth', {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'authorize', empresa_id: empresaId })
    });
    if (error) return { data: null, error };
    return { data, error: null };
  } catch (error) {
    console.error('contaAzulAuthorize error:', error);
    return { data: null, error };
  }
}

export async function contaAzulCallback(empresaId, code) {
  try {
    if (!empresaId || !code) throw new Error('empresaId and code are required');
    const { data, error } = await supabase.functions.invoke('contaazul-auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'callback', empresa_id: empresaId, code })
    });
    if (error) return { data: null, error };
    return { data, error: null };
  } catch (error) {
    console.error('contaAzulCallback error:', error);
    return { data: null, error };
  }
}

export async function contaAzulStatus(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    const { data, error } = await supabase.functions.invoke('contaazul-auth', {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'status', empresa_id: empresaId })
    });
    if (error) return { data: null, error };
    return { data, error: null };
  } catch (error) {
    console.error('contaAzulStatus error:', error);
    return { data: null, error };
  }
}

export async function contaAzulTest(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    const { data, error } = await supabase.functions.invoke('contaazul-auth', {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'test', empresa_id: empresaId })
    });
    if (error) return { data: null, error };
    return { data, error: null };
  } catch (error) {
    console.error('contaAzulTest error:', error);
    return { data: null, error };
  }
}

export async function contaAzulRefresh(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    const { data, error } = await supabase.functions.invoke('contaazul-auth', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'refresh', empresa_id: empresaId })
    });
    if (error) return { data: null, error };
    return { data, error: null };
  } catch (error) {
    console.error('contaAzulRefresh error:', error);
    return { data: null, error };
  }
}

export async function contaAzulSync(empresaId, syncAction = 'full') {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    const { data, error } = await supabase.functions.invoke('contaazul-sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: syncAction, empresa_id: empresaId })
    });
    if (error) return { data: null, error };
    return { data, error: null };
  } catch (error) {
    console.error('contaAzulSync error:', error);
    return { data: null, error };
  }
}

export async function contaAzulQuery(empresaId, endpoint, params = {}) {
  try {
    if (!empresaId || !endpoint) throw new Error('empresaId and endpoint are required');
    const { data, error } = await supabase.functions.invoke('contaazul-sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'query', empresa_id: empresaId, endpoint, params })
    });
    if (error) return { data: null, error };
    return { data, error: null };
  } catch (error) {
    console.error('contaAzulQuery error:', error);
    return { data: null, error };
  }
}

export { CONTAAZUL_AUTH_URL };
export { supabase };
