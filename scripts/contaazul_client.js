import { supabase } from './supabase_client_contab.js';

/**
 * Conta Azul API v2 integration module for LUMA Contabilidade
 * Uses direct fetch to Edge Functions with query params for compatibility
 *
 * API Base: https://api-v2.contaazul.com
 * Auth: OAuth 2.0 Authorization Code (Cognito JWT)
 */

const CONTAAZUL_AUTH_URL = 'https://auth.contaazul.com/login';
const CONTAAZUL_API_BASE = 'https://api-v2.contaazul.com';
const SUPABASE_FUNCTIONS_URL = 'https://wjoxsyyyqohaqknymqdg.supabase.co/functions/v1';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indqb3hzeXl5cW9oYXFrbnltcWRnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMDM3NzUsImV4cCI6MjA5MDg3OTc3NX0.TVsuVcNNqqC74C70ILXt7GZ9ny_QZhW0DljoKUAtiNw';

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

async function invokeEdgeFunction(functionName, params) {
  const queryString = new URLSearchParams(params).toString();
  const url = `${SUPABASE_FUNCTIONS_URL}/${functionName}?${queryString}`;
  const response = await fetch(url, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      'apikey': SUPABASE_ANON_KEY
    }
  });
  const data = await response.json();
  if (!response.ok) {
    return { data: null, error: data };
  }
  return { data, error: null };
}

async function invokeEdgeFunctionPost(functionName, params) {
  const url = `${SUPABASE_FUNCTIONS_URL}/${functionName}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
      'apikey': SUPABASE_ANON_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(params)
  });
  const data = await response.json();
  if (!response.ok) {
    return { data: null, error: data };
  }
  return { data, error: null };
}

export async function contaAzulAuthorize(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    return await invokeEdgeFunction('contaazul-auth', { action: 'authorize', empresa_id: empresaId });
  } catch (error) {
    console.error('contaAzulAuthorize error:', error);
    return { data: null, error };
  }
}

export async function contaAzulCallback(empresaId, code) {
  try {
    if (!empresaId || !code) throw new Error('empresaId and code are required');
    return await invokeEdgeFunction('contaazul-auth', { action: 'callback', empresa_id: empresaId, code });
  } catch (error) {
    console.error('contaAzulCallback error:', error);
    return { data: null, error };
  }
}

export async function contaAzulStatus(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    return await invokeEdgeFunction('contaazul-auth', { action: 'status', empresa_id: empresaId });
  } catch (error) {
    console.error('contaAzulStatus error:', error);
    return { data: null, error };
  }
}

export async function contaAzulTest(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    return await invokeEdgeFunction('contaazul-auth', { action: 'test', empresa_id: empresaId });
  } catch (error) {
    console.error('contaAzulTest error:', error);
    return { data: null, error };
  }
}

export async function contaAzulRefresh(empresaId) {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    return await invokeEdgeFunction('contaazul-auth', { action: 'refresh', empresa_id: empresaId });
  } catch (error) {
    console.error('contaAzulRefresh error:', error);
    return { data: null, error };
  }
}

export async function contaAzulSync(empresaId, syncAction = 'full') {
  try {
    if (!empresaId) throw new Error('empresaId is required');
    return await invokeEdgeFunction('contaazul-sync', { action: syncAction, empresa_id: empresaId });
  } catch (error) {
    console.error('contaAzulSync error:', error);
    return { data: null, error };
  }
}

export async function contaAzulQuery(empresaId, endpoint, params = {}) {
  try {
    if (!empresaId || !endpoint) throw new Error('empresaId and endpoint are required');
    return await invokeEdgeFunctionPost('contaazul-sync', { action: 'query', empresa_id: empresaId, endpoint, params });
  } catch (error) {
    console.error('contaAzulQuery error:', error);
    return { data: null, error };
  }
}

export { CONTAAZUL_AUTH_URL };
export { supabase };
