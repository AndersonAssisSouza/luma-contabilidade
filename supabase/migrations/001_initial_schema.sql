-- ============================================================
-- LUMA CONTABILIDADE — Migration 001: Schema Inicial
-- Arquitetura multi-tenant com isolamento por empresa (tenant)
-- Compatível com LUMA RH (mesmo padrão de tenants/profiles)
-- ============================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- TABELA: tenants (empresas clientes)
-- Mesma estrutura do LUMA RH para compatibilidade
-- ============================================================
CREATE TABLE tenants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nome text NOT NULL,
    slug text UNIQUE NOT NULL,
    cnpj text UNIQUE,
    inscricao_estadual text,
    inscricao_municipal text,
    email_admin text NOT NULL,
    telefone text,
    endereco_logradouro text,
    endereco_numero text,
    endereco_complemento text,
    endereco_bairro text,
    endereco_cidade text,
    endereco_uf text,
    endereco_cep text,
    -- Dados contábeis
    regime_tributario text NOT NULL DEFAULT 'LUCRO_PRESUMIDO', -- SIMPLES | LUCRO_PRESUMIDO | LUCRO_REAL
    atividade_principal text, -- SERVICOS | COMERCIO | INDUSTRIA | MISTO
    codigo_cnae text,
    percentual_presuncao_irpj numeric(5,2) DEFAULT 32.00, -- 8% comércio, 32% serviços
    percentual_presuncao_csll numeric(5,2) DEFAULT 32.00, -- 12% comércio, 32% serviços
    -- Integração
    conta_azul_client_id text,
    conta_azul_client_secret text,
    conta_azul_access_token text,
    conta_azul_refresh_token text,
    conta_azul_token_expiry timestamptz,
    luma_rh_tenant_id uuid, -- ID do tenant no LUMA RH (para integração)
    -- Controle
    plano text NOT NULL DEFAULT 'TRIAL',
    status text NOT NULL DEFAULT 'ATIVO',
    max_usuarios integer DEFAULT 10,
    config jsonb DEFAULT '{}',
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: profiles (usuários — estende auth.users)
-- ============================================================
CREATE TABLE profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
    nome text NOT NULL,
    email text NOT NULL UNIQUE,
    role text NOT NULL DEFAULT 'operador',
    -- roles: 'manager_global' | 'master' | 'contador' | 'operador' | 'visualizador'
    status text NOT NULL DEFAULT 'ATIVO',
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: plano_contas (Plano de Contas Contábil)
-- ============================================================
CREATE TABLE plano_contas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    codigo text NOT NULL,           -- Ex: 1.1.01.001
    descricao text NOT NULL,        -- Ex: Caixa Geral
    tipo text NOT NULL,             -- ATIVO | PASSIVO | RECEITA | DESPESA | PATRIMONIO_LIQUIDO
    natureza text NOT NULL,         -- DEVEDORA | CREDORA
    nivel integer NOT NULL,         -- 1=grupo, 2=subgrupo, 3=conta, 4=subconta
    conta_pai_id uuid REFERENCES plano_contas(id),
    aceita_lancamento boolean DEFAULT true, -- false = conta sintética (agrupadora)
    status text DEFAULT 'ATIVA',    -- ATIVA | INATIVA
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, codigo)
);

-- ============================================================
-- TABELA: categorias (Categorias financeiras)
-- ============================================================
CREATE TABLE categorias (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nome text NOT NULL,
    tipo text NOT NULL,             -- RECEITA | DESPESA
    grupo text,                     -- OPERACIONAL | NAO_OPERACIONAL | FINANCEIRA | TRIBUTARIA | PESSOAL
    conta_contabil_id uuid REFERENCES plano_contas(id),
    cor text DEFAULT '#666666',
    status text DEFAULT 'ATIVA',
    criado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, nome, tipo)
);

-- ============================================================
-- TABELA: centros_custo (Centros de Custo / Projetos)
-- ============================================================
CREATE TABLE centros_custo (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    codigo text NOT NULL,
    nome text NOT NULL,
    tipo text DEFAULT 'DEPARTAMENTO', -- DEPARTAMENTO | PROJETO | CLIENTE | FILIAL
    responsavel text,
    status text DEFAULT 'ATIVO',
    criado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, codigo)
);

-- ============================================================
-- TABELA: contas_bancarias (Contas Bancárias)
-- ============================================================
CREATE TABLE contas_bancarias (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nome text NOT NULL,             -- Ex: Itaú AG 1234 CC 56789-0
    banco text,                     -- Ex: Itaú, Bradesco, etc.
    codigo_banco text,              -- Ex: 341
    agencia text,
    conta text,
    tipo text DEFAULT 'CORRENTE',   -- CORRENTE | POUPANCA | INVESTIMENTO | CAIXA
    saldo_inicial numeric(14,2) DEFAULT 0,
    data_saldo_inicial date,
    conta_contabil_id uuid REFERENCES plano_contas(id),
    status text DEFAULT 'ATIVA',
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: clientes
-- ============================================================
CREATE TABLE clientes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tipo_pessoa text NOT NULL DEFAULT 'JURIDICA', -- FISICA | JURIDICA
    nome text NOT NULL,
    nome_fantasia text,
    cpf_cnpj text,
    inscricao_estadual text,
    inscricao_municipal text,
    email text,
    telefone text,
    endereco_logradouro text,
    endereco_numero text,
    endereco_complemento text,
    endereco_bairro text,
    endereco_cidade text,
    endereco_uf text,
    endereco_cep text,
    observacoes text,
    status text DEFAULT 'ATIVO',
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, cpf_cnpj)
);

-- ============================================================
-- TABELA: fornecedores
-- ============================================================
CREATE TABLE fornecedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tipo_pessoa text NOT NULL DEFAULT 'JURIDICA',
    nome text NOT NULL,
    nome_fantasia text,
    cpf_cnpj text,
    inscricao_estadual text,
    inscricao_municipal text,
    email text,
    telefone text,
    endereco_logradouro text,
    endereco_numero text,
    endereco_complemento text,
    endereco_bairro text,
    endereco_cidade text,
    endereco_uf text,
    endereco_cep text,
    observacoes text,
    status text DEFAULT 'ATIVO',
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, cpf_cnpj)
);

-- ============================================================
-- TABELA: produtos_servicos
-- ============================================================
CREATE TABLE produtos_servicos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tipo text NOT NULL DEFAULT 'SERVICO',  -- PRODUTO | SERVICO
    codigo text,
    descricao text NOT NULL,
    unidade text DEFAULT 'UN',       -- UN | HR | MES | KG | etc.
    preco_unitario numeric(14,2),
    -- Tributação
    ncm text,                        -- NCM (para produtos)
    codigo_servico text,             -- Código de serviço municipal
    aliquota_iss numeric(5,2),
    aliquota_icms numeric(5,2),
    aliquota_ipi numeric(5,2),
    -- Classificação
    categoria_id uuid REFERENCES categorias(id),
    conta_contabil_id uuid REFERENCES plano_contas(id),
    status text DEFAULT 'ATIVO',
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: notas_fiscais (NF-e / NFS-e entrada e saída)
-- ============================================================
CREATE TABLE notas_fiscais (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tipo text NOT NULL,              -- ENTRADA | SAIDA
    modelo text,                     -- NFE | NFSE | NFCE | CTE | MANUAL
    numero text,
    serie text,
    chave_acesso text,               -- Chave 44 dígitos (NF-e)
    -- Partes
    cliente_id uuid REFERENCES clientes(id),
    fornecedor_id uuid REFERENCES fornecedores(id),
    nome_emitente text,
    cnpj_emitente text,
    nome_destinatario text,
    cnpj_destinatario text,
    -- Valores
    valor_total numeric(14,2) NOT NULL DEFAULT 0,
    valor_produtos numeric(14,2) DEFAULT 0,
    valor_servicos numeric(14,2) DEFAULT 0,
    valor_desconto numeric(14,2) DEFAULT 0,
    valor_frete numeric(14,2) DEFAULT 0,
    -- Impostos
    valor_icms numeric(14,2) DEFAULT 0,
    valor_ipi numeric(14,2) DEFAULT 0,
    valor_pis numeric(14,2) DEFAULT 0,
    valor_cofins numeric(14,2) DEFAULT 0,
    valor_iss numeric(14,2) DEFAULT 0,
    valor_irrf numeric(14,2) DEFAULT 0,
    valor_csll numeric(14,2) DEFAULT 0,
    valor_inss numeric(14,2) DEFAULT 0,
    valor_pcc numeric(14,2) DEFAULT 0,  -- PIS/COFINS/CSLL retido
    -- Retenções na fonte
    retencao_irrf numeric(14,2) DEFAULT 0,
    retencao_pcc numeric(14,2) DEFAULT 0,
    retencao_iss numeric(14,2) DEFAULT 0,
    retencao_inss numeric(14,2) DEFAULT 0,
    -- Datas
    data_emissao date NOT NULL,
    data_entrada_saida date,
    data_competencia date,           -- Mês de competência
    -- Status
    status text DEFAULT 'ATIVA',     -- ATIVA | CANCELADA | INUTILIZADA
    status_sefaz text,               -- AUTORIZADA | CANCELADA | DENEGADA
    -- Classificação
    categoria_id uuid REFERENCES categorias(id),
    centro_custo_id uuid REFERENCES centros_custo(id),
    -- Dados brutos
    xml_content text,                -- XML original da NF
    observacoes text,
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: itens_nota_fiscal
-- ============================================================
CREATE TABLE itens_nota_fiscal (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nota_fiscal_id uuid NOT NULL REFERENCES notas_fiscais(id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    produto_servico_id uuid REFERENCES produtos_servicos(id),
    descricao text NOT NULL,
    quantidade numeric(14,4) NOT NULL DEFAULT 1,
    valor_unitario numeric(14,4) NOT NULL DEFAULT 0,
    valor_total numeric(14,2) NOT NULL DEFAULT 0,
    valor_desconto numeric(14,2) DEFAULT 0,
    -- Impostos do item
    ncm text,
    cfop text,
    aliquota_icms numeric(5,2) DEFAULT 0,
    valor_icms numeric(14,2) DEFAULT 0,
    aliquota_ipi numeric(5,2) DEFAULT 0,
    valor_ipi numeric(14,2) DEFAULT 0,
    aliquota_pis numeric(5,2) DEFAULT 0,
    valor_pis numeric(14,2) DEFAULT 0,
    aliquota_cofins numeric(5,2) DEFAULT 0,
    valor_cofins numeric(14,2) DEFAULT 0,
    aliquota_iss numeric(5,2) DEFAULT 0,
    valor_iss numeric(14,2) DEFAULT 0,
    criado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: lancamentos (Lançamentos Contábeis)
-- ============================================================
CREATE TABLE lancamentos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    data_lancamento date NOT NULL,
    data_competencia date NOT NULL,
    numero_lancamento serial,
    -- Partida dobrada
    conta_debito_id uuid NOT NULL REFERENCES plano_contas(id),
    conta_credito_id uuid NOT NULL REFERENCES plano_contas(id),
    valor numeric(14,2) NOT NULL CHECK (valor > 0),
    -- Classificação
    historico text NOT NULL,          -- Descrição do lançamento
    tipo text DEFAULT 'MANUAL',       -- MANUAL | AUTOMATICO | FOLHA | FISCAL | CONCILIACAO
    categoria_id uuid REFERENCES categorias(id),
    centro_custo_id uuid REFERENCES centros_custo(id),
    -- Origem
    nota_fiscal_id uuid REFERENCES notas_fiscais(id),
    conta_pagar_id uuid,              -- Referência lazy (sem FK por modularidade)
    conta_receber_id uuid,
    origem_externa text,              -- 'CONTA_AZUL:id' | 'LUMA_RH:folha_id' | etc.
    -- Controle
    status text DEFAULT 'ATIVO',      -- ATIVO | ESTORNADO
    estorno_de uuid REFERENCES lancamentos(id),
    usuario_id uuid REFERENCES auth.users(id),
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: contas_pagar
-- ============================================================
CREATE TABLE contas_pagar (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    fornecedor_id uuid REFERENCES fornecedores(id),
    nota_fiscal_id uuid REFERENCES notas_fiscais(id),
    descricao text NOT NULL,
    valor_original numeric(14,2) NOT NULL,
    valor_pago numeric(14,2) DEFAULT 0,
    valor_juros numeric(14,2) DEFAULT 0,
    valor_multa numeric(14,2) DEFAULT 0,
    valor_desconto numeric(14,2) DEFAULT 0,
    data_emissao date NOT NULL,
    data_vencimento date NOT NULL,
    data_pagamento date,
    data_competencia date,
    -- Classificação
    categoria_id uuid REFERENCES categorias(id),
    centro_custo_id uuid REFERENCES centros_custo(id),
    conta_bancaria_id uuid REFERENCES contas_bancarias(id),
    conta_contabil_id uuid REFERENCES plano_contas(id),
    -- Recorrência
    recorrente boolean DEFAULT false,
    frequencia_recorrencia text,     -- MENSAL | SEMANAL | QUINZENAL | ANUAL
    parcela_atual integer,
    total_parcelas integer,
    -- Controle
    numero_documento text,
    codigo_barras text,
    forma_pagamento text,            -- BOLETO | PIX | TED | DEBITO | CHEQUE | DINHEIRO
    status text DEFAULT 'PENDENTE',  -- PENDENTE | PAGO | VENCIDO | CANCELADO | PARCIAL
    observacoes text,
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: contas_receber
-- ============================================================
CREATE TABLE contas_receber (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    cliente_id uuid REFERENCES clientes(id),
    nota_fiscal_id uuid REFERENCES notas_fiscais(id),
    descricao text NOT NULL,
    valor_original numeric(14,2) NOT NULL,
    valor_recebido numeric(14,2) DEFAULT 0,
    valor_juros numeric(14,2) DEFAULT 0,
    valor_multa numeric(14,2) DEFAULT 0,
    valor_desconto numeric(14,2) DEFAULT 0,
    data_emissao date NOT NULL,
    data_vencimento date NOT NULL,
    data_recebimento date,
    data_competencia date,
    -- Classificação
    categoria_id uuid REFERENCES categorias(id),
    centro_custo_id uuid REFERENCES centros_custo(id),
    conta_bancaria_id uuid REFERENCES contas_bancarias(id),
    conta_contabil_id uuid REFERENCES plano_contas(id),
    -- Recorrência
    recorrente boolean DEFAULT false,
    frequencia_recorrencia text,
    parcela_atual integer,
    total_parcelas integer,
    -- Controle
    numero_documento text,
    forma_recebimento text,          -- BOLETO | PIX | TED | CARTAO_CREDITO | CARTAO_DEBITO | DINHEIRO
    status text DEFAULT 'PENDENTE',  -- PENDENTE | RECEBIDO | VENCIDO | CANCELADO | PARCIAL
    observacoes text,
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: extratos_bancarios (importação OFX/CSV)
-- ============================================================
CREATE TABLE extratos_bancarios (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    conta_bancaria_id uuid NOT NULL REFERENCES contas_bancarias(id),
    data_transacao date NOT NULL,
    descricao text NOT NULL,
    valor numeric(14,2) NOT NULL,    -- Positivo = crédito, Negativo = débito
    tipo text,                       -- CREDITO | DEBITO
    numero_documento text,
    -- Conciliação
    conciliado boolean DEFAULT false,
    lancamento_id uuid REFERENCES lancamentos(id),
    conta_pagar_id uuid REFERENCES contas_pagar(id),
    conta_receber_id uuid REFERENCES contas_receber(id),
    data_conciliacao date,
    -- Origem
    origem text DEFAULT 'MANUAL',    -- MANUAL | OFX | CSV | CONTA_AZUL
    id_externo text,                 -- ID na origem (para evitar duplicação)
    criado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, conta_bancaria_id, id_externo)
);

-- ============================================================
-- TABELA: apuracoes_fiscais (Apuração de Impostos)
-- ============================================================
CREATE TABLE apuracoes_fiscais (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    tipo_imposto text NOT NULL,      -- IRPJ | CSLL | PIS | COFINS | ISS | ICMS
    periodo_tipo text NOT NULL,      -- MENSAL | TRIMESTRAL | ANUAL
    competencia_inicio date NOT NULL,
    competencia_fim date NOT NULL,
    -- Bases de cálculo
    receita_bruta numeric(14,2) DEFAULT 0,
    base_calculo numeric(14,2) DEFAULT 0,
    percentual_presuncao numeric(5,2),
    aliquota numeric(5,2) NOT NULL,
    -- Valores
    valor_imposto numeric(14,2) NOT NULL DEFAULT 0,
    valor_adicional numeric(14,2) DEFAULT 0,  -- Adicional IRPJ >60k/tri
    valor_retencoes numeric(14,2) DEFAULT 0,
    valor_compensacoes numeric(14,2) DEFAULT 0,
    valor_devido numeric(14,2) NOT NULL DEFAULT 0,
    -- DARF
    codigo_receita text,             -- Ex: 2089 (IRPJ), 2372 (CSLL)
    data_vencimento date,
    data_pagamento date,
    numero_darf text,
    -- Controle
    status text DEFAULT 'CALCULADO', -- CALCULADO | CONFERIDO | PAGO | ATRASADO
    observacoes text,
    dados_calculo jsonb DEFAULT '{}', -- Memória de cálculo detalhada
    usuario_id uuid REFERENCES auth.users(id),
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, tipo_imposto, competencia_inicio)
);

-- ============================================================
-- TABELA: retencoes (Retenções na Fonte)
-- ============================================================
CREATE TABLE retencoes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    nota_fiscal_id uuid REFERENCES notas_fiscais(id),
    tipo_retencao text NOT NULL,     -- IRRF | PCC | ISS | INSS
    -- Partes
    retido_de text,                  -- Nome de quem reteve / de quem foi retido
    cnpj_retido_de text,
    -- Valores
    base_calculo numeric(14,2) NOT NULL,
    aliquota numeric(5,2) NOT NULL,
    valor_retido numeric(14,2) NOT NULL,
    -- Competência
    data_fato_gerador date NOT NULL,
    data_competencia date NOT NULL,
    data_recolhimento date,
    -- DARF
    codigo_receita text,
    numero_darf text,
    -- Controle
    direcao text NOT NULL,           -- RETIDO_POR_NOS | RETIDO_DE_NOS
    status text DEFAULT 'PENDENTE',  -- PENDENTE | RECOLHIDO | COMPENSADO
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: calendario_obrigacoes (Agenda Fiscal)
-- ============================================================
CREATE TABLE calendario_obrigacoes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    obrigacao text NOT NULL,         -- DCTF | EFD | SPED_ECD | SPED_ECF | DIRF | IRPJ | CSLL | PIS | COFINS | ISS | FGTS | INSS | ESOCIAL
    descricao text,
    competencia date NOT NULL,       -- Mês/ano de competência
    data_vencimento date NOT NULL,
    data_entrega date,
    responsavel text,                -- AGENTE_DIGITAL | CONTADOR_CRC
    status text DEFAULT 'PENDENTE',  -- PENDENTE | ENTREGUE | ATRASADO | NAO_APLICAVEL
    observacoes text,
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, obrigacao, competencia)
);

-- ============================================================
-- TABELA: pedidos_venda (Orçamentos e Vendas)
-- ============================================================
CREATE TABLE pedidos_venda (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    numero text NOT NULL,
    cliente_id uuid NOT NULL REFERENCES clientes(id),
    data_emissao date NOT NULL DEFAULT CURRENT_DATE,
    data_validade date,
    -- Valores
    valor_produtos numeric(14,2) DEFAULT 0,
    valor_servicos numeric(14,2) DEFAULT 0,
    valor_desconto numeric(14,2) DEFAULT 0,
    valor_frete numeric(14,2) DEFAULT 0,
    valor_total numeric(14,2) NOT NULL DEFAULT 0,
    -- Classificação
    categoria_id uuid REFERENCES categorias(id),
    centro_custo_id uuid REFERENCES centros_custo(id),
    -- Referências
    nota_fiscal_id uuid REFERENCES notas_fiscais(id),
    conta_receber_id uuid REFERENCES contas_receber(id),
    -- Controle
    forma_pagamento text,
    condicao_pagamento text,         -- A_VISTA | 30_DIAS | 30_60 | 30_60_90 | PERSONALIZADO
    status text DEFAULT 'ORCAMENTO', -- ORCAMENTO | APROVADO | FATURADO | CANCELADO
    observacoes text,
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, numero)
);

-- ============================================================
-- TABELA: itens_pedido_venda
-- ============================================================
CREATE TABLE itens_pedido_venda (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    pedido_venda_id uuid NOT NULL REFERENCES pedidos_venda(id) ON DELETE CASCADE,
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    produto_servico_id uuid REFERENCES produtos_servicos(id),
    descricao text NOT NULL,
    quantidade numeric(14,4) NOT NULL DEFAULT 1,
    valor_unitario numeric(14,4) NOT NULL DEFAULT 0,
    valor_desconto numeric(14,2) DEFAULT 0,
    valor_total numeric(14,2) NOT NULL DEFAULT 0,
    criado_em timestamptz DEFAULT now()
);

-- ============================================================
-- TABELA: folha_contabil (Dados de folha vindos do RH)
-- ============================================================
CREATE TABLE folha_contabil (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    competencia date NOT NULL,       -- Mês/ano
    -- Totais da folha
    total_salarios numeric(14,2) DEFAULT 0,
    total_horas_extras numeric(14,2) DEFAULT 0,
    total_ferias numeric(14,2) DEFAULT 0,
    total_13_salario numeric(14,2) DEFAULT 0,
    total_rescisoes numeric(14,2) DEFAULT 0,
    total_inss_empregado numeric(14,2) DEFAULT 0,
    total_irrf numeric(14,2) DEFAULT 0,
    total_inss_patronal numeric(14,2) DEFAULT 0,
    total_fgts numeric(14,2) DEFAULT 0,
    total_rat numeric(14,2) DEFAULT 0,
    total_terceiros numeric(14,2) DEFAULT 0,
    total_vale_transporte numeric(14,2) DEFAULT 0,
    total_vale_refeicao numeric(14,2) DEFAULT 0,
    total_plano_saude numeric(14,2) DEFAULT 0,
    total_liquido numeric(14,2) DEFAULT 0,
    total_custo_empresa numeric(14,2) DEFAULT 0,
    -- PJ
    total_pagamentos_pj numeric(14,2) DEFAULT 0,
    total_retencoes_pj numeric(14,2) DEFAULT 0,
    -- Quantidade
    qtd_funcionarios_clt integer DEFAULT 0,
    qtd_prestadores_pj integer DEFAULT 0,
    -- Integração
    origem text DEFAULT 'MANUAL',    -- MANUAL | LUMA_RH | IMPORTACAO
    luma_rh_referencia text,         -- ID/referência no LUMA RH
    -- Controle
    lancamento_id uuid REFERENCES lancamentos(id),
    status text DEFAULT 'PENDENTE',  -- PENDENTE | CONTABILIZADO | CONFERIDO
    dados_detalhados jsonb DEFAULT '{}',
    criado_em timestamptz DEFAULT now(),
    atualizado_em timestamptz DEFAULT now(),
    UNIQUE (tenant_id, competencia)
);

-- ============================================================
-- TABELA: log_eventos (Auditoria)
-- ============================================================
CREATE TABLE log_eventos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
    tipo text NOT NULL,
    descricao text,
    dados jsonb DEFAULT '{}',
    usuario_id uuid REFERENCES auth.users(id),
    criado_em timestamptz DEFAULT now()
);

-- ============================================================
-- ÍNDICES
-- ============================================================
-- Plano de contas
CREATE INDEX idx_plano_contas_tenant ON plano_contas(tenant_id);
CREATE INDEX idx_plano_contas_codigo ON plano_contas(tenant_id, codigo);
CREATE INDEX idx_plano_contas_tipo ON plano_contas(tenant_id, tipo);

-- Lançamentos
CREATE INDEX idx_lancamentos_tenant ON lancamentos(tenant_id);
CREATE INDEX idx_lancamentos_data ON lancamentos(tenant_id, data_competencia);
CREATE INDEX idx_lancamentos_tipo ON lancamentos(tenant_id, tipo);
CREATE INDEX idx_lancamentos_debito ON lancamentos(conta_debito_id);
CREATE INDEX idx_lancamentos_credito ON lancamentos(conta_credito_id);

-- Contas a pagar/receber
CREATE INDEX idx_contas_pagar_tenant ON contas_pagar(tenant_id);
CREATE INDEX idx_contas_pagar_vencimento ON contas_pagar(tenant_id, data_vencimento);
CREATE INDEX idx_contas_pagar_status ON contas_pagar(tenant_id, status);
CREATE INDEX idx_contas_receber_tenant ON contas_receber(tenant_id);
CREATE INDEX idx_contas_receber_vencimento ON contas_receber(tenant_id, data_vencimento);
CREATE INDEX idx_contas_receber_status ON contas_receber(tenant_id, status);

-- Notas fiscais
CREATE INDEX idx_notas_fiscais_tenant ON notas_fiscais(tenant_id);
CREATE INDEX idx_notas_fiscais_tipo ON notas_fiscais(tenant_id, tipo);
CREATE INDEX idx_notas_fiscais_emissao ON notas_fiscais(tenant_id, data_emissao);
CREATE INDEX idx_notas_fiscais_competencia ON notas_fiscais(tenant_id, data_competencia);

-- Extratos
CREATE INDEX idx_extratos_tenant ON extratos_bancarios(tenant_id);
CREATE INDEX idx_extratos_conta ON extratos_bancarios(conta_bancaria_id, data_transacao);
CREATE INDEX idx_extratos_conciliado ON extratos_bancarios(tenant_id, conciliado);

-- Apurações
CREATE INDEX idx_apuracoes_tenant ON apuracoes_fiscais(tenant_id);
CREATE INDEX idx_apuracoes_tipo ON apuracoes_fiscais(tenant_id, tipo_imposto);

-- Retenções
CREATE INDEX idx_retencoes_tenant ON retencoes(tenant_id);
CREATE INDEX idx_retencoes_competencia ON retencoes(tenant_id, data_competencia);

-- Calendário
CREATE INDEX idx_calendario_tenant ON calendario_obrigacoes(tenant_id);
CREATE INDEX idx_calendario_vencimento ON calendario_obrigacoes(data_vencimento);
CREATE INDEX idx_calendario_status ON calendario_obrigacoes(tenant_id, status);

-- Clientes/Fornecedores
CREATE INDEX idx_clientes_tenant ON clientes(tenant_id);
CREATE INDEX idx_clientes_cnpj ON clientes(cpf_cnpj);
CREATE INDEX idx_fornecedores_tenant ON fornecedores(tenant_id);
CREATE INDEX idx_fornecedores_cnpj ON fornecedores(cpf_cnpj);

-- Pedidos
CREATE INDEX idx_pedidos_tenant ON pedidos_venda(tenant_id);
CREATE INDEX idx_pedidos_cliente ON pedidos_venda(cliente_id);
CREATE INDEX idx_pedidos_status ON pedidos_venda(tenant_id, status);

-- Folha contábil
CREATE INDEX idx_folha_tenant ON folha_contabil(tenant_id);
CREATE INDEX idx_folha_competencia ON folha_contabil(tenant_id, competencia);

-- Profiles e Log
CREATE INDEX idx_profiles_tenant ON profiles(tenant_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_log_tenant ON log_eventos(tenant_id, criado_em DESC);

-- ============================================================
-- FUNÇÃO: atualiza campo atualizado_em automaticamente
-- ============================================================
CREATE OR REPLACE FUNCTION _set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers de atualizado_em
CREATE TRIGGER trg_tenants_updated BEFORE UPDATE ON tenants FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_plano_contas_updated BEFORE UPDATE ON plano_contas FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_contas_bancarias_updated BEFORE UPDATE ON contas_bancarias FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_clientes_updated BEFORE UPDATE ON clientes FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_fornecedores_updated BEFORE UPDATE ON fornecedores FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_produtos_servicos_updated BEFORE UPDATE ON produtos_servicos FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_notas_fiscais_updated BEFORE UPDATE ON notas_fiscais FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_lancamentos_updated BEFORE UPDATE ON lancamentos FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_contas_pagar_updated BEFORE UPDATE ON contas_pagar FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_contas_receber_updated BEFORE UPDATE ON contas_receber FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_apuracoes_updated BEFORE UPDATE ON apuracoes_fiscais FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_retencoes_updated BEFORE UPDATE ON retencoes FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_calendario_updated BEFORE UPDATE ON calendario_obrigacoes FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_pedidos_updated BEFORE UPDATE ON pedidos_venda FOR EACH ROW EXECUTE FUNCTION _set_updated_at();
CREATE TRIGGER trg_folha_updated BEFORE UPDATE ON folha_contabil FOR EACH ROW EXECUTE FUNCTION _set_updated_at();

-- ============================================================
-- FUNÇÃO: gerar próximo número de pedido
-- ============================================================
CREATE OR REPLACE FUNCTION gen_numero_pedido(p_tenant_id uuid)
RETURNS text AS $$
DECLARE
    v_seq integer;
BEGIN
    SELECT COALESCE(MAX(CAST(SUBSTRING(numero FROM '[0-9]+') AS integer)), 0) + 1
    INTO v_seq
    FROM pedidos_venda
    WHERE tenant_id = p_tenant_id;

    RETURN 'PED-' || LPAD(v_seq::text, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- FUNÇÃO: calcular saldo de conta bancária
-- ============================================================
CREATE OR REPLACE FUNCTION saldo_conta_bancaria(p_conta_id uuid, p_data date DEFAULT CURRENT_DATE)
RETURNS numeric AS $$
DECLARE
    v_saldo_inicial numeric;
    v_movimentacoes numeric;
BEGIN
    SELECT COALESCE(saldo_inicial, 0) INTO v_saldo_inicial
    FROM contas_bancarias WHERE id = p_conta_id;

    SELECT COALESCE(SUM(valor), 0) INTO v_movimentacoes
    FROM extratos_bancarios
    WHERE conta_bancaria_id = p_conta_id
    AND data_transacao <= p_data;

    RETURN v_saldo_inicial + v_movimentacoes;
END;
$$ LANGUAGE plpgsql;
