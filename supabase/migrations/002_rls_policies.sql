-- =====================================================
-- LUMA Contabilidade - RLS Policies Migration
-- Multi-tenant Row Level Security Configuration
-- =====================================================

-- =====================================================
-- HELPERS: Functions for tenant isolation and role checks
-- =====================================================

CREATE OR REPLACE FUNCTION obter_tenant_id()
RETURNS UUID AS $$
  SELECT tenant_id FROM profiles WHERE id = auth.uid()
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION eh_usuario_do_tenant(p_tenant_id UUID)
RETURNS BOOLEAN AS $$
  SELECT obter_tenant_id() = p_tenant_id OR
         EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'manager_global')
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION obter_papel_usuario()
RETURNS TEXT AS $$
  SELECT COALESCE(
    raw_user_meta_data->>'role',
    'operador'
  ) FROM auth.users WHERE id = auth.uid()
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION eh_manager_global()
RETURNS BOOLEAN AS $$
  SELECT obter_papel_usuario() = 'manager_global'
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION eh_master()
RETURNS BOOLEAN AS $$
  SELECT obter_papel_usuario() IN ('master', 'manager_global')
$$ LANGUAGE SQL STABLE;

CREATE OR REPLACE FUNCTION pode_escrever()
RETURNS BOOLEAN AS $$
  SELECT obter_papel_usuario() NOT IN ('visualizador')
$$ LANGUAGE SQL STABLE;

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE plano_contas ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE centros_custo ENABLE ROW LEVEL SECURITY;
ALTER TABLE contas_bancarias ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos_servicos ENABLE ROW LEVEL SECURITY;
ALTER TABLE notas_fiscais ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_nota_fiscal ENABLE ROW LEVEL SECURITY;
ALTER TABLE lancamentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE contas_pagar ENABLE ROW LEVEL SECURITY;
ALTER TABLE contas_receber ENABLE ROW LEVEL SECURITY;
ALTER TABLE extratos_bancarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE apuracoes_fiscais ENABLE ROW LEVEL SECURITY;
ALTER TABLE retencoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendario_obrigacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos_venda ENABLE ROW LEVEL SECURITY;
ALTER TABLE itens_pedido_venda ENABLE ROW LEVEL SECURITY;
ALTER TABLE folha_contabil ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_eventos ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PROFILES TABLE POLICIES
-- =====================================================

-- Usuários autenticados podem ler seu próprio perfil
CREATE POLICY "Ler próprio perfil" ON profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Managers podem ler todos os perfis do seu tenant
CREATE POLICY "Master e Manager leem perfis do tenant" ON profiles
  FOR SELECT
  USING (eh_master() OR obter_tenant_id() = tenant_id);

-- Usuários podem atualizar seu próprio perfil
CREATE POLICY "Atualizar próprio perfil" ON profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Master e Manager Global podem atualizar qualquer perfil
CREATE POLICY "Master e Manager atualizam perfis" ON profiles
  FOR UPDATE
  USING (eh_master())
  WITH CHECK (eh_master());

-- Apenas Manager Global pode deletar perfis
CREATE POLICY "Manager Global deleta perfis" ON profiles
  FOR DELETE
  USING (eh_manager_global());

-- =====================================================
-- TENANTS TABLE POLICIES
-- =====================================================

-- Apenas Manager Global pode ver todos os tenants
CREATE POLICY "Manager Global lê todos tenants" ON tenants
  FOR SELECT
  USING (eh_manager_global());

-- Manager Global pode inserir novos tenants
CREATE POLICY "Manager Global insere tenants" ON tenants
  FOR INSERT
  WITH CHECK (eh_manager_global());

-- Manager Global pode atualizar tenants
CREATE POLICY "Manager Global atualiza tenants" ON tenants
  FOR UPDATE
  USING (eh_manager_global())
  WITH CHECK (eh_manager_global());

-- Manager Global pode deletar tenants
CREATE POLICY "Manager Global deleta tenants" ON tenants
  FOR DELETE
  USING (eh_manager_global());

-- =====================================================
-- PLANO DE CONTAS POLICIES
-- =====================================================

-- Leitura: Usuários autenticados do tenant
CREATE POLICY "Ler plano de contas do tenant" ON plano_contas
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

-- Inserção: Usuários com permissão de escrita
CREATE POLICY "Inserir plano de contas" ON plano_contas
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

-- Atualização: Usuários com permissão de escrita
CREATE POLICY "Atualizar plano de contas" ON plano_contas
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

-- Deleção: Apenas master
CREATE POLICY "Deletar plano de contas" ON plano_contas
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- CATEGORIAS POLICIES
-- =====================================================

CREATE POLICY "Ler categorias do tenant" ON categorias
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir categorias" ON categorias
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar categorias" ON categorias
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar categorias" ON categorias
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- CENTROS DE CUSTO POLICIES
-- =====================================================

CREATE POLICY "Ler centros de custo do tenant" ON centros_custo
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir centros de custo" ON centros_custo
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar centros de custo" ON centros_custo
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar centros de custo" ON centros_custo
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- CONTAS BANCÁRIAS POLICIES
-- =====================================================

CREATE POLICY "Ler contas bancárias do tenant" ON contas_bancarias
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir contas bancárias" ON contas_bancarias
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar contas bancárias" ON contas_bancarias
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar contas bancárias" ON contas_bancarias
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- CLIENTES POLICIES
-- =====================================================

CREATE POLICY "Ler clientes do tenant" ON clientes
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir clientes" ON clientes
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar clientes" ON clientes
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar clientes" ON clientes
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- FORNECEDORES POLICIES
-- =====================================================

CREATE POLICY "Ler fornecedores do tenant" ON fornecedores
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir fornecedores" ON fornecedores
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar fornecedores" ON fornecedores
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar fornecedores" ON fornecedores
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- PRODUTOS E SERVIÇOS POLICIES
-- =====================================================

CREATE POLICY "Ler produtos e serviços do tenant" ON produtos_servicos
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir produtos e serviços" ON produtos_servicos
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar produtos e serviços" ON produtos_servicos
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar produtos e serviços" ON produtos_servicos
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- NOTAS FISCAIS POLICIES
-- =====================================================

CREATE POLICY "Ler notas fiscais do tenant" ON notas_fiscais
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir notas fiscais" ON notas_fiscais
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar notas fiscais" ON notas_fiscais
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar notas fiscais" ON notas_fiscais
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- ITENS DE NOTA FISCAL POLICIES
-- =====================================================

CREATE POLICY "Ler itens de nota fiscal do tenant" ON itens_nota_fiscal
  FOR SELECT
  USING (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM notas_fiscais WHERE id = nota_fiscal_id)
    )
  );

CREATE POLICY "Inserir itens de nota fiscal" ON itens_nota_fiscal
  FOR INSERT
  WITH CHECK (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM notas_fiscais WHERE id = nota_fiscal_id)
    ) AND pode_escrever()
  );

CREATE POLICY "Atualizar itens de nota fiscal" ON itens_nota_fiscal
  FOR UPDATE
  USING (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM notas_fiscais WHERE id = nota_fiscal_id)
    ) AND pode_escrever()
  )
  WITH CHECK (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM notas_fiscais WHERE id = nota_fiscal_id)
    ) AND pode_escrever()
  );

CREATE POLICY "Deletar itens de nota fiscal" ON itens_nota_fiscal
  FOR DELETE
  USING (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM notas_fiscais WHERE id = nota_fiscal_id)
    ) AND eh_master()
  );

-- =====================================================
-- LANÇAMENTOS POLICIES
-- =====================================================

CREATE POLICY "Ler lançamentos do tenant" ON lancamentos
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir lançamentos" ON lancamentos
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar lançamentos" ON lancamentos
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar lançamentos" ON lancamentos
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- CONTAS A PAGAR POLICIES
-- =====================================================

CREATE POLICY "Ler contas a pagar do tenant" ON contas_pagar
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir contas a pagar" ON contas_pagar
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar contas a pagar" ON contas_pagar
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar contas a pagar" ON contas_pagar
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- CONTAS A RECEBER POLICIES
-- =====================================================

CREATE POLICY "Ler contas a receber do tenant" ON contas_receber
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir contas a receber" ON contas_receber
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar contas a receber" ON contas_receber
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar contas a receber" ON contas_receber
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- EXTRATOS BANCÁRIOS POLICIES
-- =====================================================

CREATE POLICY "Ler extratos bancários do tenant" ON extratos_bancarios
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir extratos bancários" ON extratos_bancarios
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar extratos bancários" ON extratos_bancarios
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar extratos bancários" ON extratos_bancarios
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- APURAÇÕES FISCAIS POLICIES
-- =====================================================

CREATE POLICY "Ler apurações fiscais do tenant" ON apuracoes_fiscais
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir apurações fiscais" ON apuracoes_fiscais
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar apurações fiscais" ON apuracoes_fiscais
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar apurações fiscais" ON apuracoes_fiscais
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- RETENÇÕES POLICIES
-- =====================================================

CREATE POLICY "Ler retenções do tenant" ON retencoes
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir retenções" ON retencoes
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar retenções" ON retencoes
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar retenções" ON retencoes
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- CALENDÁRIO DE OBRIGAÇÕES POLICIES
-- =====================================================

CREATE POLICY "Ler calendário de obrigações do tenant" ON calendario_obrigacoes
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir calendário de obrigações" ON calendario_obrigacoes
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar calendário de obrigações" ON calendario_obrigacoes
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar calendário de obrigações" ON calendario_obrigacoes
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- PEDIDOS DE VENDA POLICIES
-- =====================================================

CREATE POLICY "Ler pedidos de venda do tenant" ON pedidos_venda
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir pedidos de venda" ON pedidos_venda
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar pedidos de venda" ON pedidos_venda
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar pedidos de venda" ON pedidos_venda
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- ITENS DE PEDIDO DE VENDA POLICIES
-- =====================================================

CREATE POLICY "Ler itens de pedido de venda do tenant" ON itens_pedido_venda
  FOR SELECT
  USING (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM pedidos_venda WHERE id = pedido_venda_id)
    )
  );

CREATE POLICY "Inserir itens de pedido de venda" ON itens_pedido_venda
  FOR INSERT
  WITH CHECK (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM pedidos_venda WHERE id = pedido_venda_id)
    ) AND pode_escrever()
  );

CREATE POLICY "Atualizar itens de pedido de venda" ON itens_pedido_venda
  FOR UPDATE
  USING (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM pedidos_venda WHERE id = pedido_venda_id)
    ) AND pode_escrever()
  )
  WITH CHECK (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM pedidos_venda WHERE id = pedido_venda_id)
    ) AND pode_escrever()
  );

CREATE POLICY "Deletar itens de pedido de venda" ON itens_pedido_venda
  FOR DELETE
  USING (
    eh_usuario_do_tenant(
      (SELECT tenant_id FROM pedidos_venda WHERE id = pedido_venda_id)
    ) AND eh_master()
  );

-- =====================================================
-- FOLHA CONTÁBIL POLICIES
-- =====================================================

CREATE POLICY "Ler folha contábil do tenant" ON folha_contabil
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

CREATE POLICY "Inserir folha contábil" ON folha_contabil
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Atualizar folha contábil" ON folha_contabil
  FOR UPDATE
  USING (eh_usuario_do_tenant(tenant_id) AND pode_escrever())
  WITH CHECK (eh_usuario_do_tenant(tenant_id) AND pode_escrever());

CREATE POLICY "Deletar folha contábil" ON folha_contabil
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- LOG DE EVENTOS POLICIES
-- =====================================================

-- Todos os usuários autenticados podem inserir logs
CREATE POLICY "Inserir eventos de log" ON log_eventos
  FOR INSERT
  WITH CHECK (eh_usuario_do_tenant(tenant_id));

-- Todos os usuários autenticados podem ler logs do seu tenant
CREATE POLICY "Ler eventos de log do tenant" ON log_eventos
  FOR SELECT
  USING (eh_usuario_do_tenant(tenant_id));

-- Apenas master pode deletar logs
CREATE POLICY "Deletar eventos de log" ON log_eventos
  FOR DELETE
  USING (eh_usuario_do_tenant(tenant_id) AND eh_master());

-- =====================================================
-- END OF RLS POLICIES
-- =====================================================
