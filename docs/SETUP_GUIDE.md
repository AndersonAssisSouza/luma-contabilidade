# Guia de Setup - LUMA Contabilidade

Guia técnico completo para configurar o LUMA Contabilidade com Supabase, autenticação e deploy.

## Sumário

- [Requisitos](#requisitos)
- [Passo 1: Criar Projeto Supabase](#passo-1-criar-projeto-supabase)
- [Passo 2: Obter Credenciais](#passo-2-obter-credenciais)
- [Passo 3: Executar Migrations](#passo-3-executar-migrations)
- [Passo 4: Configurar Autenticação](#passo-4-configurar-autenticação)
- [Passo 5: Configurar Aplicação](#passo-5-configurar-aplicação)
- [Passo 6: Criar Primeiro Admin](#passo-6-criar-primeiro-admin)
- [Passo 7: Deploy GitHub Pages](#passo-7-deploy-github-pages)
- [Passo 8: Domínio Customizado Cloudflare](#passo-8-domínio-customizado-cloudflare)
- [Troubleshooting](#troubleshooting)
- [Security Checklist](#security-checklist)

---

## Requisitos

Antes de começar, certifique-se de ter:

- **Node.js** 16+ instalado (`node --version`)
- **Git** instalado (`git --version`)
- **PostgreSQL Client (psql)** para teste de conexão
  - Ubuntu/Debian: `sudo apt-get install postgresql-client`
  - macOS: `brew install postgresql`
  - Windows: Baixar do [postgresql.org](https://www.postgresql.org/download/)
- **Conta Supabase** criada em [supabase.com](https://supabase.com)
- **Conta GitHub** para deploy via GitHub Pages
- **Conta Cloudflare** (opcional, para domínio customizado)

---

## Passo 1: Criar Projeto Supabase

### 1.1 Acessar Supabase

1. Acesse [app.supabase.com](https://app.supabase.com)
2. Faça login com sua conta (ou crie uma nova)

### 1.2 Criar Novo Projeto

1. Clique no botão **"New Project"** (geralmente na página inicial)
2. Preencha os campos:
   - **Name**: `luma-contabilidade` (ou outro nome preferido)
   - **Database Password**: Crie uma senha forte (mínimo 12 caracteres)
     - Use caracteres especiais: !@#$%^&*()
     - Anote essa senha - você precisará dela
   - **Region**: Selecione a região mais próxima (ex: `sa-east-1` para Brasil)
   - **Pricing Plan**: Selecione "Free" para começar (pode fazer upgrade depois)

3. Clique em **"Create new project"**

> ⏳ O projeto levará alguns minutos para inicializar. Aguarde a conclusão.

### 1.3 Verificar Projeto Criado

Após a inicialização:
- Você será redirecionado para o dashboard do projeto
- A URL do projeto aparecerá na barra de endereço (ex: `https://xxxxxx.supabase.co`)
- Um banner de sucesso será exibido

---

## Passo 2: Obter Credenciais

### 2.1 URL do Projeto

1. No dashboard Supabase, clique em **"Settings"** (canto inferior esquerdo)
2. Selecione aba **"API"**
3. Em **"Project URL"**, copie o valor completo
   - Formato: `https://xxxxxxxxxxxxx.supabase.co`
4. **Salve em um local seguro** (será necessário em breve)

### 2.2 Chaves de Autenticação

Ainda na aba **"API"** do Settings:

#### Anon Key (Chave Pública)
1. Localize a seção **"Project API keys"**
2. Copie o valor em **"anon public"**
   - Começa com `eyJhbGciOiJI...`
3. Esta é a **SUPABASE_ANON_KEY**

#### Service Role Key (Chave de Serviço)
1. Na mesma seção, copie o valor em **"service_role secret"**
   - Começa com `eyJhbGciOiJI...` (mas é diferente)
2. Esta é a **SUPABASE_SERVICE_KEY**
3. ⚠️ **GUARDE ESTA CHAVE COM SEGURANÇA** - não compartilhe!

### 2.3 Banco de Dados - Informações

1. Clique em **"Database"** (menu lateral)
2. Selecione aba **"Connection pooler"** ou **"Connection info"**
3. Anote:
   - **Host**: `xxxxx.supabase.co`
   - **Port**: `5432`
   - **Database**: `postgres`
   - **User**: `postgres`
   - **Password**: A senha que você criou no Passo 1.2

---

## Passo 3: Executar Migrations

### 3.1 Opção A: Usar Script Automático (Recomendado)

#### Preparar Variáveis de Ambiente

```bash
export SUPABASE_URL="https://xxxxxxxxxxxxx.supabase.co"
export SUPABASE_ANON_KEY="eyJhbGciOiJI..."
export SUPABASE_SERVICE_KEY="eyJhbGciOiJI..."
```

#### Executar Script

```bash
# Navegar para o diretório do projeto
cd luma-contabilidade

# Dar permissão de execução ao script
chmod +x scripts/setup_supabase.sh

# Executar o script
./scripts/setup_supabase.sh
```

O script irá:
- ✓ Validar dependências (psql, supabase CLI)
- ✓ Solicitar credenciais (se não estiverem em env vars)
- ✓ Executar as 3 migrations em ordem
- ✓ Atualizar o arquivo `supabase_client_contab.js`
- ✓ Exibir resumo final

### 3.2 Opção B: Execução Manual no Painel Supabase

#### Via SQL Editor

1. No Supabase, clique em **"SQL Editor"** (menu lateral)
2. Clique em **"New Query"**
3. Copie e cole o conteúdo de `migrations/001_initial_schema.sql`
4. Clique em **"Run"** (Ctrl+Enter)
5. Repita para `002_rls_policies.sql` e `003_seed_data.sql`

#### Via psql (Linha de Comando)

```bash
# Conectar ao banco de dados Supabase
psql -h xxxxx.supabase.co -p 5432 -U postgres -d postgres

# Na prompt, executar cada arquivo:
\i migrations/001_initial_schema.sql
\i migrations/002_rls_policies.sql
\i migrations/003_seed_data.sql

# Sair
\q
```

### 3.3 Verificar Execução das Migrations

No SQL Editor do Supabase:

```sql
-- Verificar tabelas criadas
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Verificar se policies foram criadas
SELECT * FROM pg_policies;

-- Verificar dados de seed
SELECT COUNT(*) FROM usuarios;
SELECT COUNT(*) FROM empresas;
```

Todas as tabelas devem estar presentes:
- `usuarios`
- `empresas`
- `clientes`
- `documentos`
- `lancamentos`
- `categorias`
- `auditorias`

---

## Passo 4: Configurar Autenticação

### 4.1 Ativar Email/Password

1. No Supabase, vá para **"Authentication"** (menu lateral)
2. Clique em **"Providers"**
3. Localize **"Email"** na lista
4. Clique no toggle para ativar ✓
5. Expanda a seção "Email" e configure:
   - **Enable email confirmations**: ON (para segurança)
   - **Email templates**: Deixar com defaults (ou customizar se desejar)

### 4.2 Configurar URLs de Redirecionamento

1. Em **"Authentication"** > **"URL Configuration"**
2. Seção **"Redirect URLs"**:
   - Adicione URL local: `http://localhost:8000`
   - Adicione URL de staging: `https://seu-username.github.io`
   - Adicione URL customizada (se usar domínio próprio): `https://seu-dominio.com`

3. Clique em **"Save"**

### 4.3 Configurar SMTP (Opcional, Para Produção)

Para enviar e-mails de autenticação:

1. Em **"Authentication"** > **"Email Templates"**
2. Clique em **"SMTP Settings"**
3. Configure seu provedor de SMTP:
   - SendGrid
   - AWS SES
   - Mailgun
   - Seu servidor SMTP próprio

> **Dica**: Por enquanto, você pode usar a solução padrão do Supabase para testes.

### 4.4 Ativar 2FA (Adicional)

Para maior segurança:

1. Em **"Authentication"** > **"Factors"**
2. Ative **"TOTP"** (Time-based One-Time Password)
3. Configure conforme necessário

---

## Passo 5: Configurar Aplicação

### 5.1 Atualizar supabase_client_contab.js

O script automático (Passo 3.1) faz isso automaticamente.

Se você executou manualmente:

1. Abra o arquivo `supabase_client_contab.js`
2. Localize as linhas:
   ```javascript
   const SUPABASE_URL = 'https://xxxxx.supabase.co';
   const SUPABASE_KEY = 'eyJhbGciOiJI...';
   ```

3. Substitua pelos seus valores (obtidos no Passo 2):
   - `SUPABASE_URL`: URL do projeto
   - `SUPABASE_KEY`: Sua SUPABASE_ANON_KEY

4. Salve o arquivo

### 5.2 Instalar Dependências

```bash
cd luma-contabilidade

# Se usar npm
npm install

# Se usar yarn
yarn install

# Se usar pnpm
pnpm install
```

### 5.3 Variáveis de Ambiente (Opcional)

Crie arquivo `.env.local` na raiz do projeto:

```env
VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJI...
```

> **Nota**: Não compartilhe este arquivo. Adicione `.env.local` ao `.gitignore`.

### 5.4 Testar Localmente

```bash
# Iniciar servidor de desenvolvimento
npm run dev

# A aplicação estará disponível em:
# http://localhost:5173 (Vite)
# ou http://localhost:3000 (conforme seu setup)
```

Teste:
1. Acesse http://localhost:5173
2. Clique em "Login" ou "Cadastro"
3. Crie uma conta de teste
4. Verifique se consegue acessar o dashboard

---

## Passo 6: Criar Primeiro Admin

### 6.1 Criar Usuário Admin no Painel

1. No Supabase, vá para **"Authentication"** > **"Users"**
2. Clique em **"Add user"**
3. Preencha:
   - **Email**: seu-email@exemplo.com
   - **Password**: Senha forte (você pode trocar depois)
   - **Auto confirm user**: ✓ (marque para ativar imediatamente)

4. Clique em **"Create user"**

### 6.2 Designar Usuário Como Admin

Via SQL Editor no Supabase:

```sql
-- Substituir 'seu-email@exemplo.com' pelo e-mail que criou
UPDATE usuarios
SET role = 'admin', ativo = true
WHERE auth_id = (
    SELECT id FROM auth.users WHERE email = 'seu-email@exemplo.com'
);
```

Ou manualmente pelo aplicativo:

1. Faça login com a conta criada
2. Acesse a seção de **"Administração"** > **"Usuários"**
3. Encontre o usuário
4. Altere o role para **"Admin"**
5. Salve

### 6.3 Verificar Acesso

1. Faça logout
2. Faça login novamente com a conta admin
3. Você deve ter acesso a todas as funcionalidades de administração

---

## Passo 7: Deploy GitHub Pages

### 7.1 Preparar Repositório GitHub

#### Se ainda não tem repositório:

```bash
# Inicializar git (se não tiver)
git init

# Adicionar remote GitHub
git remote add origin https://github.com/seu-usuario/luma-contabilidade.git

# Criar arquivo .gitignore
cat > .gitignore << EOF
node_modules/
dist/
.env.local
.env.*.local
*.log
.DS_Store
EOF

# Commit inicial
git add .
git commit -m "Initial commit: LUMA Contabilidade setup"
git branch -M main
git push -u origin main
```

#### Se já tem repositório:

```bash
# Certifique-se de estar na branch main
git checkout main
git pull origin main

# Atualizar .gitignore se necessário
```

### 7.2 Configurar Variáveis de Deploy

No **GitHub**:

1. Vá para **Settings** > **Secrets and variables** > **Actions**
2. Clique em **"New repository secret"**
3. Adicione:
   - **Nome**: `VITE_SUPABASE_URL`
   - **Valor**: Sua URL do Supabase

4. Clique em **"New repository secret"** novamente
5. Adicione:
   - **Nome**: `VITE_SUPABASE_ANON_KEY`
   - **Valor**: Sua chave anônima do Supabase

> **Importante**: Não exponha a SUPABASE_SERVICE_KEY no GitHub!

### 7.3 Criar GitHub Actions Workflow

Se não tiver, crie o arquivo `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'

    - name: Install dependencies
      run: npm ci

    - name: Build
      run: npm run build
      env:
        VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
        VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}

    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./dist
```

### 7.4 Ativar GitHub Pages

1. No repositório GitHub, vá para **Settings** > **Pages**
2. Em **"Source"**, selecione **"Deploy from a branch"**
3. Selecione branch: **`gh-pages`**
4. Selecione pasta: **`/ (root)`**
5. Clique em **"Save"**

> A URL será: `https://seu-usuario.github.io/luma-contabilidade`

### 7.5 Fazer Deploy

```bash
# Adicionar as mudanças
git add .

# Commit
git commit -m "Configure GitHub Pages deployment"

# Push
git push origin main
```

O GitHub Actions irá:
1. Fazer build da aplicação
2. Deploy automaticamente para GitHub Pages
3. A aplicação estará disponível em poucos minutos

**Status do deploy**: Veja em **Actions** no seu repositório GitHub.

---

## Passo 8: Domínio Customizado Cloudflare

### 8.1 Registrar Domínio

Opções:
- Registrar em [Namecheap](https://www.namecheap.com)
- Registrar em [Google Domains](https://domains.google.com)
- Registrar em outro registrador preferido

**Exemplo**: `seu-dominio.com` (aprox. $10-15/ano)

### 8.2 Transferir para Cloudflare (Recomendado)

1. Crie conta em [cloudflare.com](https://www.cloudflare.com)
2. Clique em **"Add a domain"**
3. Insira seu domínio: `seu-dominio.com`
4. Selecione plano **"Free"**
5. Cloudflare irá escanear registros DNS existentes
6. Clique em **"Continue"**
7. Cloudflare mostrará nameservers para você usar
8. Vá ao seu registrador original
9. Altere os nameservers para os do Cloudflare
10. Aguarde propagação DNS (até 48h, geralmente minutos)

### 8.3 Configurar DNS no Cloudflare

1. Em Cloudflare, vá para **DNS**
2. Adicione registro:
   - **Type**: `CNAME`
   - **Name**: `@` (ou `www`)
   - **Content**: `seu-usuario.github.io`
   - **TTL**: Auto
   - **Proxy status**: Proxied (laranja)

3. Clique em **"Save"**

### 8.4 Configurar HTTPS

1. Em Cloudflare, vá para **SSL/TLS**
2. Selecione modo: **"Full"** ou **"Full (strict)"**
3. Em **"Edge Certificates"**, habilite:
   - **Auto HTTPS Rewrites**: ON
   - **Always Use HTTPS**: ON

### 8.5 Configurar Redirects no GitHub Pages

1. Na raiz do projeto, crie arquivo `CNAME`:

```
seu-dominio.com
```

2. Commit e push:

```bash
git add CNAME
git commit -m "Add custom domain CNAME"
git push origin main
```

### 8.6 Configurar Redirecionamento de URLs no Supabase

1. No Supabase, vá para **Authentication** > **URL Configuration**
2. Adicione seu domínio customizado em **Redirect URLs**:
   - `https://seu-dominio.com`
   - `https://seu-dominio.com/auth`

3. Clique em **"Save"**

### 8.7 Testar Acesso

Após propagação DNS:
- Acesse `https://seu-dominio.com`
- Deveria carregar a aplicação
- HTTPS deveria estar ativo (verde no navegador)

---

## Troubleshooting

### Problema: "Connection refused" ao executar migrations

**Causa**: Credenciais incorretas ou firewall bloqueando.

**Solução**:
1. Verifique URL e credenciais (Passo 2)
2. Teste conexão: `psql -h xxxxx.supabase.co -U postgres -d postgres`
3. No Supabase, vá para **Settings** > **Network** e verifique whitelist de IPs
4. Se usar Cloud Shell (GitHub), IP pode variar - adicione `0.0.0.0/0` temporariamente (depois ajuste)

### Problema: "Relation does not exist" no login

**Causa**: Migrations não foram executadas corretamente.

**Solução**:
1. Vá para SQL Editor no Supabase
2. Execute: `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';`
3. Se tabelas estão faltando, re-execute as migrations
4. Verifique se não há erros nas migrations (check console output)

### Problema: "Policy violation" ao inserir dados

**Causa**: RLS (Row Level Security) política bloqueando.

**Solução**:
1. Verifique se RLS está configurado corretamente em `002_rls_policies.sql`
2. No SQL Editor, desabilite RLS temporariamente para testes:
   ```sql
   ALTER TABLE usuarios DISABLE ROW LEVEL SECURITY;
   ALTER TABLE empresas DISABLE ROW LEVEL SECURITY;
   -- ... e assim por diante
   ```
3. Depois re-habilite e ajuste as políticas

### Problema: GitHub Pages não carrega (404 ou blank page)

**Causa**: Build falhou ou caminho incorreto.

**Solução**:
1. Verifique o **Actions** do GitHub - há algum erro no workflow?
2. Se build passou, verifique em **Settings** > **Pages** se a branch `gh-pages` e pasta estão corretas
3. Limpe cache do navegador (Ctrl+Shift+Delete)
4. Verifique console do navegador (F12) para erros de JavaScript

### Problema: Autenticação não funciona

**Causa**: Chave anônima incorreta ou URL não configurada.

**Solução**:
1. Verifique `supabase_client_contab.js` - URL e chave estão corretas?
2. No console do navegador (F12), procure erros de CORS
3. No Supabase, verifique **Auth** > **URL Configuration** - seu domínio está listado?
4. Teste com usuário criado manualmente no painel do Supabase

### Problema: Email de confirmação não chega

**Causa**: SMTP não configurado ou em spam.

**Solução**:
1. Verifique pasta Spam/Lixo do e-mail
2. Configure SMTP adequado em **Authentication** > **SMTP Settings**
3. Ou, desabilite email confirmations em **Authentication** > **Providers** > **Email** (apenas para desenvolvimento)

### Problema: "Service Key" exposto acidentalmente

**Ação Imediata**:
1. No Supabase, vá para **Settings** > **API**
2. Clique em **"Rotate"** na Service Role Key
3. Atualize seu arquivo `.env.local` com a nova chave
4. Remova a chave antiga de qualquer lugar (commits, logs, etc.)

---

## Security Checklist

### Antes de Deploy em Produção

- [ ] **Credenciais Supabase**:
  - [ ] Não expostas em código
  - [ ] Armazenadas apenas em variáveis de ambiente
  - [ ] Service Key nunca commitada

- [ ] **Autenticação**:
  - [ ] Email confirmation habilitado
  - [ ] 2FA configurado para admins
  - [ ] Senhas de admins são fortes (12+ caracteres, especiais)
  - [ ] Políticas RLS foram testadas

- [ ] **Banco de Dados**:
  - [ ] RLS ativado em todas as tabelas
  - [ ] Triggers de auditoria testados
  - [ ] Backup automático configurado no Supabase
  - [ ] Connection pooler ativado se usar muitas conexões

- [ ] **GitHub Pages / Deploy**:
  - [ ] `.env.local` está em `.gitignore`
  - [ ] Secrets configurados no GitHub Actions
  - [ ] Branch protegida (require pull request reviews)
  - [ ] Apenas chaves públicas (anon key) em variáveis públicas

- [ ] **Cloudflare (se usar)**:
  - [ ] HTTPS forçado
  - [ ] DDoS protection ativado
  - [ ] WAF regras configuradas (se usar plano pago)

- [ ] **RGPD/Privacidade**:
  - [ ] Política de Privacidade publicada
  - [ ] Termos de Serviço publicados
  - [ ] Consentimento de cookies (se necessário por lei)
  - [ ] Dados deletados conforme LGPD (Brasil)

- [ ] **Monitoring**:
  - [ ] Logs habilitados no Supabase
  - [ ] Alertas configurados para erros
  - [ ] Monitoramento de performance ativado

- [ ] **Backups**:
  - [ ] Backup automático configurado (mínimo diário)
  - [ ] Teste de restore realizado
  - [ ] Retenção de backups definida

### Checklist de Desenvolvimento

- [ ] Código foi revisado (code review)
- [ ] Testes passam (unit, integration)
- [ ] Sem console.log() de dados sensíveis
- [ ] Sem hardcoded secrets no código
- [ ] Performance testada (build < 5s idealmente)
- [ ] Mobile responsivo testado

---

## Contato e Suporte

Para dúvidas ou problemas:

1. Verifique esta documentação novamente
2. Consulte a seção Troubleshooting acima
3. Abra uma issue no repositório GitHub
4. Procure documentação oficial:
   - [Supabase Docs](https://supabase.com/docs)
   - [GitHub Pages Docs](https://docs.github.com/en/pages)
   - [Cloudflare Docs](https://developers.cloudflare.com)

---

## Versão e Histórico

- **v1.0** (2026-03-27): Documentação inicial completa
  - Setup Supabase
  - Migrations e banco de dados
  - Autenticação
  - Deploy GitHub Pages
  - Domínio customizado
  - Security checklist

---

**Última atualização**: 2026-03-27
