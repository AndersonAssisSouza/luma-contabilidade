# LUMA Contabilidade

[![GitHub](https://img.shields.io/badge/GitHub-AndersonAssisSouza/luma--contabilidade-blue)](https://github.com/AndersonAssisSouza/luma-contabilidade)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![TypeScript](https://img.shields.io/badge/TypeScript-Ready-blue)](https://www.typescriptlang.org/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL%20%2B%20Auth-brightgreen)](https://supabase.com/)

## 📋 Descrição

**LUMA Contabilidade** é um sistema SaaS completo de contabilidade desenvolvido especificamente para empresas brasileiras. Oferece uma solução integrada para gestão contábil, fiscal, trabalhista e gerencial, com suporte a regime de tributação de **Lucro Presumido** e escrituração de partida dobrada.

O projeto utiliza arquitetura **multi-tenant** com isolamento de dados por `tenant_id`, garantindo segurança e conformidade através de **Row Level Security (RLS)** do PostgreSQL. É uma aplicação web moderna construída com **HTML puro** e **Vanilla JavaScript**, elimando dependências pesadas e proporcionando máxima portabilidade.

### Principais Características

- ✅ **Multi-tenant SaaS**: Isolamento completo de dados por tenant
- ✅ **5 Níveis de Permissão**: manager_global, master, contador, operador, visualizador
- ✅ **Contabilidade Completa**: Partida dobrada, plano de contas, diário e razão
- ✅ **Fiscal Integrado**: IRPJ/CSLL, PIS/COFINS, ISS, retenções e apurações
- ✅ **Folha de Pagamento**: Integração com LUMA RH
- ✅ **Gestão Comercial**: Clientes, fornecedores, notas fiscais, pedidos
- ✅ **Dashboards Gerenciais**: DRE, fluxo de caixa, análises em tempo real
- ✅ **Calendário Fiscal**: Controle de obrigações acessórias brasileiras
- ✅ **Conciliação Bancária**: Verificação de transações e discrepâncias
- ✅ **RLS PostgreSQL**: Segurança em nível de linha no banco de dados

---

## 🏗️ Arquitetura

### Arquitetura Multi-Tenant

```
┌─────────────────────────────────────────────────┐
│           Frontend (HTML + Vanilla JS)           │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│    Supabase Client (Realtime + RLS)             │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│  Supabase (Auth + PostgreSQL + RLS + Realtime) │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │   PostgreSQL Database                      │ │
│  │   - Tenant Isolation (tenant_id)           │ │
│  │   - 20+ Tabelas Especializadas             │ │
│  │   - 60+ Índices para Performance           │ │
│  │   - Row Level Security (RLS)               │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │   Authentication & Authorization           │ │
│  │   - JWT Tokens                             │ │
│  │   - Role-Based Access Control (RBAC)       │ │
│  └────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

### Fluxo de Dados

1. **Login**: Usuário autentica via Supabase Auth
2. **Token JWT**: Supabase emite JWT com claims do tenant e role
3. **Isolamento**: RLS policies filtram dados por `tenant_id`
4. **Operações**: CRUD respeitam permissões por role
5. **Realtime**: WebSocket sincroniza mudanças em tempo real

---

## 🛠️ Stack Tecnológico

| Camada | Tecnologia | Descrição |
|--------|-----------|-----------|
| **Frontend** | HTML5 + CSS3 | Markup semântico e estilos responsivos |
| **JavaScript** | Vanilla JS (ES6+) | Sem frameworks, máxima portabilidade |
| **Backend** | Supabase | PostgreSQL gerenciado |
| **Auth** | Supabase Auth | JWT, OAuth 2.0 pronto para integração |
| **Database** | PostgreSQL 15+ | Transações ACID, partida dobrada |
| **RLS** | PostgreSQL RLS | Segurança em nível de linha |
| **Realtime** | Supabase Realtime | WebSocket para sincronização |
| **Hosting** | GitHub Pages + Cloudflare Worker | SPA moderna com suporte a routing |
| **Versionamento** | Git | Controle de versão e CI/CD |

---

## 📦 Módulos do Sistema

### 1. **Módulo Fiscal** 🏛️
Apuração automática de impostos e gestão de obrigações acessórias.

- **Impostos Federais**:
  - IRPJ (Imposto de Renda Pessoa Jurídica)
  - CSLL (Contribuição Social Sobre o Lucro Líquido)
  - PIS/COFINS (Contribuições Sociais)

- **Impostos Estaduais**:
  - ICMS (Circulação de Mercadorias)

- **Impostos Municipais**:
  - ISS (Imposto Sobre Serviços)

- **Retenções na Fonte**:
  - IR sobre Aluguéis
  - IR sobre Aplicações Financeiras
  - INSS sobre Aluguéis (15%)

- **Regime Fiscal**: Lucro Presumido (32% de presunção para serviços)

**Arquivo**: `apuracoes.html` | `calendario_fiscal.html`

### 2. **Módulo Contábil** 📚
Escrituração contábil com partida dobrada.

- **Plano de Contas**: Contas sintéticas e analíticas
- **Lançamentos**: Diário contábil com validação de débito/crédito
- **Razão**: Movimentação por conta
- **Balancetes**: Teste antes e depois da apuração
- **Closing**: Encerramento de períodos
- **Auditoria**: Rastro completo de alterações

**Arquivos**: `plano_contas.html` | `lancamentos.html`

### 3. **Módulo Trabalhista** 💼
Integração com folha de pagamento.

- **Integração LUMA RH**: Importação de eventos de folha
- **Contabilização de Folha**: Lançamentos automáticos
- **FGTS**: Contabilização mensal
- **13º Salário**: Apropriação e pagamento
- **Encargos**: Cálculo de INSS patronal

**Integração**: API/Events do LUMA RH (planejado)

### 4. **Módulo Gerencial** 📊
Inteligência de negócios e análises.

- **DRE (Demonstração de Resultado)**: Receitas, custos, despesas, lucro
- **Fluxo de Caixa**: Projeções e análises de liquidez
- **Dashboards**: KPIs em tempo real
- **Indicadores**: Margem, rentabilidade, endividamento
- **Comparativos**: Períodos e cenários

**Arquivos**: `dre.html` | `fluxo_caixa.html`

### 5. **Módulo Comercial** 🛍️
Gestão de relacionamento comercial.

- **Clientes**: Cadastro com dados fiscais
- **Fornecedores**: Gestão de fornecedores
- **Notas Fiscais**: Emissão e recebimento (NFe/NFSe)
- **Pedidos de Venda**: Fluxo de vendas
- **Contas a Receber**: Gestão de créditos
- **Contas a Pagar**: Gestão de débitos

**Arquivos**: `clientes.html` | `fornecedores.html` | `notas_fiscais.html` | `contas_receber.html` | `contas_pagar.html`

### 6. **Módulo Operacional** ⚙️
Configurações e manutenção.

- **Conciliação Bancária**: Matching de transações
- **Configurações**: Parâmetros do sistema
- **Auditoria**: Log de operações
- **Backup**: Exportação de dados

**Arquivos**: `conciliacao.html` | `configuracoes.html`

---

## 📁 Estrutura de Arquivos

```
luma-contabilidade/
├── README.md                                    # Este arquivo
├── LICENSE                                      # MIT License
├── .github/
│   └── workflows/                               # CI/CD workflows (future)
│       ├── test.yml
│       └── deploy.yml
│
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql              # 20+ tabelas, 60+ índices
│   │   ├── 002_rls_policies.sql                # Row Level Security
│   │   └── 003_seed_data.sql                   # Dados iniciais (CoA, etc)
│   │
│   └── config.toml                             # Configuração local Supabase
│
├── scripts/
│   ├── supabase_client_contab.js               # 108+ funções Supabase
│   ├── auth.js                                 # Autenticação (future)
│   ├── validators.js                           # Validações de negócio
│   └── utils.js                                # Funções utilitárias
│
├── public/
│   ├── index.html                              # Página inicial/home
│   ├── login.html                              # Tela de login
│   ├── dashboard.html                          # Dashboard principal
│   │
│   ├── fiscal/
│   │   ├── apuracoes.html                      # Apurações de impostos
│   │   └── calendario_fiscal.html              # Calendário fiscal
│   │
│   ├── contabil/
│   │   ├── plano_contas.html                   # Plano de contas
│   │   └── lancamentos.html                    # Diário contábil
│   │
│   ├── comercial/
│   │   ├── clientes.html                       # Gestão de clientes
│   │   ├── fornecedores.html                   # Gestão de fornecedores
│   │   ├── notas_fiscais.html                  # NF-e/NFS-e
│   │   ├── contas_receber.html                 # Contas a receber
│   │   └── contas_pagar.html                   # Contas a pagar
│   │
│   ├── gerencial/
│   │   ├── dre.html                            # DRE (resultado)
│   │   └── fluxo_caixa.html                    # Fluxo de caixa
│   │
│   ├── operacional/
│   │   ├── conciliacao.html                    # Conciliação bancária
│   │   └── configuracoes.html                  # Configurações
│   │
│   ├── css/
│   │   ├── main.css                            # Estilos principais
│   │   ├── responsive.css                      # Media queries
│   │   └── components.css                      # Componentes reutilizáveis
│   │
│   ├── js/
│   │   ├── app.js                              # Lógica principal
│   │   ├── router.js                           # Roteamento SPA
│   │   └── state.js                            # Gerenciamento de estado
│   │
│   └── assets/
│       ├── logo.svg
│       └── icons/
│
├── docs/
│   ├── ARCHITECTURE.md                         # Documentação técnica
│   ├── API.md                                  # Referência de APIs
│   ├── FISCAL.md                               # Guia fiscal
│   ├── DATABASE.md                             # Schema do banco
│   └── DEPLOYMENT.md                           # Guia de deployment
│
└── .gitignore
```

---

## 🚀 Setup & Instalação

### Pré-requisitos

- Node.js 18+ (para CLI do Supabase)
- Uma conta no [Supabase](https://supabase.com) (gratuita)
- Git
- Navegador moderno (Chrome, Firefox, Safari, Edge)

### 1. Clonar o Repositório

```bash
git clone https://github.com/AndersonAssisSouza/luma-contabilidade.git
cd luma-contabilidade
```

### 2. Configurar Projeto Supabase

#### 2.1 Criar Projeto no Supabase

1. Acesse [app.supabase.com](https://app.supabase.com)
2. Clique em "New Project"
3. Configure:
   - **Project Name**: `luma-contabilidade`
   - **Database Password**: Guarde em local seguro
   - **Region**: Selecione região mais próxima (ex: São Paulo)
4. Clique em "Create new project"
5. Aguarde a inicialização (5-10 minutos)

#### 2.2 Obter Credenciais

Após criar o projeto:

1. Vá para **Settings** → **API**
2. Copie:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Anon Key**: `eyJhbGc...` (chave pública)
   - **Service Role Key**: `eyJhbGc...` (chave privada - guarde em segurança)

3. Crie um arquivo `.env.local` na raiz do projeto:

```bash
# .env.local
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
```

### 3. Instalar Supabase CLI

```bash
npm install -g supabase
```

### 4. Executar Migrations

```bash
# Login no Supabase
supabase login

# Link ao projeto
supabase link --project-ref xxxxx

# Executar migrations
supabase db push
```

As migrations executarão nesta ordem:
1. `001_initial_schema.sql` - Cria tabelas e índices
2. `002_rls_policies.sql` - Configura RLS policies
3. `003_seed_data.sql` - Popula dados iniciais

### 5. Configurar Autenticação

#### 5.1 Habilitar Email/Password Auth

1. No Supabase Dashboard, vá para **Authentication** → **Providers**
2. Habilite **Email** (padrão)
3. Copie os dados para `public/login.html`

#### 5.2 Criar Primeiro Usuário (Manager Global)

```sql
-- No SQL Editor do Supabase
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  aud,
  role,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'admin@sua-empresa.com.br',
  crypt('SenhaForte123!', gen_salt('bf')),
  NOW(),
  'authenticated',
  'authenticated',
  NOW(),
  NOW()
);

-- Criar registro de usuário na tabela users
INSERT INTO public.users (
  id,
  tenant_id,
  email,
  full_name,
  role,
  is_active
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  (SELECT id FROM tenants LIMIT 1),
  'admin@sua-empresa.com.br',
  'Administrador',
  'manager_global',
  true
);
```

### 6. Iniciar Desenvolvimento Local

```bash
# Iniciar servidor local Supabase (opcional)
supabase start

# Abrir em navegador (usar live server ou python)
python -m http.server 8000
# ou
npx http-server
```

Acesse: `http://localhost:8000/public/login.html`

---

## 👥 Papéis de Usuário (RBAC)

O sistema possui 5 níveis de acesso gerenciados via RLS:

| Papel | Permissões | Casos de Uso |
|-------|-----------|-------------|
| **manager_global** | Acesso total ao sistema | Proprietário/Sócio |
| **master** | Gestão contábil + fiscal completa | Contador responsável |
| **contador** | Leitura e escrita contábil | Analista contábil |
| **operador** | Operações de rotina | Recepcionista/Auxiliar |
| **visualizador** | Apenas leitura | Consultas/Relatórios |

Cada operação é validada em duas camadas:
1. **Frontend**: Desabilita UI baseado no role
2. **Backend (RLS)**: PostgreSQL rejeita query se não autorizado

---

## 🔐 Segurança

### Row Level Security (RLS)

Todos as tabelas possuem RLS habilitado:

```sql
-- Exemplo de política RLS
CREATE POLICY "tenant_isolation" ON lancamentos
FOR ALL USING (tenant_id = auth.uid()::uuid);
```

### Proteções Implementadas

- ✅ **Isolamento de Tenant**: Todos queries filtram por `tenant_id`
- ✅ **JWT Token**: Autenticação sem sessão
- ✅ **HTTPS Obrigatório**: Em produção
- ✅ **CORS Configurado**: Apenas domínios autorizados
- ✅ **SQL Injection Prevention**: Prepared statements via Supabase
- ✅ **Validação Frontend**: Tipos e ranges
- ✅ **Rate Limiting**: Planejado para v2.0

---

## 📚 Banco de Dados

### Tabelas Principais (20+)

```sql
-- Estrutura simplificada

tenants
├── id (UUID)
├── name (TEXT)
├── cnpj (TEXT)
└── created_at (TIMESTAMP)

users
├── id (UUID)
├── tenant_id (UUID FK)
├── email (TEXT)
├── role (ENUM)
└── is_active (BOOLEAN)

contas (Plano de Contas)
├── id (UUID)
├── tenant_id (UUID FK)
├── numero (TEXT)
├── descricao (TEXT)
├── tipo (ENUM: ativo, passivo, receita, despesa)
└── saldo (NUMERIC)

lancamentos (Diário)
├── id (UUID)
├── tenant_id (UUID FK)
├── data (DATE)
├── numero (TEXT)
├── descricao (TEXT)
├── itens (JSONB)
└── status (ENUM: rascunho, confirmado, anulado)

clientes
├── id (UUID)
├── tenant_id (UUID FK)
├── nome_razao_social (TEXT)
├── cpf_cnpj (TEXT)
└── endereco (JSONB)

fornecedores
├── id (UUID)
├── tenant_id (UUID FK)
├── nome_razao_social (TEXT)
├── cpf_cnpj (TEXT)
└── endereco (JSONB)

notas_fiscais
├── id (UUID)
├── tenant_id (UUID FK)
├── numero (TEXT)
├── cliente_id (UUID FK)
├── valor_total (NUMERIC)
└── status (ENUM: emitida, recebida, anulada)

contas_receber
├── id (UUID)
├── tenant_id (UUID FK)
├── nf_id (UUID FK)
├── data_vencimento (DATE)
├── valor (NUMERIC)
└── status (ENUM: aberta, paga, vencida)

contas_pagar
├── id (UUID)
├── tenant_id (UUID FK)
├── fornecedor_id (UUID FK)
├── data_vencimento (DATE)
├── valor (NUMERIC)
└── status (ENUM: aberta, paga, vencida)

apuracoes_fiscais
├── id (UUID)
├── tenant_id (UUID FK)
├── periodo (TEXT: YYYY-MM)
├── irpj (NUMERIC)
├── csll (NUMERIC)
├── pis_cofins (NUMERIC)
└── status (ENUM: aberta, apurada, paga)

calendario_fiscal
├── id (UUID)
├── tenant_id (UUID FK)
├── obrigacao (TEXT)
├── data_vencimento (DATE)
└── status (ENUM: pendente, cumprida, atrasada)
```

### Índices de Performance (60+)

```sql
CREATE INDEX idx_lancamentos_tenant_data
  ON lancamentos(tenant_id, data DESC);

CREATE INDEX idx_lancamentos_conta_data
  ON lancamentos(conta_id, data DESC);

CREATE INDEX idx_contas_tenant_numero
  ON contas(tenant_id, numero);

-- Índices compostos para queries comuns
CREATE INDEX idx_contas_receber_tenant_status
  ON contas_receber(tenant_id, status, data_vencimento);
```

---

## 📖 Guia de Desenvolvimento

### Arquitetura Frontend

```
scripts/supabase_client_contab.js (108+ funções)
├── Autenticação
│   ├── login()
│   ├── logout()
│   ├── getCurrentUser()
│   └── updateProfile()
├── Contábil
│   ├── criarLancamento()
│   ├── atualizarLancamento()
│   ├── deletarLancamento()
│   ├── listarLancamentos()
│   ├── getPlanoContas()
│   └── getBalancete()
├── Fiscal
│   ├── apurarIRPJ()
│   ├── apurarCSLL()
│   ├── apurarPISCOFINS()
│   ├── apurarISS()
│   └── getCalendarioFiscal()
├── Comercial
│   ├── criarCliente()
│   ├── criarFornecedor()
│   ├── emitirNotaFiscal()
│   ├── registrarContagemReceber()
│   └── registrarContagemPagar()
└── Gerencial
    ├── getDRE()
    ├── getFluxoCaixa()
    ├── getIndicadores()
    └── getComparativo()
```

### Fluxo de Desenvolvimento

1. **Feature Branch**: `git checkout -b feature/minha-feature`
2. **Desenvolver**: Editar arquivos HTML/JS
3. **Testar Localmente**: `supabase start` + navegador
4. **Commit**: `git commit -m "feat: descrição da feature"`
5. **Push**: `git push origin feature/minha-feature`
6. **Pull Request**: Abrir PR no GitHub

### Padrões de Código

#### Naming Conventions

- **Variáveis**: camelCase (ex: `usuarioAtivo`)
- **Funções**: camelCase (ex: `criarLancamento()`)
- **Classes/Constructores**: PascalCase (ex: `LancamentoContabil`)
- **Constantes**: UPPER_SNAKE_CASE (ex: `TAXA_ISS`)
- **IDs HTML**: kebab-case (ex: `btn-salvar`)

#### Exemplo de Função

```javascript
// Bom - Documentado e com tratamento de erro
/**
 * Cria um novo lançamento contábil
 * @param {Object} lancamento - Dados do lançamento
 * @param {string} lancamento.data - Data no formato YYYY-MM-DD
 * @param {string} lancamento.descricao - Descrição
 * @param {Array} lancamento.itens - Itens [{ conta_id, tipo, valor }]
 * @returns {Promise<Object>} Lançamento criado
 * @throws {Error} Se validação falhar
 */
async function criarLancamento(lancamento) {
  try {
    // Validação
    if (!lancamento.data || !lancamento.itens?.length) {
      throw new Error('Data e itens são obrigatórios');
    }

    // Validar partida dobrada
    const totalDebitos = lancamento.itens
      .filter(i => i.tipo === 'debito')
      .reduce((sum, i) => sum + i.valor, 0);

    const totalCreditos = lancamento.itens
      .filter(i => i.tipo === 'credito')
      .reduce((sum, i) => sum + i.valor, 0);

    if (totalDebitos !== totalCreditos) {
      throw new Error('Débitos devem ser iguais a créditos');
    }

    // Executar
    const { data, error } = await supabase
      .from('lancamentos')
      .insert([lancamento])
      .select();

    if (error) throw error;
    return data[0];
  } catch (error) {
    console.error('Erro ao criar lançamento:', error);
    throw error;
  }
}
```

---

## 🚀 Deployment

### Opção 1: GitHub Pages + Cloudflare Worker (Recomendado)

```bash
# 1. Deploy estático no GitHub Pages
git push origin main

# 2. Habilitar GitHub Pages em Settings → Pages
# 3. Selecionar branch: main, pasta: /public

# 4. Cloudflare Worker para redirects (SPA routing)
# Veja docs/DEPLOYMENT.md para configuração
```

### Opção 2: Vercel

```bash
npm install -g vercel
vercel
# Selecionar pasta: public
```

### Opção 3: Netlify

```bash
npm install -g netlify-cli
netlify deploy --prod --dir=public
```

### Variáveis de Ambiente (Produção)

```bash
# .env.production
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...
VITE_APP_URL=https://seu-dominio.com.br
```

---

## 🗺️ Roadmap

### v1.0 (MVP - Atual)
- [x] Autenticação e RBAC
- [x] Plano de contas
- [x] Lançamentos contábeis
- [x] Apurações fiscais (Lucro Presumido)
- [x] Gestão de clientes e fornecedores
- [x] DRE e fluxo de caixa
- [x] Conciliação bancária

### v1.1 (Q2 2026)
- [ ] Integração com Conta Azul ERP (OAuth 2.0)
- [ ] Integração com LUMA RH (API/Events)
- [ ] Emissão de NFe via Focus NFe API
- [ ] Dashboards avançados
- [ ] Exportação para Excel/PDF

### v2.0 (Q4 2026)
- [ ] Regime Lucro Real
- [ ] Regime Simples Nacional
- [ ] EFD-Contribuições
- [ ] ECF (Escrituração Contábil Fiscal)
- [ ] Integração bancária automática
- [ ] IA para categorização contábil
- [ ] Mobile app nativo

### v3.0 (Futuro)
- [ ] Consolidação de contas
- [ ] Orçamento e planejamento
- [ ] Conformidade IFRS
- [ ] Auditoria interna
- [ ] SLA 99.9%

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/sua-feature`
3. Commit: `git commit -m 'feat: descrição'`
4. Push: `git push origin feature/sua-feature`
5. Abra um Pull Request

### Diretrizes

- Mantenha coerência com o código existente
- Adicione testes para novas features
- Documente mudanças em comentários
- Respeite as políticas RLS

---

## 📞 Suporte

- **Issues**: [GitHub Issues](https://github.com/AndersonAssisSouza/luma-contabilidade/issues)
- **Discussions**: [GitHub Discussions](https://github.com/AndersonAssisSouza/luma-contabilidade/discussions)
- **Email**: contato@lumacontabilidade.com.br

---

## 📄 Documentação Adicional

- [Arquitetura Detalhada](docs/ARCHITECTURE.md)
- [Referência de API](docs/API.md)
- [Guia Fiscal Brasileiro](docs/FISCAL.md)
- [Schema do Banco](docs/DATABASE.md)
- [Guia de Deployment](docs/DEPLOYMENT.md)

---

## 📝 Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE).

```
MIT License

Copyright (c) 2024 Anderson Assis Souza

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

---

## 🙏 Agradecimentos

- [Supabase](https://supabase.com) - Backend as a Service
- [PostgreSQL](https://www.postgresql.org/) - Banco de dados
- Comunidade open-source brasileira

---

<div align="center">

**Desenvolvido com ❤️ para contadores e empresários brasileiros**

[⭐ Star este repositório](https://github.com/AndersonAssisSouza/luma-contabilidade)

</div>
