-- Migration 007: adiciona data_competencia e data_emissao nas tabelas CA
-- Necessário para DRE por regime de competência

ALTER TABLE ca_contas_pagar
    ADD COLUMN IF NOT EXISTS data_emissao    DATE,
    ADD COLUMN IF NOT EXISTS data_competencia DATE;

ALTER TABLE ca_contas_receber
    ADD COLUMN IF NOT EXISTS data_emissao    DATE,
    ADD COLUMN IF NOT EXISTS data_competencia DATE;

-- Popula a partir do dados_raw para registros já existentes
UPDATE ca_contas_pagar
SET
    data_emissao     = (dados_raw->>'data_emissao')::DATE,
    data_competencia = COALESCE(
                          NULLIF(dados_raw->>'data_competencia', ''),
                          dados_raw->>'data_emissao'
                       )::DATE
WHERE dados_raw IS NOT NULL
  AND data_competencia IS NULL;

UPDATE ca_contas_receber
SET
    data_emissao     = (dados_raw->>'data_emissao')::DATE,
    data_competencia = COALESCE(
                          NULLIF(dados_raw->>'data_competencia', ''),
                          dados_raw->>'data_emissao'
                       )::DATE
WHERE dados_raw IS NOT NULL
  AND data_competencia IS NULL;

-- Índices para performance na DRE
CREATE INDEX IF NOT EXISTS idx_ca_contas_pag_competencia  ON ca_contas_pagar(data_competencia);
CREATE INDEX IF NOT EXISTS idx_ca_contas_rec_competencia  ON ca_contas_receber(data_competencia);
CREATE INDEX IF NOT EXISTS idx_ca_contas_pag_emissao      ON ca_contas_pagar(data_emissao);
CREATE INDEX IF NOT EXISTS idx_ca_contas_rec_emissao      ON ca_contas_receber(data_emissao);
