import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = ''; // To be configured
const SUPABASE_ANON_KEY = ''; // To be configured

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ============================================================================
// AUTENTICAÇÃO
// ============================================================================

/**
 * Realiza login do usuário
 * @param {string} email - Email do usuário
 * @param {string} password - Senha do usuário
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function login(email, password) {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Realiza logout do usuário
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function logout() {
  try {
    const { error } = await supabase.auth.signOut();
    sessionStorage.removeItem('profile_cache');
    return { data: null, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Redefine a senha do usuário
 * @param {string} email - Email do usuário
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function resetPassword(email) {
  try {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email);
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém a sessão atual do usuário
 * @returns {Promise<Object>}
 */
export async function getSession() {
  try {
    const { data: { session }, error } = await supabase.auth.getSession();
    return session;
  } catch (err) {
    return null;
  }
}

/**
 * Subscribe às mudanças de estado de autenticação
 * @param {Function} callback - Função a ser executada quando houver mudança
 * @returns {Function} Função para unsubscribe
 */
export function onAuthStateChange(callback) {
  return supabase.auth.onAuthStateChange((event, session) => {
    callback(event, session);
  });
}

/**
 * Obtém o perfil do usuário logado
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getProfile() {
  try {
    const cached = sessionStorage.getItem('profile_cache');
    if (cached) {
      return { data: JSON.parse(cached), error: null };
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return { data: null, error: authError };
    }

    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.id)
      .single();

    if (!error && data) {
      sessionStorage.setItem('profile_cache', JSON.stringify(data));
    }

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Verifica autenticação e autorização por role
 * @param {Array<string>} rolesPermitidos - Array de roles permitidos
 * @returns {Promise<{authorized: boolean, profile: Object, error: Object}>}
 */
export async function requireAuth(rolesPermitidos = []) {
  try {
    const { data: profile, error: profileError } = await getProfile();

    if (profileError || !profile) {
      window.location.href = '/login.html';
      return { authorized: false, profile: null, error: profileError };
    }

    if (rolesPermitidos.length > 0 && !rolesPermitidos.includes(profile.role)) {
      return { authorized: false, profile, error: new Error('Acesso negado') };
    }

    return { authorized: true, profile, error: null };
  } catch (err) {
    return { authorized: false, profile: null, error: err };
  }
}

// ============================================================================
// TENANT
// ============================================================================

/**
 * Obtém os dados do tenant
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getTenant() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('tenants')
      .select('*')
      .eq('id', profile.tenant_id)
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza os dados do tenant
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateTenant(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('tenants')
      .update(dados)
      .eq('id', profile.tenant_id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// PLANO DE CONTAS
// ============================================================================

/**
 * Obtém as contas contábeis com filtros opcionais
 * @param {Object} filtros - { tipo, categoria, ativo }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getPlanoContas(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('plano_contas')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.tipo) query = query.eq('tipo', filtros.tipo);
    if (filtros.categoria) query = query.eq('categoria_id', filtros.categoria);
    if (filtros.ativo !== undefined) query = query.eq('ativo', filtros.ativo);

    const { data, error } = await query.order('numero');
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova conta contábil
 * @param {Object} dados - { numero, nome, tipo, categoria_id, ativo }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createConta(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('plano_contas')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma conta contábil
 * @param {string} id - ID da conta
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateConta(id, dados) {
  try {
    const { data, error } = await supabase
      .from('plano_contas')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Deleta uma conta contábil
 * @param {string} id - ID da conta
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function deleteConta(id) {
  try {
    const { data, error } = await supabase
      .from('plano_contas')
      .delete()
      .eq('id', id);

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém contas contábeis por tipo
 * @param {string} tipo - Tipo da conta (ativo, passivo, receita, despesa, patrimonio)
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasByTipo(tipo) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('plano_contas')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('tipo', tipo)
      .eq('ativo', true)
      .order('numero');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém contas analíticas
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasAnaliticas() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('plano_contas')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('analitica', true)
      .eq('ativo', true)
      .order('numero');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// CATEGORIAS
// ============================================================================

/**
 * Obtém categorias por tipo
 * @param {string} tipo - Tipo da categoria
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getCategorias(tipo) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('categorias')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('tipo', tipo)
      .order('nome');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova categoria
 * @param {Object} dados - { tipo, nome, descricao }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createCategoria(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('categorias')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma categoria
 * @param {string} id - ID da categoria
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateCategoria(id, dados) {
  try {
    const { data, error } = await supabase
      .from('categorias')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Deleta uma categoria
 * @param {string} id - ID da categoria
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function deleteCategoria(id) {
  try {
    const { data, error } = await supabase
      .from('categorias')
      .delete()
      .eq('id', id);

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// CENTROS DE CUSTO
// ============================================================================

/**
 * Obtém todos os centros de custo
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getCentrosCusto() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('centros_custo')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .order('nome');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo centro de custo
 * @param {Object} dados - { codigo, nome, descricao }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createCentroCusto(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('centros_custo')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza um centro de custo
 * @param {string} id - ID do centro de custo
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateCentroCusto(id, dados) {
  try {
    const { data, error } = await supabase
      .from('centros_custo')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// CONTAS BANCÁRIAS
// ============================================================================

/**
 * Obtém todas as contas bancárias
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasBancarias() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('contas_bancarias')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .order('nome');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova conta bancária
 * @param {Object} dados - { banco, agencia, conta, digito, titular, tipo }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createContaBancaria(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('contas_bancarias')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma conta bancária
 * @param {string} id - ID da conta bancária
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateContaBancaria(id, dados) {
  try {
    const { data, error } = await supabase
      .from('contas_bancarias')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém o saldo de uma conta bancária
 * @param {string} contaId - ID da conta bancária
 * @returns {Promise<{data: number, error: Object}>}
 */
export async function getSaldoBancario(contaId) {
  try {
    const { data, error } = await supabase
      .from('contas_bancarias')
      .select('saldo')
      .eq('id', contaId)
      .single();

    return { data: data?.saldo || 0, error };
  } catch (err) {
    return { data: 0, error: err };
  }
}

// ============================================================================
// CLIENTES
// ============================================================================

/**
 * Obtém clientes com busca opcional
 * @param {string} search - Termo de busca (nome ou CNPJ)
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getClientes(search = '') {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('clientes')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (search) {
      query = query.or(`nome.ilike.%${search}%,cnpj.ilike.%${search}%`);
    }

    const { data, error } = await query.order('nome');
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém um cliente específico
 * @param {string} id - ID do cliente
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getCliente(id) {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('id', id)
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo cliente
 * @param {Object} dados - { nome, cnpj, cpf, email, telefone, endereco }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createCliente(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('clientes')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza um cliente
 * @param {string} id - ID do cliente
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateCliente(id, dados) {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Deleta um cliente
 * @param {string} id - ID do cliente
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function deleteCliente(id) {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .delete()
      .eq('id', id);

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// FORNECEDORES
// ============================================================================

/**
 * Obtém fornecedores com busca opcional
 * @param {string} search - Termo de busca (nome ou CNPJ)
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getFornecedores(search = '') {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('fornecedores')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (search) {
      query = query.or(`nome.ilike.%${search}%,cnpj.ilike.%${search}%`);
    }

    const { data, error } = await query.order('nome');
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém um fornecedor específico
 * @param {string} id - ID do fornecedor
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getFornecedor(id) {
  try {
    const { data, error } = await supabase
      .from('fornecedores')
      .select('*')
      .eq('id', id)
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo fornecedor
 * @param {Object} dados - { nome, cnpj, cpf, email, telefone, endereco }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createFornecedor(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('fornecedores')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza um fornecedor
 * @param {string} id - ID do fornecedor
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateFornecedor(id, dados) {
  try {
    const { data, error } = await supabase
      .from('fornecedores')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Deleta um fornecedor
 * @param {string} id - ID do fornecedor
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function deleteFornecedor(id) {
  try {
    const { data, error } = await supabase
      .from('fornecedores')
      .delete()
      .eq('id', id);

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// PRODUTOS/SERVIÇOS
// ============================================================================

/**
 * Obtém produtos/serviços por tipo
 * @param {string} tipo - Tipo (produto, servico)
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getProdutosServicos(tipo) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('produtos_servicos')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('tipo', tipo)
      .order('nome');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo produto/serviço
 * @param {Object} dados - { tipo, codigo, nome, descricao, preco, ncm, cst }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createProdutoServico(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('produtos_servicos')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza um produto/serviço
 * @param {string} id - ID do produto/serviço
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateProdutoServico(id, dados) {
  try {
    const { data, error } = await supabase
      .from('produtos_servicos')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// NOTAS FISCAIS
// ============================================================================

/**
 * Obtém notas fiscais com filtros opcionais
 * @param {Object} filtros - { tipo, status, cliente_id, fornecedor_id }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getNotasFiscais(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('notas_fiscais')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.tipo) query = query.eq('tipo', filtros.tipo);
    if (filtros.status) query = query.eq('status', filtros.status);
    if (filtros.cliente_id) query = query.eq('cliente_id', filtros.cliente_id);
    if (filtros.fornecedor_id) query = query.eq('fornecedor_id', filtros.fornecedor_id);

    const { data, error } = await query.order('data', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém uma nota fiscal específica
 * @param {string} id - ID da nota fiscal
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getNotaFiscal(id) {
  try {
    const { data, error } = await supabase
      .from('notas_fiscais')
      .select('*')
      .eq('id', id)
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova nota fiscal
 * @param {Object} dados - { tipo, numero, serie, data, cliente_id, fornecedor_id, valor_total, desconto, valor_liquido }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createNotaFiscal(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('notas_fiscais')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma nota fiscal
 * @param {string} id - ID da nota fiscal
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateNotaFiscal(id, dados) {
  try {
    const { data, error } = await supabase
      .from('notas_fiscais')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém notas fiscais por competência
 * @param {string} inicio - Data inicial (YYYY-MM-DD)
 * @param {string} fim - Data final (YYYY-MM-DD)
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getNotasFiscaisPorCompetencia(inicio, fim) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('notas_fiscais')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .gte('data', inicio)
      .lte('data', fim)
      .order('data');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// ITENS NF
// ============================================================================

/**
 * Obtém itens de uma nota fiscal
 * @param {string} notaId - ID da nota fiscal
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getItensNF(notaId) {
  try {
    const { data, error } = await supabase
      .from('itens_nf')
      .select('*')
      .eq('nota_id', notaId)
      .order('sequencia');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo item de nota fiscal
 * @param {Object} dados - { nota_id, produto_id, quantidade, preco_unitario, desconto_item }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createItemNF(dados) {
  try {
    const { data, error } = await supabase
      .from('itens_nf')
      .insert(dados)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Deleta um item de nota fiscal
 * @param {string} id - ID do item
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function deleteItemNF(id) {
  try {
    const { data, error } = await supabase
      .from('itens_nf')
      .delete()
      .eq('id', id);

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// LANÇAMENTOS CONTÁBEIS
// ============================================================================

/**
 * Obtém lançamentos contábeis com filtros opcionais
 * @param {Object} filtros - { data_inicio, data_fim, conta_id, tipo }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getLancamentos(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('lancamentos_contabeis')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.data_inicio) query = query.gte('data', filtros.data_inicio);
    if (filtros.data_fim) query = query.lte('data', filtros.data_fim);
    if (filtros.conta_id) query = query.eq('conta_id', filtros.conta_id);
    if (filtros.tipo) query = query.eq('tipo', filtros.tipo);

    const { data, error } = await query.order('data', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo lançamento contábil
 * @param {Object} dados - { data, conta_debito_id, conta_credito_id, valor, descricao, documento_id }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createLancamento(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('lancamentos_contabeis')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Estorna um lançamento contábil
 * @param {string} id - ID do lançamento
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function estornarLancamento(id) {
  try {
    const { data, error } = await supabase
      .from('lancamentos_contabeis')
      .update({ estornado: true, data_estorno: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém lançamentos de uma conta por período
 * @param {string} contaId - ID da conta
 * @param {Object} periodo - { data_inicio, data_fim }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getLancamentosPorConta(contaId, periodo = {}) {
  try {
    let query = supabase
      .from('lancamentos_contabeis')
      .select('*')
      .or(`conta_debito_id.eq.${contaId},conta_credito_id.eq.${contaId}`)
      .eq('estornado', false);

    if (periodo.data_inicio) query = query.gte('data', periodo.data_inicio);
    if (periodo.data_fim) query = query.lte('data', periodo.data_fim);

    const { data, error } = await query.order('data', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém balancete de verificação
 * @param {string} dataInicio - Data inicial (YYYY-MM-DD)
 * @param {string} dataFim - Data final (YYYY-MM-DD)
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getBalancete(dataInicio, dataFim) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('calcular_balancete', {
        p_tenant_id: profile.tenant_id,
        p_data_inicio: dataInicio,
        p_data_fim: dataFim,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// CONTAS A PAGAR
// ============================================================================

/**
 * Obtém contas a pagar com filtros opcionais
 * @param {Object} filtros - { status, data_vencimento_inicio, data_vencimento_fim }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasPagar(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('contas_pagar')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.status) query = query.eq('status', filtros.status);
    if (filtros.data_vencimento_inicio) query = query.gte('data_vencimento', filtros.data_vencimento_inicio);
    if (filtros.data_vencimento_fim) query = query.lte('data_vencimento', filtros.data_vencimento_fim);

    const { data, error } = await query.order('data_vencimento');
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova conta a pagar
 * @param {Object} dados - { fornecedor_id, numero_documento, valor, data_vencimento, descricao }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createContaPagar(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('contas_pagar')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
        status: 'pendente',
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma conta a pagar
 * @param {string} id - ID da conta
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateContaPagar(id, dados) {
  try {
    const { data, error } = await supabase
      .from('contas_pagar')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Registra pagamento de uma conta
 * @param {string} id - ID da conta
 * @param {Object} dadosPagamento - { data_pagamento, valor_pago, conta_bancaria_id, numero_comprovante }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function pagarConta(id, dadosPagamento) {
  try {
    const { data, error } = await supabase
      .from('contas_pagar')
      .update({
        ...dadosPagamento,
        status: 'paga',
      })
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém contas a pagar vencidas
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasVencidas() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const hoje = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('contas_pagar')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'pendente')
      .lt('data_vencimento', hoje)
      .order('data_vencimento');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém contas a pagar vencendo em N dias
 * @param {number} dias - Número de dias
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasVencendo(dias) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const hoje = new Date();
    const futuro = new Date(hoje.getTime() + dias * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const hojeStr = hoje.toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('contas_pagar')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'pendente')
      .gte('data_vencimento', hojeStr)
      .lte('data_vencimento', futuro)
      .order('data_vencimento');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// CONTAS A RECEBER
// ============================================================================

/**
 * Obtém contas a receber com filtros opcionais
 * @param {Object} filtros - { status, data_vencimento_inicio, data_vencimento_fim }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasReceber(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('contas_receber')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.status) query = query.eq('status', filtros.status);
    if (filtros.data_vencimento_inicio) query = query.gte('data_vencimento', filtros.data_vencimento_inicio);
    if (filtros.data_vencimento_fim) query = query.lte('data_vencimento', filtros.data_vencimento_fim);

    const { data, error } = await query.order('data_vencimento');
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova conta a receber
 * @param {Object} dados - { cliente_id, numero_documento, valor, data_vencimento, descricao }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createContaReceber(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('contas_receber')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
        status: 'pendente',
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma conta a receber
 * @param {string} id - ID da conta
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateContaReceber(id, dados) {
  try {
    const { data, error } = await supabase
      .from('contas_receber')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Registra recebimento de uma conta
 * @param {string} id - ID da conta
 * @param {Object} dadosRecebimento - { data_recebimento, valor_recebido, conta_bancaria_id, numero_comprovante }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function receberConta(id, dadosRecebimento) {
  try {
    const { data, error } = await supabase
      .from('contas_receber')
      .update({
        ...dadosRecebimento,
        status: 'recebida',
      })
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém contas a receber vencidas
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasReceberVencidas() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const hoje = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('contas_receber')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'pendente')
      .lt('data_vencimento', hoje)
      .order('data_vencimento');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém contas a receber vencendo em N dias
 * @param {number} dias - Número de dias
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getContasReceberVencendo(dias) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const hoje = new Date();
    const futuro = new Date(hoje.getTime() + dias * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const hojeStr = hoje.toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('contas_receber')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'pendente')
      .gte('data_vencimento', hojeStr)
      .lte('data_vencimento', futuro)
      .order('data_vencimento');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// EXTRATOS BANCÁRIOS
// ============================================================================

/**
 * Obtém extratos de uma conta bancária
 * @param {string} contaBancariaId - ID da conta bancária
 * @param {Object} periodo - { data_inicio, data_fim }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getExtratos(contaBancariaId, periodo = {}) {
  try {
    let query = supabase
      .from('extratos_bancarios')
      .select('*')
      .eq('conta_bancaria_id', contaBancariaId);

    if (periodo.data_inicio) query = query.gte('data', periodo.data_inicio);
    if (periodo.data_fim) query = query.lte('data', periodo.data_fim);

    const { data, error } = await query.order('data', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Importa transações de extrato bancário
 * @param {string} contaBancariaId - ID da conta bancária
 * @param {Array} transacoes - Array de transações
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function importarExtrato(contaBancariaId, transacoes) {
  try {
    const dados = transacoes.map(t => ({
      ...t,
      conta_bancaria_id: contaBancariaId,
    }));

    const { data, error } = await supabase
      .from('extratos_bancarios')
      .insert(dados)
      .select();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Concilia uma transação de extrato com um lançamento contábil
 * @param {string} extratoId - ID do extrato
 * @param {string} lancamentoId - ID do lançamento
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function conciliarExtrato(extratoId, lancamentoId) {
  try {
    const { data, error } = await supabase
      .from('extratos_bancarios')
      .update({
        lancamento_id: lancamentoId,
        conciliado: true,
      })
      .eq('id', extratoId)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// APURAÇÕES FISCAIS
// ============================================================================

/**
 * Obtém apurações fiscais com filtros opcionais
 * @param {Object} filtros - { tipo, competencia, status }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getApuracoes(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('apuracoes_fiscais')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.tipo) query = query.eq('tipo', filtros.tipo);
    if (filtros.competencia) query = query.eq('competencia', filtros.competencia);
    if (filtros.status) query = query.eq('status', filtros.status);

    const { data, error } = await query.order('competencia', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova apuração fiscal
 * @param {Object} dados - { tipo, competencia, dados_calculo }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createApuracao(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('apuracoes_fiscais')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
        status: 'rascunho',
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma apuração fiscal
 * @param {string} id - ID da apuração
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateApuracao(id, dados) {
  try {
    const { data, error } = await supabase
      .from('apuracoes_fiscais')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Calcula IRPJ para um trimestre
 * @param {string} trimestre - Trimestre (1T, 2T, 3T, 4T) do ano
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function calcularIRPJ(trimestre) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('calcular_irpj', {
        p_tenant_id: profile.tenant_id,
        p_trimestre: trimestre,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Calcula CSLL para um trimestre
 * @param {string} trimestre - Trimestre (1T, 2T, 3T, 4T) do ano
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function calcularCSLL(trimestre) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('calcular_csll', {
        p_tenant_id: profile.tenant_id,
        p_trimestre: trimestre,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Calcula PIS para uma competência
 * @param {string} competencia - Competência (YYYY-MM)
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function calcularPIS(competencia) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('calcular_pis', {
        p_tenant_id: profile.tenant_id,
        p_competencia: competencia,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Calcula COFINS para uma competência
 * @param {string} competencia - Competência (YYYY-MM)
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function calcularCOFINS(competencia) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('calcular_cofins', {
        p_tenant_id: profile.tenant_id,
        p_competencia: competencia,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// RETENÇÕES
// ============================================================================

/**
 * Obtém retenções com filtros opcionais
 * @param {Object} filtros - { tipo, data_inicio, data_fim }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getRetencoes(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('retencoes')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.tipo) query = query.eq('tipo', filtros.tipo);
    if (filtros.data_inicio) query = query.gte('data', filtros.data_inicio);
    if (filtros.data_fim) query = query.lte('data', filtros.data_fim);

    const { data, error } = await query.order('data', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova retenção
 * @param {Object} dados - { tipo, documento_id, valor, aliquota, base_calculo }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createRetencao(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('retencoes')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma retenção
 * @param {string} id - ID da retenção
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateRetencao(id, dados) {
  try {
    const { data, error } = await supabase
      .from('retencoes')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// CALENDÁRIO DE OBRIGAÇÕES
// ============================================================================

/**
 * Obtém calendário de obrigações com filtros opcionais
 * @param {Object} filtros - { mes, ano, status }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getCalendario(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('calendario_obrigacoes')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.mes) query = query.eq('mes', filtros.mes);
    if (filtros.ano) query = query.eq('ano', filtros.ano);
    if (filtros.status) query = query.eq('status', filtros.status);

    const { data, error } = await query.order('data_vencimento');
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma obrigação do calendário
 * @param {string} id - ID da obrigação
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateObrigacao(id, dados) {
  try {
    const { data, error } = await supabase
      .from('calendario_obrigacoes')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém obrigações pendentes
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getObrigacoesPendentes() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('calendario_obrigacoes')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'pendente')
      .order('data_vencimento');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém obrigações vencidas
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getObrigacoesVencidas() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const hoje = new Date().toISOString().split('T')[0];

    const { data, error } = await supabase
      .from('calendario_obrigacoes')
      .select('*')
      .eq('tenant_id', profile.tenant_id)
      .eq('status', 'pendente')
      .lt('data_vencimento', hoje)
      .order('data_vencimento');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// PEDIDOS DE VENDA
// ============================================================================

/**
 * Obtém pedidos de venda com filtros opcionais
 * @param {Object} filtros - { status, cliente_id, data_inicio, data_fim }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getPedidos(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('pedidos_venda')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.status) query = query.eq('status', filtros.status);
    if (filtros.cliente_id) query = query.eq('cliente_id', filtros.cliente_id);
    if (filtros.data_inicio) query = query.gte('data_pedido', filtros.data_inicio);
    if (filtros.data_fim) query = query.lte('data_pedido', filtros.data_fim);

    const { data, error } = await query.order('data_pedido', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém um pedido de venda específico
 * @param {string} id - ID do pedido
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getPedido(id) {
  try {
    const { data, error } = await supabase
      .from('pedidos_venda')
      .select('*')
      .eq('id', id)
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo pedido de venda
 * @param {Object} dados - { cliente_id, data_pedido, data_entrega_prevista, valor_total }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createPedido(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('pedidos_venda')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
        status: 'aberto',
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza um pedido de venda
 * @param {string} id - ID do pedido
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updatePedido(id, dados) {
  try {
    const { data, error } = await supabase
      .from('pedidos_venda')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Converte um pedido de venda em nota fiscal
 * @param {string} id - ID do pedido
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function faturarPedido(id) {
  try {
    const { data, error } = await supabase
      .from('pedidos_venda')
      .update({ status: 'faturado' })
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// ITENS PEDIDO
// ============================================================================

/**
 * Obtém itens de um pedido de venda
 * @param {string} pedidoId - ID do pedido
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getItensPedido(pedidoId) {
  try {
    const { data, error } = await supabase
      .from('itens_pedido')
      .select('*')
      .eq('pedido_id', pedidoId)
      .order('sequencia');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria um novo item de pedido
 * @param {Object} dados - { pedido_id, produto_id, quantidade, preco_unitario }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createItemPedido(dados) {
  try {
    const { data, error } = await supabase
      .from('itens_pedido')
      .insert(dados)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Deleta um item de pedido
 * @param {string} id - ID do item
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function deleteItemPedido(id) {
  try {
    const { data, error } = await supabase
      .from('itens_pedido')
      .delete()
      .eq('id', id);

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// FOLHA CONTÁBIL
// ============================================================================

/**
 * Obtém folhas contábeis com filtros opcionais
 * @param {Object} filtros - { mes, ano, status }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getFolhas(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('folhas_contabeis')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.mes) query = query.eq('mes', filtros.mes);
    if (filtros.ano) query = query.eq('ano', filtros.ano);
    if (filtros.status) query = query.eq('status', filtros.status);

    const { data, error } = await query.order('ano', { ascending: false }).order('mes', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Cria uma nova folha contábil
 * @param {Object} dados - { mes, ano, dados_folha }
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function createFolha(dados) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('folhas_contabeis')
      .insert({
        ...dados,
        tenant_id: profile.tenant_id,
        status: 'rascunho',
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Atualiza uma folha contábil
 * @param {string} id - ID da folha
 * @param {Object} dados - Dados a atualizar
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function updateFolha(id, dados) {
  try {
    const { data, error } = await supabase
      .from('folhas_contabeis')
      .update(dados)
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Contabiliza uma folha de pagamento
 * @param {string} id - ID da folha
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function contabilizarFolha(id) {
  try {
    const { data, error } = await supabase
      .from('folhas_contabeis')
      .update({ status: 'contabilizada' })
      .eq('id', id)
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// LOG
// ============================================================================

/**
 * Registra um evento no log
 * @param {string} tipo - Tipo do evento
 * @param {string} descricao - Descrição do evento
 * @param {Object} dados - Dados adicionais do evento
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function logEvento(tipo, descricao, dados = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('logs')
      .insert({
        tenant_id: profile.tenant_id,
        usuario_id: profile.id,
        tipo,
        descricao,
        dados,
        data_criacao: new Date().toISOString(),
      })
      .select()
      .single();

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém logs com filtros opcionais
 * @param {Object} filtros - { tipo, usuario_id, data_inicio, data_fim }
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getLogs(filtros = {}) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    let query = supabase
      .from('logs')
      .select('*')
      .eq('tenant_id', profile.tenant_id);

    if (filtros.tipo) query = query.eq('tipo', filtros.tipo);
    if (filtros.usuario_id) query = query.eq('usuario_id', filtros.usuario_id);
    if (filtros.data_inicio) query = query.gte('data_criacao', filtros.data_inicio);
    if (filtros.data_fim) query = query.lte('data_criacao', filtros.data_fim);

    const { data, error } = await query.order('data_criacao', { ascending: false });
    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

// ============================================================================
// DASHBOARD
// ============================================================================

/**
 * Obtém resumo financeiro para um período
 * @param {string} periodo - Período (hoje, mes, trimestre, ano)
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getResumoFinanceiro(periodo = 'mes') {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('obter_resumo_financeiro', {
        p_tenant_id: profile.tenant_id,
        p_periodo: periodo,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém DRE simplificada
 * @param {string} dataInicio - Data inicial (YYYY-MM-DD)
 * @param {string} dataFim - Data final (YYYY-MM-DD)
 * @returns {Promise<{data: Object, error: Object}>}
 */
export async function getDRESimplificado(dataInicio, dataFim) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('calcular_dre_simplificado', {
        p_tenant_id: profile.tenant_id,
        p_data_inicio: dataInicio,
        p_data_fim: dataFim,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém fluxo de caixa projetado
 * @param {number} dias - Número de dias a projetar
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getFluxoCaixaProjetado(dias) {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .rpc('calcular_fluxo_caixa_projetado', {
        p_tenant_id: profile.tenant_id,
        p_dias: dias,
      });

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}

/**
 * Obtém saldos de todas as contas bancárias
 * @returns {Promise<{data: Array, error: Object}>}
 */
export async function getSaldosBancarios() {
  try {
    const { data: profile } = await getProfile();
    if (!profile) return { data: null, error: new Error('Usuário não autenticado') };

    const { data, error } = await supabase
      .from('contas_bancarias')
      .select('id, nome, saldo, tipo')
      .eq('tenant_id', profile.tenant_id)
      .order('nome');

    return { data, error };
  } catch (err) {
    return { data: null, error: err };
  }
}
