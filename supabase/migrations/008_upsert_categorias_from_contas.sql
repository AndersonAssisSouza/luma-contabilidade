-- Migration 008: RPC to extract inline categories from dados_raw of contas tables
-- Ensures categories embedded in bill/invoice data are always reflected in ca_categorias.
-- Called automatically after each syncCategorias run.

CREATE OR REPLACE FUNCTION upsert_categorias_from_contas_raw(p_empresa_id uuid)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO ca_categorias (id, empresa_id, nome, tipo, versao, categoria_pai, ativo, dados_raw, sync_at)
  SELECT DISTINCT
    (cat->>'id')::uuid               AS id,
    p_empresa_id                     AS empresa_id,
    cat->>'nome'                     AS nome,
    COALESCE(cat->>'tipo', 'DESPESA') AS tipo,
    0                                AS versao,
    NULL::uuid                       AS categoria_pai,
    true                             AS ativo,
    cat                              AS dados_raw,
    NOW()                            AS sync_at
  FROM (
    SELECT jsonb_array_elements(dados_raw->'categorias') AS cat
    FROM ca_contas_pagar
    WHERE dados_raw->'categorias' IS NOT NULL
      AND empresa_id = p_empresa_id
    UNION
    SELECT jsonb_array_elements(dados_raw->'categorias') AS cat
    FROM ca_contas_receber
    WHERE dados_raw->'categorias' IS NOT NULL
      AND empresa_id = p_empresa_id
  ) sub
  WHERE cat->>'id' IS NOT NULL
  ON CONFLICT (id) DO UPDATE SET
    nome     = EXCLUDED.nome,
    sync_at  = NOW()
  WHERE ca_categorias.nome IS DISTINCT FROM EXCLUDED.nome;
END;
$$;
