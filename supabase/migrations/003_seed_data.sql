-- Migration: 003_seed_data.sql
-- Purpose: Create seed data function for Brazilian accounting system (LUMA Contabilidade)
-- This includes Chart of Accounts (Plano de Contas), Categories, and Tax Obligations Calendar

-- ============================================================================
-- FUNCTION: seed_tenant_data
-- Description: Seeds complete chart of accounts, categories, and tax calendar
--              for a given tenant (multi-tenant support)
-- ============================================================================

CREATE OR REPLACE FUNCTION seed_tenant_data(p_tenant_id uuid)
RETURNS TABLE(
  accounts_inserted integer,
  categories_inserted integer,
  obligations_inserted integer
) AS $$
DECLARE
  v_accounts_inserted integer := 0;
  v_categories_inserted integer := 0;
  v_obligations_inserted integer := 0;

  -- Variables to store parent account IDs for hierarchy linking
  v_ativo_id uuid;
  v_ativo_circulante_id uuid;
  v_ativo_nao_circulante_id uuid;
  v_passivo_id uuid;
  v_passivo_circulante_id uuid;
  v_passivo_nao_circulante_id uuid;
  v_patrimonio_id uuid;
  v_receitas_id uuid;
  v_receitas_operacionais_id uuid;
  v_receitas_financeiras_id uuid;
  v_despesas_id uuid;
  v_despesas_operacionais_id uuid;
  v_despesas_tributarias_id uuid;
  v_despesas_financeiras_id uuid;

  -- Additional parent account IDs
  v_caixa_id uuid;
  v_contas_receber_id uuid;
  v_impostos_recuperar_id uuid;
  v_adiantamentos_id uuid;
  v_estoques_id uuid;
  v_imobilizado_id uuid;
  v_intangivel_id uuid;
  v_depreciacacao_id uuid;
  v_fornecedores_id uuid;
  v_obrigacoes_trabalhistas_id uuid;
  v_obrigacoes_tributarias_id uuid;
  v_emprestimos_cp_id uuid;
  v_outras_contas_pagar_id uuid;
  v_emprestimos_lp_id uuid;
  v_provisoes_id uuid;
  v_capital_social_id uuid;
  v_reservas_id uuid;
  v_lucros_acumulados_id uuid;
  v_despesas_operacionais_pessoal_id uuid;
  v_despesas_operacionais_administrativas_id uuid;
  v_despesas_operacionais_comerciais_id uuid;

BEGIN
  -- ========================================================================
  -- SECTION 1: INSERT CHART OF ACCOUNTS (PLANO DE CONTAS)
  -- ========================================================================

  -- 1. ATIVO (DEVEDORA) - Assets
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1', 'ATIVO', 'SINTETICA', 'DEVEDORA', 1, NULL, false)
  RETURNING id INTO v_ativo_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.1 Ativo Circulante
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1', 'Ativo Circulante', 'SINTETICA', 'DEVEDORA', 2, v_ativo_id, false)
  RETURNING id INTO v_ativo_circulante_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.1.01 Caixa e Equivalentes
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.01', 'Caixa e Equivalentes', 'SINTETICA', 'DEVEDORA', 3, v_ativo_circulante_id, false)
  RETURNING id INTO v_caixa_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.01.001', 'Caixa Geral', 'ANALITICA', 'DEVEDORA', 4, v_caixa_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.01.002', 'Bancos Conta Movimento', 'ANALITICA', 'DEVEDORA', 4, v_caixa_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.1.02 Contas a Receber
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.02', 'Contas a Receber', 'SINTETICA', 'DEVEDORA', 3, v_ativo_circulante_id, false)
  RETURNING id INTO v_contas_receber_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.02.001', 'Clientes', 'ANALITICA', 'DEVEDORA', 4, v_contas_receber_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.02.002', 'Duplicatas a Receber', 'ANALITICA', 'DEVEDORA', 4, v_contas_receber_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.1.03 Impostos a Recuperar
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.03', 'Impostos a Recuperar', 'SINTETICA', 'DEVEDORA', 3, v_ativo_circulante_id, false)
  RETURNING id INTO v_impostos_recuperar_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.03.001', 'IRRF a Compensar', 'ANALITICA', 'DEVEDORA', 4, v_impostos_recuperar_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.03.002', 'PIS/COFINS/CSLL Retidos', 'ANALITICA', 'DEVEDORA', 4, v_impostos_recuperar_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.1.04 Adiantamentos
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.04', 'Adiantamentos', 'SINTETICA', 'DEVEDORA', 3, v_ativo_circulante_id, false)
  RETURNING id INTO v_adiantamentos_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.04.001', 'Adiantamentos a Fornecedores', 'ANALITICA', 'DEVEDORA', 4, v_adiantamentos_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.04.002', 'Adiantamentos a Colaboradores', 'ANALITICA', 'DEVEDORA', 4, v_adiantamentos_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.1.05 Estoques
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.05', 'Estoques', 'SINTETICA', 'DEVEDORA', 3, v_ativo_circulante_id, false)
  RETURNING id INTO v_estoques_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.05.001', 'Estoque de Produtos Acabados', 'ANALITICA', 'DEVEDORA', 4, v_estoques_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.1.05.002', 'Estoque de Materiais', 'ANALITICA', 'DEVEDORA', 4, v_estoques_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.2 Ativo Não Circulante
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2', 'Ativo Não Circulante', 'SINTETICA', 'DEVEDORA', 2, v_ativo_id, false)
  RETURNING id INTO v_ativo_nao_circulante_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.2.01 Imobilizado
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.01', 'Imobilizado', 'SINTETICA', 'DEVEDORA', 3, v_ativo_nao_circulante_id, false)
  RETURNING id INTO v_imobilizado_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.01.001', 'Máquinas e Equipamentos', 'ANALITICA', 'DEVEDORA', 4, v_imobilizado_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.01.002', 'Móveis e Utensílios', 'ANALITICA', 'DEVEDORA', 4, v_imobilizado_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.01.003', 'Veículos', 'ANALITICA', 'DEVEDORA', 4, v_imobilizado_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.2.02 Intangível
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.02', 'Intangível', 'SINTETICA', 'DEVEDORA', 3, v_ativo_nao_circulante_id, false)
  RETURNING id INTO v_intangivel_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.02.001', 'Software e Licenças', 'ANALITICA', 'DEVEDORA', 4, v_intangivel_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.02.002', 'Marca e Patentes', 'ANALITICA', 'DEVEDORA', 4, v_intangivel_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 1.2.03 Depreciação Acumulada
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.03', 'Depreciação Acumulada', 'SINTETICA', 'CREDORA', 3, v_ativo_nao_circulante_id, false)
  RETURNING id INTO v_depreciacacao_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.03.001', 'Depreciação Acumulada - Equipamentos', 'ANALITICA', 'CREDORA', 4, v_depreciacacao_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.03.002', 'Depreciação Acumulada - Móveis', 'ANALITICA', 'CREDORA', 4, v_depreciacacao_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '1.2.03.003', 'Depreciação Acumulada - Veículos', 'ANALITICA', 'CREDORA', 4, v_depreciacacao_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2. PASSIVO (CREDORA) - Liabilities
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2', 'PASSIVO', 'SINTETICA', 'CREDORA', 1, NULL, false)
  RETURNING id INTO v_passivo_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.1 Passivo Circulante
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1', 'Passivo Circulante', 'SINTETICA', 'CREDORA', 2, v_passivo_id, false)
  RETURNING id INTO v_passivo_circulante_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.1.01 Fornecedores
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.01', 'Fornecedores', 'SINTETICA', 'CREDORA', 3, v_passivo_circulante_id, false)
  RETURNING id INTO v_fornecedores_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.01.001', 'Fornecedores Nacionais', 'ANALITICA', 'CREDORA', 4, v_fornecedores_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.01.002', 'Fornecedores Importação', 'ANALITICA', 'CREDORA', 4, v_fornecedores_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.1.02 Obrigações Trabalhistas
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.02', 'Obrigações Trabalhistas', 'SINTETICA', 'CREDORA', 3, v_passivo_circulante_id, false)
  RETURNING id INTO v_obrigacoes_trabalhistas_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.02.001', 'Salários a Pagar', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_trabalhistas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.02.002', 'FGTS a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_trabalhistas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.02.003', 'INSS a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_trabalhistas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.02.004', 'IRRF a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_trabalhistas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.1.03 Obrigações Tributárias
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.03', 'Obrigações Tributárias', 'SINTETICA', 'CREDORA', 3, v_passivo_circulante_id, false)
  RETURNING id INTO v_obrigacoes_tributarias_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.03.001', 'IRPJ a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_tributarias_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.03.002', 'CSLL a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_tributarias_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.03.003', 'PIS a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_tributarias_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.03.004', 'COFINS a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_tributarias_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.03.005', 'ISS a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_tributarias_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.03.006', 'Simples Nacional a Recolher', 'ANALITICA', 'CREDORA', 4, v_obrigacoes_tributarias_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.1.04 Empréstimos CP
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.04', 'Empréstimos Curto Prazo', 'SINTETICA', 'CREDORA', 3, v_passivo_circulante_id, false)
  RETURNING id INTO v_emprestimos_cp_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.04.001', 'Empréstimos Bancários CP', 'ANALITICA', 'CREDORA', 4, v_emprestimos_cp_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.1.05 Outras Contas a Pagar
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.05', 'Outras Contas a Pagar', 'SINTETICA', 'CREDORA', 3, v_passivo_circulante_id, false)
  RETURNING id INTO v_outras_contas_pagar_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.1.05.001', 'Contas a Pagar Diversas', 'ANALITICA', 'CREDORA', 4, v_outras_contas_pagar_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.2 Passivo Não Circulante
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.2', 'Passivo Não Circulante', 'SINTETICA', 'CREDORA', 2, v_passivo_id, false)
  RETURNING id INTO v_passivo_nao_circulante_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.2.01 Empréstimos LP
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.2.01', 'Empréstimos Longo Prazo', 'SINTETICA', 'CREDORA', 3, v_passivo_nao_circulante_id, false)
  RETURNING id INTO v_emprestimos_lp_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.2.01.001', 'Empréstimos Bancários LP', 'ANALITICA', 'CREDORA', 4, v_emprestimos_lp_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 2.2.02 Provisões
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.2.02', 'Provisões', 'SINTETICA', 'CREDORA', 3, v_passivo_nao_circulante_id, false)
  RETURNING id INTO v_provisoes_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '2.2.02.001', 'Provisão para Contingências', 'ANALITICA', 'CREDORA', 4, v_provisoes_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 3. PATRIMÔNIO LÍQUIDO (CREDORA) - Equity
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3', 'PATRIMONIO LIQUIDO', 'SINTETICA', 'CREDORA', 1, NULL, false)
  RETURNING id INTO v_patrimonio_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 3.1 Capital Social
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.1', 'Capital Social', 'SINTETICA', 'CREDORA', 2, v_patrimonio_id, false)
  RETURNING id INTO v_capital_social_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.1.01', 'Capital Social Integralizado', 'ANALITICA', 'CREDORA', 3, v_capital_social_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 3.2 Reservas
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.2', 'Reservas', 'SINTETICA', 'CREDORA', 2, v_patrimonio_id, false)
  RETURNING id INTO v_reservas_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.2.01', 'Reserva de Lucros', 'ANALITICA', 'CREDORA', 3, v_reservas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.2.02', 'Reserva Legal', 'ANALITICA', 'CREDORA', 3, v_reservas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 3.3 Lucros/Prejuízos Acumulados
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.3', 'Lucros/Prejuizos Acumulados', 'SINTETICA', 'CREDORA', 2, v_patrimonio_id, false)
  RETURNING id INTO v_lucros_acumulados_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.3.01', 'Lucros Acumulados', 'ANALITICA', 'CREDORA', 3, v_lucros_acumulados_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '3.3.02', 'Prejuízos Acumulados', 'ANALITICA', 'DEVEDORA', 3, v_lucros_acumulados_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 4. RECEITAS (CREDORA) - Revenue
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4', 'RECEITAS', 'SINTETICA', 'CREDORA', 1, NULL, false)
  RETURNING id INTO v_receitas_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 4.1 Receita Operacional
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.1', 'Receita Operacional', 'SINTETICA', 'CREDORA', 2, v_receitas_id, false)
  RETURNING id INTO v_receitas_operacionais_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.1.01', 'Receita de Serviços', 'SINTETICA', 'CREDORA', 3, v_receitas_operacionais_id, false);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.1.01.001', 'Receita de Serviços Diversos', 'ANALITICA', 'CREDORA', 4, v_receitas_operacionais_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.1.02', 'Receita de Vendas', 'SINTETICA', 'CREDORA', 3, v_receitas_operacionais_id, false);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.1.02.001', 'Vendas de Produtos', 'ANALITICA', 'CREDORA', 4, v_receitas_operacionais_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 4.2 Receitas Financeiras
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.2', 'Receitas Financeiras', 'SINTETICA', 'CREDORA', 2, v_receitas_id, false)
  RETURNING id INTO v_receitas_financeiras_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.2.01', 'Juros Recebidos', 'ANALITICA', 'CREDORA', 3, v_receitas_financeiras_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.2.02', 'Variação Cambial Positiva', 'ANALITICA', 'CREDORA', 3, v_receitas_financeiras_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 4.3 Outras Receitas
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.3', 'Outras Receitas', 'SINTETICA', 'CREDORA', 2, v_receitas_id, false);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '4.3.01', 'Receitas Diversas', 'ANALITICA', 'CREDORA', 3, v_receitas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5. DESPESAS (DEVEDORA) - Expenses
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5', 'DESPESAS', 'SINTETICA', 'DEVEDORA', 1, NULL, false)
  RETURNING id INTO v_despesas_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5.1 Despesas Operacionais
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1', 'Despesas Operacionais', 'SINTETICA', 'DEVEDORA', 2, v_despesas_id, false)
  RETURNING id INTO v_despesas_operacionais_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5.1.01 Pessoal
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.01', 'Despesas com Pessoal', 'SINTETICA', 'DEVEDORA', 3, v_despesas_operacionais_id, false)
  RETURNING id INTO v_despesas_operacionais_pessoal_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.01.001', 'Salários e Ordenados', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_pessoal_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.01.002', 'Encargos Sociais', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_pessoal_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.01.003', 'Benefícios - Vale Refeição/Transporte', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_pessoal_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5.1.02 Administrativas
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02', 'Despesas Administrativas', 'SINTETICA', 'DEVEDORA', 3, v_despesas_operacionais_id, false)
  RETURNING id INTO v_despesas_operacionais_administrativas_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.001', 'Aluguel', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.002', 'Energia Elétrica', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.003', 'Água e Saneamento', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.004', 'Internet e Telecom', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.005', 'Material de Escritório', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.006', 'Honorários Contábeis', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.007', 'Seguros', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.008', 'Manutenção e Reparos', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.02.009', 'Despesas com Tecnologia', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_administrativas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5.1.03 Comerciais
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.03', 'Despesas Comerciais', 'SINTETICA', 'DEVEDORA', 3, v_despesas_operacionais_id, false)
  RETURNING id INTO v_despesas_operacionais_comerciais_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.03.001', 'Marketing e Publicidade', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_comerciais_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.03.002', 'Comissões de Vendas', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_comerciais_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.1.03.003', 'Frete e Transporte', 'ANALITICA', 'DEVEDORA', 4, v_despesas_operacionais_comerciais_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5.2 Despesas Tributárias
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.2', 'Despesas Tributárias', 'SINTETICA', 'DEVEDORA', 2, v_despesas_id, false)
  RETURNING id INTO v_despesas_tributarias_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.2.01', 'Impostos e Taxas', 'ANALITICA', 'DEVEDORA', 3, v_despesas_tributarias_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5.3 Despesas Financeiras
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.3', 'Despesas Financeiras', 'SINTETICA', 'DEVEDORA', 2, v_despesas_id, false)
  RETURNING id INTO v_despesas_financeiras_id;
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.3.01', 'Juros Pagos', 'ANALITICA', 'DEVEDORA', 3, v_despesas_financeiras_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.3.02', 'Variação Cambial Negativa', 'ANALITICA', 'DEVEDORA', 3, v_despesas_financeiras_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.3.03', 'Despesas Bancárias', 'ANALITICA', 'DEVEDORA', 3, v_despesas_financeiras_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- 5.4 Depreciação e Amortização
  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.4', 'Depreciação e Amortização', 'SINTETICA', 'DEVEDORA', 2, v_despesas_id, false);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.4.01', 'Depreciação do Período', 'ANALITICA', 'DEVEDORA', 3, v_despesas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  INSERT INTO contas (tenant_id, codigo, descricao, tipo, natureza, nivel, conta_pai_id, aceita_lancamento)
  VALUES (p_tenant_id, '5.4.02', 'Amortização Intangível', 'ANALITICA', 'DEVEDORA', 3, v_despesas_id, true);
  v_accounts_inserted := v_accounts_inserted + 1;

  -- ========================================================================
  -- SECTION 2: INSERT FINANCIAL CATEGORIES
  -- ========================================================================

  -- RECEITA Categories
  INSERT INTO categorias (tenant_id, nome, tipo, descricao, ativa)
  VALUES
    (p_tenant_id, 'Serviços Prestados', 'RECEITA', 'Receita de serviços profissionais prestados', true),
    (p_tenant_id, 'Venda de Produtos', 'RECEITA', 'Receita de venda de produtos', true),
    (p_tenant_id, 'Receitas Financeiras', 'RECEITA', 'Juros, rendimentos e variação cambial positiva', true),
    (p_tenant_id, 'Outras Receitas', 'RECEITA', 'Outras receitas não operacionais', true);
  v_categories_inserted := v_categories_inserted + 4;

  -- DESPESA Categories
  INSERT INTO categorias (tenant_id, nome, tipo, descricao, ativa)
  VALUES
    (p_tenant_id, 'Salários e Encargos', 'DESPESA', 'Salários, encargos sociais e benefícios', true),
    (p_tenant_id, 'Aluguel', 'DESPESA', 'Despesa de aluguel da sede/filiais', true),
    (p_tenant_id, 'Energia/Água/Internet', 'DESPESA', 'Serviços de utilidade pública', true),
    (p_tenant_id, 'Material de Escritório', 'DESPESA', 'Consumíveis e material de expediente', true),
    (p_tenant_id, 'Serviços de Terceiros (PJ)', 'DESPESA', 'Pagamentos para prestadores pessoa jurídica', true),
    (p_tenant_id, 'Honorários Contábeis', 'DESPESA', 'Despesa com serviços contábeis', true),
    (p_tenant_id, 'Impostos e Taxas', 'DESPESA', 'Impostos, taxas e contribuições', true),
    (p_tenant_id, 'Despesas Financeiras', 'DESPESA', 'Juros, juros bancários e encargos financeiros', true),
    (p_tenant_id, 'Marketing', 'DESPESA', 'Despesas com marketing, publicidade e propaganda', true),
    (p_tenant_id, 'Transporte', 'DESPESA', 'Combustível, passagens, frete e logística', true),
    (p_tenant_id, 'Alimentação', 'DESPESA', 'Refeições, lanches e café', true),
    (p_tenant_id, 'Manutenção', 'DESPESA', 'Manutenção de equipamentos e instalações', true),
    (p_tenant_id, 'Seguros', 'DESPESA', 'Prêmios de seguros diversos', true),
    (p_tenant_id, 'Tecnologia', 'DESPESA', 'Software, hardware e suporte técnico', true),
    (p_tenant_id, 'Outras Despesas', 'DESPESA', 'Outras despesas não classificadas', true);
  v_categories_inserted := v_categories_inserted + 15;

  -- ========================================================================
  -- SECTION 3: INSERT TAX OBLIGATIONS CALENDAR FOR 2026
  -- ========================================================================

  -- January 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-01-25', 'MENSAL', 1, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de janeiro'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-01-25', 'MENSAL', 1, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de janeiro'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-01-15', 'MENSAL', 1, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de janeiro (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-01-20', 'MENSAL', 1, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de janeiro'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-01-20', 'MENSAL', 1, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de janeiro');
  v_obligations_inserted := v_obligations_inserted + 5;

  -- February 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'DIRF', 'DIRF - Declaração do Imposto de Renda Retido na Fonte', '2026-02-27', 'ANUAL', 2, NULL, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Último dia útil de fevereiro'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-02-25', 'MENSAL', 2, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de fevereiro'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-02-25', 'MENSAL', 2, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de fevereiro'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-02-15', 'MENSAL', 2, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de fevereiro (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-02-20', 'MENSAL', 2, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de fevereiro'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-02-20', 'MENSAL', 2, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de fevereiro');
  v_obligations_inserted := v_obligations_inserted + 6;

  -- March 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'IRPJ', 'IRPJ - Imposto de Renda Pessoa Jurídica (Q1)', '2026-03-31', 'TRIMESTRAL', 3, 1, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'CSLL', 'CSLL - Contribuição Social sobre o Lucro Líquido (Q1)', '2026-03-31', 'TRIMESTRAL', 3, 1, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-03-25', 'MENSAL', 3, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de março'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-03-25', 'MENSAL', 3, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de março'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-03-15', 'MENSAL', 3, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de março (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-03-20', 'MENSAL', 3, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de março'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-03-20', 'MENSAL', 3, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de março');
  v_obligations_inserted := v_obligations_inserted + 7;

  -- April 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'DCTF', 'DCTF - Declaração de Débitos e Créditos Tributários Federais (Q1)', '2026-05-15', 'TRIMESTRAL', 5, 1, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Vencimento 15 do 2º mês após o trimestre'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-04-25', 'MENSAL', 4, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de abril'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-04-25', 'MENSAL', 4, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de abril'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-04-15', 'MENSAL', 4, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de abril (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-04-20', 'MENSAL', 4, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de abril'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-04-20', 'MENSAL', 4, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de abril');
  v_obligations_inserted := v_obligations_inserted + 6;

  -- May 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'ECD', 'ECD/SPED - Escrituração Contábil Digital (até 31/05)', '2026-05-31', 'ANUAL', 5, NULL, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Último dia útil de maio'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-05-25', 'MENSAL', 5, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de maio'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-05-25', 'MENSAL', 5, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de maio'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-05-15', 'MENSAL', 5, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de maio (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-05-20', 'MENSAL', 5, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de maio'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-05-20', 'MENSAL', 5, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de maio');
  v_obligations_inserted := v_obligations_inserted + 6;

  -- June 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-06-25', 'MENSAL', 6, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de junho'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-06-25', 'MENSAL', 6, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de junho'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-06-15', 'MENSAL', 6, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de junho (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-06-20', 'MENSAL', 6, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de junho'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-06-20', 'MENSAL', 6, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de junho');
  v_obligations_inserted := v_obligations_inserted + 5;

  -- July 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'ECF', 'ECF - Escrituração Contábil Fiscal (até 31/07)', '2026-07-31', 'ANUAL', 7, NULL, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Último dia útil de julho'),
    (p_tenant_id, 'IRPJ', 'IRPJ - Imposto de Renda Pessoa Jurídica (Q2)', '2026-07-31', 'TRIMESTRAL', 7, 2, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'CSLL', 'CSLL - Contribuição Social sobre o Lucro Líquido (Q2)', '2026-07-31', 'TRIMESTRAL', 7, 2, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-07-25', 'MENSAL', 7, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de julho'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-07-25', 'MENSAL', 7, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de julho'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-07-15', 'MENSAL', 7, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de julho (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-07-20', 'MENSAL', 7, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de julho'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-07-20', 'MENSAL', 7, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de julho');
  v_obligations_inserted := v_obligations_inserted + 8;

  -- August 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'DCTF', 'DCTF - Declaração de Débitos e Créditos Tributários Federais (Q2)', '2026-09-15', 'TRIMESTRAL', 9, 2, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Vencimento 15 do 2º mês após o trimestre'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-08-25', 'MENSAL', 8, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de agosto'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-08-25', 'MENSAL', 8, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de agosto'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-08-15', 'MENSAL', 8, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de agosto (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-08-20', 'MENSAL', 8, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de agosto'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-08-20', 'MENSAL', 8, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de agosto');
  v_obligations_inserted := v_obligations_inserted + 6;

  -- September 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-09-25', 'MENSAL', 9, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de setembro'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-09-25', 'MENSAL', 9, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de setembro'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-09-15', 'MENSAL', 9, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de setembro (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-09-20', 'MENSAL', 9, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de setembro'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-09-20', 'MENSAL', 9, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de setembro');
  v_obligations_inserted := v_obligations_inserted + 5;

  -- October 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'IRPJ', 'IRPJ - Imposto de Renda Pessoa Jurídica (Q3)', '2026-10-31', 'TRIMESTRAL', 10, 3, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'CSLL', 'CSLL - Contribuição Social sobre o Lucro Líquido (Q3)', '2026-10-31', 'TRIMESTRAL', 10, 3, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-10-25', 'MENSAL', 10, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de outubro'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-10-25', 'MENSAL', 10, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de outubro'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-10-15', 'MENSAL', 10, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de outubro (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-10-20', 'MENSAL', 10, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de outubro'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-10-20', 'MENSAL', 10, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de outubro');
  v_obligations_inserted := v_obligations_inserted + 7;

  -- November 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'DCTF', 'DCTF - Declaração de Débitos e Créditos Tributários Federais (Q3)', '2026-11-15', 'TRIMESTRAL', 11, 3, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Vencimento 15 do 2º mês após o trimestre'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-11-25', 'MENSAL', 11, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de novembro'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-11-25', 'MENSAL', 11, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de novembro'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-11-15', 'MENSAL', 11, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de novembro (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-11-20', 'MENSAL', 11, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de novembro'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-11-20', 'MENSAL', 11, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de novembro');
  v_obligations_inserted := v_obligations_inserted + 6;

  -- December 2026
  INSERT INTO obrigacoes (tenant_id, tipo, descricao, data_vencimento, periodicidade, mes, trimestre, ano, responsavel, status, observacoes)
  VALUES
    (p_tenant_id, 'IRPJ', 'IRPJ - Imposto de Renda Pessoa Jurídica (Q4)', '2026-12-31', 'TRIMESTRAL', 12, 4, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'CSLL', 'CSLL - Contribuição Social sobre o Lucro Líquido (Q4)', '2026-12-31', 'TRIMESTRAL', 12, 4, 2026, 'CONTADOR_CRC', 'PENDENTE', 'Lucro Presumido - Último dia útil do mês subsequente ao trimestre'),
    (p_tenant_id, 'PIS', 'PIS - Programação de Integração Social', '2026-12-25', 'MENSAL', 12, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de dezembro'),
    (p_tenant_id, 'COFINS', 'COFINS - Contribuição para Financiamento da Seguridade Social', '2026-12-25', 'MENSAL', 12, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 25 de dezembro'),
    (p_tenant_id, 'ISS', 'ISS - Imposto Sobre Serviços (se aplicável)', '2026-12-15', 'MENSAL', 12, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 15 de dezembro (varia por município)'),
    (p_tenant_id, 'FGTS', 'FGTS - Fundo de Garantia do Tempo de Serviço', '2026-12-20', 'MENSAL', 12, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de dezembro'),
    (p_tenant_id, 'INSS', 'INSS - Contribuição Previdenciária Patronal', '2026-12-20', 'MENSAL', 12, NULL, 2026, 'AGENTE_DIGITAL', 'PENDENTE', 'Vencimento em 20 de dezembro');
  v_obligations_inserted := v_obligations_inserted + 7;

  -- Return counts
  RETURN QUERY SELECT v_accounts_inserted, v_categories_inserted, v_obligations_inserted;

END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================
GRANT EXECUTE ON FUNCTION seed_tenant_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION seed_tenant_data(uuid) TO service_role;

-- ============================================================================
-- COMMENT AND DOCUMENTATION
-- ============================================================================
COMMENT ON FUNCTION seed_tenant_data(p_tenant_id uuid) IS
'Seeds complete chart of accounts, categories, and tax obligations calendar for a given tenant.
Returns a table with counts of inserted accounts, categories, and obligations.
Usage: SELECT * FROM seed_tenant_data(tenant_uuid);';
