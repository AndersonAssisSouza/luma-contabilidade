-- ============================================================================
-- LUMA Contabilidade - Seed Data (Corrigido)
-- Compativel com o schema da migracao 001
-- ============================================================================

-- ============================================================================
-- CORRECAO: Funcoes RLS com SECURITY DEFINER
-- (necessario para que authenticated role acesse auth.users via funcoes)
-- ============================================================================

CREATE OR REPLACE FUNCTION obter_tenant_id()
RETURNS uuid AS $$
  SELECT tenant_id FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION obter_papel_usuario()
RETURNS text AS $$
  SELECT COALESCE(
    raw_user_meta_data->>'role',
    'operador'
  ) FROM auth.users WHERE id = auth.uid()
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION eh_usuario_do_tenant(p_tenant_id uuid)
RETURNS boolean AS $$
  SELECT obter_tenant_id() = p_tenant_id OR
         EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'role' = 'manager_global')
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION eh_manager_global()
RETURNS boolean AS $$
  SELECT obter_papel_usuario() = 'manager_global'
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION eh_master()
RETURNS boolean AS $$
  SELECT obter_papel_usuario() IN ('master', 'manager_global')
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION pode_escrever()
RETURNS boolean AS $$
  SELECT obter_papel_usuario() NOT IN ('visualizador')
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ============================================================================
-- CORRECAO: Politica adicional para tenants
-- Permite que usuarios vejam seu proprio tenant
-- ============================================================================

CREATE POLICY "Usuario le proprio tenant" ON tenants
  FOR SELECT USING (id = obter_tenant_id() OR eh_manager_global());

-- ============================================================================
-- SEED: Plano de Contas (funcao reutilizavel por tenant)
-- ============================================================================

CREATE OR REPLACE FUNCTION seed_plano_contas(p_tenant_id uuid)
RETURNS integer AS $$
DECLARE
  v_ativo uuid; v_ativo_circ uuid; v_ativo_ncirc uuid;
  v_caixa uuid; v_receber uuid; v_impostos uuid; v_adiant uuid; v_estoques uuid;
  v_imob uuid; v_intang uuid; v_deprec uuid;
  v_passivo uuid; v_pass_circ uuid; v_pass_ncirc uuid;
  v_fornec uuid; v_obrig_trab uuid; v_obrig_trib uuid; v_emprest_cp uuid; v_outras_obrig uuid;
  v_emprest_lp uuid; v_provisoes uuid;
  v_pl uuid; v_capital uuid; v_reservas uuid; v_lucros_acum uuid;
  v_receitas uuid; v_rec_oper uuid; v_rec_fin uuid;
  v_despesas uuid; v_desp_oper uuid; v_desp_fin uuid; v_custos uuid;
BEGIN
  -- 1. ATIVO
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1','ATIVO','ATIVO','DEVEDORA',1,NULL,false) RETURNING id INTO v_ativo;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1','Ativo Circulante','ATIVO','DEVEDORA',2,v_ativo,false) RETURNING id INTO v_ativo_circ;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.01','Caixa e Equivalentes','ATIVO','DEVEDORA',3,v_ativo_circ,false) RETURNING id INTO v_caixa;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.01.001','Caixa Geral','ATIVO','DEVEDORA',4,v_caixa,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.01.002','Banco Conta Movimento','ATIVO','DEVEDORA',4,v_caixa,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.01.003','Aplicacoes Financeiras','ATIVO','DEVEDORA',4,v_caixa,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.02','Contas a Receber','ATIVO','DEVEDORA',3,v_ativo_circ,false) RETURNING id INTO v_receber;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.02.001','Clientes Nacionais','ATIVO','DEVEDORA',4,v_receber,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.02.002','Duplicatas a Receber','ATIVO','DEVEDORA',4,v_receber,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.03','Impostos a Recuperar','ATIVO','DEVEDORA',3,v_ativo_circ,false) RETURNING id INTO v_impostos;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.03.001','IRRF a Compensar','ATIVO','DEVEDORA',4,v_impostos,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.03.002','PIS a Compensar','ATIVO','DEVEDORA',4,v_impostos,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.03.003','COFINS a Compensar','ATIVO','DEVEDORA',4,v_impostos,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.04','Adiantamentos','ATIVO','DEVEDORA',3,v_ativo_circ,false) RETURNING id INTO v_adiant;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.04.001','Adiantamento a Fornecedores','ATIVO','DEVEDORA',4,v_adiant,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.04.002','Adiantamento a Funcionarios','ATIVO','DEVEDORA',4,v_adiant,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.05','Estoques','ATIVO','DEVEDORA',3,v_ativo_circ,false) RETURNING id INTO v_estoques;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.05.001','Mercadorias para Revenda','ATIVO','DEVEDORA',4,v_estoques,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.1.05.002','Material de Consumo','ATIVO','DEVEDORA',4,v_estoques,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2','Ativo Nao Circulante','ATIVO','DEVEDORA',2,v_ativo,false) RETURNING id INTO v_ativo_ncirc;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.01','Imobilizado','ATIVO','DEVEDORA',3,v_ativo_ncirc,false) RETURNING id INTO v_imob;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.01.001','Moveis e Utensilios','ATIVO','DEVEDORA',4,v_imob,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.01.002','Equipamentos de Informatica','ATIVO','DEVEDORA',4,v_imob,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.01.003','Veiculos','ATIVO','DEVEDORA',4,v_imob,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.02','Intangivel','ATIVO','DEVEDORA',3,v_ativo_ncirc,false) RETURNING id INTO v_intang;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.02.001','Softwares e Licencas','ATIVO','DEVEDORA',4,v_intang,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.03','Depreciacao Acumulada','ATIVO','DEVEDORA',3,v_ativo_ncirc,false) RETURNING id INTO v_deprec;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.03.001','Deprec Moveis e Utensilios','ATIVO','DEVEDORA',4,v_deprec,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.03.002','Deprec Equip Informatica','ATIVO','DEVEDORA',4,v_deprec,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'1.2.03.003','Deprec Veiculos','ATIVO','DEVEDORA',4,v_deprec,true);

  -- 2. PASSIVO
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2','PASSIVO','PASSIVO','CREDORA',1,NULL,false) RETURNING id INTO v_passivo;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1','Passivo Circulante','PASSIVO','CREDORA',2,v_passivo,false) RETURNING id INTO v_pass_circ;

  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.01','Fornecedores','PASSIVO','CREDORA',3,v_pass_circ,false) RETURNING id INTO v_fornec;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.01.001','Fornecedores Nacionais','PASSIVO','CREDORA',4,v_fornec,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.01.002','Fornecedores Estrangeiros','PASSIVO','CREDORA',4,v_fornec,true);

  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.02','Obrigacoes Trabalhistas','PASSIVO','CREDORA',3,v_pass_circ,false) RETURNING id INTO v_obrig_trab;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.02.001','Salarios a Pagar','PASSIVO','CREDORA',4,v_obrig_trab,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.02.002','FGTS a Recolher','PASSIVO','CREDORA',4,v_obrig_trab,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.02.003','INSS a Recolher','PASSIVO','CREDORA',4,v_obrig_trab,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.02.004','Ferias a Pagar','PASSIVO','CREDORA',4,v_obrig_trab,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.02.005','13o Salario a Pagar','PASSIVO','CREDORA',4,v_obrig_trab,true);

  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.03','Obrigacoes Tributarias','PASSIVO','CREDORA',3,v_pass_circ,false) RETURNING id INTO v_obrig_trib;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.03.001','IRPJ a Recolher','PASSIVO','CREDORA',4,v_obrig_trib,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.03.002','CSLL a Recolher','PASSIVO','CREDORA',4,v_obrig_trib,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.03.003','PIS a Recolher','PASSIVO','CREDORA',4,v_obrig_trib,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.03.004','COFINS a Recolher','PASSIVO','CREDORA',4,v_obrig_trib,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.03.005','ISS a Recolher','PASSIVO','CREDORA',4,v_obrig_trib,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.03.006','ICMS a Recolher','PASSIVO','CREDORA',4,v_obrig_trib,true);

  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.04','Emprestimos CP','PASSIVO','CREDORA',3,v_pass_circ,false) RETURNING id INTO v_emprest_cp;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.04.001','Emprestimos Bancarios CP','PASSIVO','CREDORA',4,v_emprest_cp,true);

  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.05','Outras Obrigacoes','PASSIVO','CREDORA',3,v_pass_circ,false) RETURNING id INTO v_outras_obrig;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.05.001','Adiantamento de Clientes','PASSIVO','CREDORA',4,v_outras_obrig,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.1.05.002','Contas a Pagar Diversas','PASSIVO','CREDORA',4,v_outras_obrig,true);

  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.2','Passivo Nao Circulante','PASSIVO','CREDORA',2,v_passivo,false) RETURNING id INTO v_pass_ncirc;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.2.01','Emprestimos LP','PASSIVO','CREDORA',3,v_pass_ncirc,false) RETURNING id INTO v_emprest_lp;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.2.01.001','Emprestimos Bancarios LP','PASSIVO','CREDORA',4,v_emprest_lp,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.2.02','Provisoes','PASSIVO','CREDORA',3,v_pass_ncirc,false) RETURNING id INTO v_provisoes;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'2.2.02.001','Provisao para Contingencias','PASSIVO','CREDORA',4,v_provisoes,true);

  -- 3. PATRIMONIO LIQUIDO
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3','PATRIMONIO LIQUIDO','PATRIMONIO_LIQUIDO','CREDORA',1,NULL,false) RETURNING id INTO v_pl;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.1','Capital Social','PATRIMONIO_LIQUIDO','CREDORA',2,v_pl,false) RETURNING id INTO v_capital;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.1.01','Capital Social Subscrito','PATRIMONIO_LIQUIDO','CREDORA',3,v_capital,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.1.02','Capital Social a Integralizar','PATRIMONIO_LIQUIDO','DEVEDORA',3,v_capital,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.2','Reservas','PATRIMONIO_LIQUIDO','CREDORA',2,v_pl,false) RETURNING id INTO v_reservas;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.2.01','Reservas de Capital','PATRIMONIO_LIQUIDO','CREDORA',3,v_reservas,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.2.02','Reservas de Lucros','PATRIMONIO_LIQUIDO','CREDORA',3,v_reservas,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.3','Lucros ou Prejuizos Acumulados','PATRIMONIO_LIQUIDO','CREDORA',2,v_pl,false) RETURNING id INTO v_lucros_acum;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.3.01','Lucros Acumulados','PATRIMONIO_LIQUIDO','CREDORA',3,v_lucros_acum,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'3.3.02','Prejuizos Acumulados','PATRIMONIO_LIQUIDO','DEVEDORA',3,v_lucros_acum,true);

  -- 4. RECEITAS
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4','RECEITAS','RECEITA','CREDORA',1,NULL,false) RETURNING id INTO v_receitas;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.1','Receita Operacional','RECEITA','CREDORA',2,v_receitas,false) RETURNING id INTO v_rec_oper;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.1.01','Receita de Servicos','RECEITA','CREDORA',3,v_rec_oper,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.1.02','Receita de Vendas','RECEITA','CREDORA',3,v_rec_oper,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.1.03','Outras Receitas Operacionais','RECEITA','CREDORA',3,v_rec_oper,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.2','Receitas Financeiras','RECEITA','CREDORA',2,v_receitas,false) RETURNING id INTO v_rec_fin;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.2.01','Juros Ativos','RECEITA','CREDORA',3,v_rec_fin,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.2.02','Descontos Obtidos','RECEITA','CREDORA',3,v_rec_fin,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'4.2.03','Rendimentos de Aplicacoes','RECEITA','CREDORA',3,v_rec_fin,true);

  -- 5. DESPESAS
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5','DESPESAS','DESPESA','DEVEDORA',1,NULL,false) RETURNING id INTO v_despesas;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.1','Despesas Operacionais','DESPESA','DEVEDORA',2,v_despesas,false) RETURNING id INTO v_desp_oper;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.1.01','Despesas com Pessoal','DESPESA','DEVEDORA',3,v_desp_oper,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.1.02','Despesas Administrativas','DESPESA','DEVEDORA',3,v_desp_oper,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.1.03','Despesas Comerciais','DESPESA','DEVEDORA',3,v_desp_oper,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.1.04','Despesas Tributarias','DESPESA','DEVEDORA',3,v_desp_oper,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.2','Despesas Financeiras','DESPESA','DEVEDORA',2,v_despesas,false) RETURNING id INTO v_desp_fin;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.2.01','Juros Passivos','DESPESA','DEVEDORA',3,v_desp_fin,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.2.02','Descontos Concedidos','DESPESA','DEVEDORA',3,v_desp_fin,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.2.03','Tarifas Bancarias','DESPESA','DEVEDORA',3,v_desp_fin,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.3','Custos','DESPESA','DEVEDORA',2,v_despesas,false) RETURNING id INTO v_custos;
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.3.01','Custo dos Servicos Prestados','DESPESA','DEVEDORA',3,v_custos,true);
  INSERT INTO plano_contas(tenant_id,codigo,descricao,tipo,natureza,nivel,conta_pai_id,aceita_lancamento)
  VALUES(p_tenant_id,'5.3.02','Custo das Mercadorias Vendidas','DESPESA','DEVEDORA',3,v_custos,true);

  RETURN 90;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED: Categorias (funcao reutilizavel por tenant)
-- ============================================================================

CREATE OR REPLACE FUNCTION seed_categorias(p_tenant_id uuid)
RETURNS integer AS $$
BEGIN
  INSERT INTO categorias(tenant_id, nome, tipo, grupo, cor, status) VALUES
  (p_tenant_id, 'Honorarios Contabeis', 'RECEITA', 'Servicos', '#4CAF50', 'ATIVO'),
  (p_tenant_id, 'Consultoria Tributaria', 'RECEITA', 'Servicos', '#8BC34A', 'ATIVO'),
  (p_tenant_id, 'Assessoria Fiscal', 'RECEITA', 'Servicos', '#CDDC39', 'ATIVO'),
  (p_tenant_id, 'Abertura de Empresa', 'RECEITA', 'Servicos', '#009688', 'ATIVO'),
  (p_tenant_id, 'BPO Financeiro', 'RECEITA', 'Servicos', '#00BCD4', 'ATIVO'),
  (p_tenant_id, 'Folha de Pagamento', 'RECEITA', 'Servicos', '#03A9F4', 'ATIVO'),
  (p_tenant_id, 'Aluguel', 'DESPESA', 'Despesas Fixas', '#F44336', 'ATIVO'),
  (p_tenant_id, 'Energia Eletrica', 'DESPESA', 'Despesas Fixas', '#E91E63', 'ATIVO'),
  (p_tenant_id, 'Internet e Telefonia', 'DESPESA', 'Despesas Fixas', '#9C27B0', 'ATIVO'),
  (p_tenant_id, 'Software e Sistemas', 'DESPESA', 'Despesas Fixas', '#673AB7', 'ATIVO'),
  (p_tenant_id, 'Salarios e Encargos', 'DESPESA', 'Pessoal', '#3F51B5', 'ATIVO'),
  (p_tenant_id, 'Vale Transporte', 'DESPESA', 'Pessoal', '#2196F3', 'ATIVO'),
  (p_tenant_id, 'Vale Alimentacao', 'DESPESA', 'Pessoal', '#03A9F4', 'ATIVO'),
  (p_tenant_id, 'Material de Escritorio', 'DESPESA', 'Operacional', '#FF9800', 'ATIVO'),
  (p_tenant_id, 'Marketing e Publicidade', 'DESPESA', 'Comercial', '#FF5722', 'ATIVO'),
  (p_tenant_id, 'Impostos e Taxas', 'DESPESA', 'Tributario', '#795548', 'ATIVO'),
  (p_tenant_id, 'Tarifas Bancarias', 'DESPESA', 'Financeiro', '#607D8B', 'ATIVO'),
  (p_tenant_id, 'Juros e Multas', 'DESPESA', 'Financeiro', '#9E9E9E', 'ATIVO');
  RETURN 18;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SEED: Calendario de Obrigacoes Fiscais (funcao reutilizavel por tenant/ano)
-- ============================================================================

CREATE OR REPLACE FUNCTION seed_calendario_obrigacoes(p_tenant_id uuid, p_ano integer DEFAULT 2025)
RETURNS integer AS $$
DECLARE
  v_count integer := 0;
  v_mes integer;
  v_competencia date;
BEGIN
  FOR v_mes IN 1..12 LOOP
    v_competencia := make_date(p_ano, v_mes, 1);

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'DARF IRPJ', 'Imposto de Renda Pessoa Juridica - Lucro Presumido', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 20),
      'Contador', 'PENDENTE', 'Trimestral - verificar se competencia encerra trimestre');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'DARF CSLL', 'Contribuicao Social sobre Lucro Liquido', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 20),
      'Contador', 'PENDENTE', 'Lucro Presumido - trimestral');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'DARF PIS', 'PIS sobre Faturamento', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 25),
      'Contador', 'PENDENTE', 'Aliquota 0,65% Lucro Presumido');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'DARF COFINS', 'COFINS sobre Faturamento', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 25),
      'Contador', 'PENDENTE', 'Aliquota 3,00% Lucro Presumido');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'ISS', 'Imposto sobre Servicos', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 10),
      'Contador', 'PENDENTE', 'Verificar aliquota municipal');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'FGTS', 'Fundo de Garantia por Tempo de Servico', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 7),
      'RH/DP', 'PENDENTE', 'Recolhimento mensal obrigatorio');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'INSS', 'Contribuicao Previdenciaria', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 20),
      'RH/DP', 'PENDENTE', 'GPS - Guia da Previdencia Social');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'EFD Contribuicoes', 'Escrituracao Fiscal Digital das Contribuicoes', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 15),
      'Contador', 'PENDENTE', 'SPED - transmissao mensal');
    v_count := v_count + 1;

    INSERT INTO calendario_obrigacoes(tenant_id, obrigacao, descricao, competencia, data_vencimento, responsavel, status, observacoes)
    VALUES(p_tenant_id, 'DCTF', 'Declaracao de Debitos e Creditos Tributarios Federais', v_competencia,
      make_date(p_ano, CASE WHEN v_mes = 12 THEN 1 ELSE v_mes + 1 END, 15),
      'Contador', 'PENDENTE', 'Mensal - obrigacao acessoria federal');
    v_count := v_count + 1;

  END LOOP;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql;
