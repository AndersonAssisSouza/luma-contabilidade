-- =====================================================
-- LUMA Contabilidade x Conta Azul - Schema de Integração
-- =====================================================

-- Tabela de tokens OAuth (1 registro por empresa conectada)
CREATE TABLE IF NOT EXISTS contaazul_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL,
    client_id TEXT NOT NULL,
    client_secret TEXT NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    token_expires_at TIMESTAMPTZ,
    redirect_uri TEXT NOT NULL DEFAULT 'https://contaazul.com',
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(empresa_id)
);

-- Tabela de log de sincronizações
CREATE TABLE IF NOT EXISTS contaazul_sync_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL,
    tipo_sync TEXT NOT NULL,
    entidade TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'running',
    registros_sincronizados INTEGER DEFAULT 0,
    erro TEXT,
    inicio TIMESTAMPTZ NOT NULL DEFAULT now(),
    fim TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ca_categorias (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    versao INTEGER DEFAULT 0,
    nome TEXT NOT NULL,
    categoria_pai UUID,
    tipo TEXT,
    entrada_saida TEXT,
    ativo BOOLEAN DEFAULT true,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_categorias_empresa ON ca_categorias(empresa_id);
CREATE INDEX idx_ca_categorias_tipo ON ca_categorias(tipo);

CREATE TABLE IF NOT EXISTS ca_categorias_dre (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    descricao TEXT NOT NULL,
    codigo TEXT,
    posicao INTEGER,
    indica_totalizador BOOLEAN DEFAULT false,
    representacao TEXT,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_categorias_dre_empresa ON ca_categorias_dre(empresa_id);

CREATE TABLE IF NOT EXISTS ca_centro_custos (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    nome TEXT NOT NULL,
    ativo BOOLEAN DEFAULT true,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_centro_custos_empresa ON ca_centro_custos(empresa_id);

CREATE TABLE IF NOT EXISTS ca_pessoas (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    nome TEXT NOT NULL,
    documento TEXT,
    email TEXT,
    telefone TEXT,
    tipo_pessoa TEXT,
    tipo_relacao TEXT[],
    ativo BOOLEAN DEFAULT true,
    endereco_logradouro TEXT,
    endereco_numero TEXT,
    endereco_complemento TEXT,
    endereco_bairro TEXT,
    endereco_cidade TEXT,
    endereco_uf TEXT,
    endereco_cep TEXT,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_pessoas_empresa ON ca_pessoas(empresa_id);
CREATE INDEX idx_ca_pessoas_documento ON ca_pessoas(documento);
CREATE INDEX idx_ca_pessoas_tipo ON ca_pessoas USING GIN(tipo_relacao);

CREATE TABLE IF NOT EXISTS ca_produtos (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    id_legado BIGINT,
    nome TEXT NOT NULL,
    codigo TEXT,
    preco_venda DECIMAL(15,2),
    preco_custo DECIMAL(15,2),
    ncm TEXT,
    unidade_medida TEXT,
    estoque_atual DECIMAL(15,4),
    ativo BOOLEAN DEFAULT true,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_produtos_empresa ON ca_produtos(empresa_id);

CREATE TABLE IF NOT EXISTS ca_servicos (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    id_servico BIGINT,
    codigo TEXT,
    descricao TEXT NOT NULL,
    preco DECIMAL(15,2),
    ativo BOOLEAN DEFAULT true,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_servicos_empresa ON ca_servicos(empresa_id);

CREATE TABLE IF NOT EXISTS ca_contas_financeiras (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    nome TEXT NOT NULL,
    tipo TEXT,
    saldo_atual DECIMAL(15,2),
    ativo BOOLEAN DEFAULT true,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_contas_fin_empresa ON ca_contas_financeiras(empresa_id);

CREATE TABLE IF NOT EXISTS ca_contas_receber (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    descricao TEXT,
    status TEXT,
    status_traduzido TEXT,
    total DECIMAL(15,2),
    pago DECIMAL(15,2) DEFAULT 0,
    nao_pago DECIMAL(15,2) DEFAULT 0,
    data_vencimento DATE,
    data_criacao TIMESTAMPTZ,
    data_alteracao TIMESTAMPTZ,
    pessoa_id UUID,
    categoria_id UUID,
    conta_financeira_id UUID,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_contas_rec_empresa ON ca_contas_receber(empresa_id);
CREATE INDEX idx_ca_contas_rec_vencimento ON ca_contas_receber(data_vencimento);
CREATE INDEX idx_ca_contas_rec_status ON ca_contas_receber(status);

CREATE TABLE IF NOT EXISTS ca_contas_pagar (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    descricao TEXT,
    status TEXT,
    status_traduzido TEXT,
    total DECIMAL(15,2),
    pago DECIMAL(15,2) DEFAULT 0,
    nao_pago DECIMAL(15,2) DEFAULT 0,
    data_vencimento DATE,
    data_criacao TIMESTAMPTZ,
    data_alteracao TIMESTAMPTZ,
    pessoa_id UUID,
    categoria_id UUID,
    conta_financeira_id UUID,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_contas_pag_empresa ON ca_contas_pagar(empresa_id);
CREATE INDEX idx_ca_contas_pag_vencimento ON ca_contas_pagar(data_vencimento);
CREATE INDEX idx_ca_contas_pag_status ON ca_contas_pagar(status);

CREATE TABLE IF NOT EXISTS ca_vendas (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    numero INTEGER,
    data_venda DATE,
    status TEXT,
    valor_total DECIMAL(15,2),
    pessoa_id UUID,
    vendedor_id UUID,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_vendas_empresa ON ca_vendas(empresa_id);
CREATE INDEX idx_ca_vendas_data ON ca_vendas(data_venda);

CREATE TABLE IF NOT EXISTS ca_notas_fiscais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL,
    chave TEXT UNIQUE,
    numero TEXT,
    serie TEXT,
    tipo TEXT,
    data_emissao TIMESTAMPTZ,
    valor_total DECIMAL(15,2),
    status TEXT,
    pessoa_id UUID,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_nfs_empresa ON ca_notas_fiscais(empresa_id);
CREATE INDEX idx_ca_nfs_data ON ca_notas_fiscais(data_emissao);
CREATE INDEX idx_ca_nfs_chave ON ca_notas_fiscais(chave);

CREATE TABLE IF NOT EXISTS ca_contratos (
    id UUID PRIMARY KEY,
    empresa_id UUID NOT NULL,
    descricao TEXT,
    valor DECIMAL(15,2),
    data_inicio DATE,
    data_fim DATE,
    recorrencia TEXT,
    status TEXT,
    pessoa_id UUID,
    dados_raw JSONB,
    sync_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_ca_contratos_empresa ON ca_contratos(empresa_id);

-- Função auxiliar: Atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'contaazul_tokens', 'ca_categorias', 'ca_centro_custos', 'ca_pessoas',
        'ca_produtos', 'ca_servicos', 'ca_contas_financeiras',
        'ca_contas_receber', 'ca_contas_pagar', 'ca_vendas', 'ca_contratos'
    ])
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_%I_updated_at
            BEFORE UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
            t, t);
    END LOOP;
END $$;

-- RLS (Row Level Security) - Habilitar para multitenancy
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'contaazul_tokens', 'contaazul_sync_log', 'ca_categorias', 'ca_categorias_dre',
        'ca_centro_custos', 'ca_pessoas', 'ca_produtos', 'ca_servicos',
        'ca_contas_financeiras', 'ca_contas_receber', 'ca_contas_pagar',
        'ca_vendas', 'ca_notas_fiscais', 'ca_contratos'
    ])
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;
