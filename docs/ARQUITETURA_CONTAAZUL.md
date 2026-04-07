# LUMA Contabilidade x Conta Azul - Arquitetura de Integracao

## Visao Geral

Integracao entre o sistema LUMA Contabilidade (GitHub Pages + Supabase) e o ERP Conta Azul via API REST v2.

## Stack Tecnica

| Componente | Tecnologia |
|---|---|
| Frontend | GitHub Pages (HTML/JS estatico) |
| Backend | Supabase Edge Functions (Deno/TypeScript) |
| Banco de Dados | Supabase PostgreSQL |
| API Externa | Conta Azul API v2 (api-v2.contaazul.com) |
| Autenticacao | OAuth 2.0 (Authorization Code + Cognito JWT) |

## Fluxo de Autenticacao OAuth 2.0

1. Frontend redireciona usuario para auth.contaazul.com/login com client_id, redirect_uri, state e scope
2. Usuario autoriza -> redirect com ?code={CODE}
3. Edge Function troca code por tokens via POST auth.contaazul.com/oauth2/token (Basic Auth)
4. Resposta: access_token, refresh_token, expires_in: 3600
5. access_token usado como Bearer token nas chamadas a API v2
6. Refresh token valido por 5 anos (renovar antes do access_token expirar)

## Endpoints da API v2 Mapeados

### Base URL: https://api-v2.contaazul.com

### Financeiro
| Metodo | Endpoint | Parametros |
|---|---|---|
| GET | /v1/categorias | page, size |
| GET | /v1/financeiro/categorias-dre | - |
| GET | /v1/centro-de-custo | - |
| GET | /v1/conta-financeira | - |
| GET | /v1/conta-financeira/{id}/saldo-atual | id |
| GET | /v1/financeiro/eventos-financeiros/contas-a-receber/buscar | data_vencimento_de, data_vencimento_ate |
| GET | /v1/financeiro/eventos-financeiros/contas-a-pagar/buscar | data_vencimento_de, data_vencimento_ate |
| POST | /v1/financeiro/eventos-financeiros/contas-a-receber | body |
| POST | /v1/financeiro/eventos-financeiros/contas-a-pagar | body |
| GET | /v1/financeiro/eventos-financeiros/parcelas/{id} | id |
| GET | /v1/financeiro/eventos-financeiros/alteracoes | data_inicio |
| GET | /v1/financeiro/transferencias | - |
| GET | /v1/financeiro/eventos-financeiros/saldo-inicial | - |

### Pessoas (Clientes/Fornecedores)
| Metodo | Endpoint | Parametros |
|---|---|---|
| GET | /v1/pessoas | page, size, nome, documento, tipo |
| GET | /v1/pessoas/{id} | id |
| POST | /v1/pessoas | body |
| PUT | /v1/pessoas/{id} | id, body |

### Produtos e Servicos
| Metodo | Endpoint | Parametros |
|---|---|---|
| GET | /v1/produtos | page, size |
| GET | /v1/produtos/{id} | id |
| GET | /v1/servicos | page, size |

### Vendas
| Metodo | Endpoint | Parametros |
|---|---|---|
| GET | /v1/venda/busca | filtros |
| GET | /v1/venda/{id} | id |
| GET | /v1/venda/{id}/itens | id |
| POST | /v1/venda | body |

### Notas Fiscais
| Metodo | Endpoint | Parametros |
|---|---|---|
| GET | /v1/notas-fiscais | data_emissao_inicio, data_emissao_fim, tipo |
| GET | /v1/notas-fiscais-servico | parametros |
| GET | /v1/notas-fiscais/{chave} | chave |

### Contratos
| Metodo | Endpoint | Parametros |
|---|---|---|
| GET | /v1/contratos | data_inicio |

## Rate Limits
- 600 requisicoes/minuto por conta conectada
- 10 requisicoes/segundo

## Estrategia de Sincronizacao
- Polling periodico (sem webhooks disponiveis)
- Endpoint /v1/financeiro/eventos-financeiros/alteracoes para sync incremental
- Sync completo agendado diariamente
- Sync sob demanda via botao no frontend

## Credenciais (Desenvolvimento)
- client_id: 4va0nsbptdp2lnlnsstan8nlm0
- Redirect URI: https://contaazul.com
- Auth endpoint: https://auth.contaazul.com
- Token endpoint: https://auth.contaazul.com/oauth2/token
- API base: https://api-v2.contaazul.com
