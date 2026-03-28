#!/bin/bash

#################################################################################
# Setup Supabase para LUMA Contabilidade
# Este script automatiza a configuração do Supabase incluindo:
# - Validação de dependências
# - Execução de migrations
# - Configuração do cliente JavaScript
#################################################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Validar dependências
check_dependencies() {
    print_header "Verificando Dependências"

    local missing_deps=()

    # Verificar se psql está instalado
    if ! command -v psql &> /dev/null; then
        missing_deps+=("psql (PostgreSQL client)")
    else
        print_success "psql encontrado"
    fi

    # Verificar se supabase CLI está instalado
    if ! command -v supabase &> /dev/null; then
        print_warning "Supabase CLI não encontrado - será usada a autenticação direta via psql"
    else
        print_success "Supabase CLI encontrado"
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Dependências faltando:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        return 1
    fi

    return 0
}

# Obter credenciais do Supabase
get_credentials() {
    print_header "Obtendo Credenciais do Supabase"

    # Tentar obter variáveis de ambiente
    SUPABASE_URL="${SUPABASE_URL:-}"
    SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
    SUPABASE_SERVICE_KEY="${SUPABASE_SERVICE_KEY:-}"

    # Se não estiverem definidas, solicitar ao usuário
    if [ -z "$SUPABASE_URL" ]; then
        print_info "URL do Supabase não encontrada em SUPABASE_URL"
        read -p "Digite a URL do Supabase (https://xxxx.supabase.co): " SUPABASE_URL
    fi

    if [ -z "$SUPABASE_ANON_KEY" ]; then
        print_info "Chave anônima não encontrada em SUPABASE_ANON_KEY"
        read -sp "Digite a chave anônima (anon key): " SUPABASE_ANON_KEY
        echo ""
    fi

    if [ -z "$SUPABASE_SERVICE_KEY" ]; then
        print_info "Chave de serviço não encontrada em SUPABASE_SERVICE_KEY"
        read -sp "Digite a chave de serviço (service role key): " SUPABASE_SERVICE_KEY
        echo ""
    fi

    # Validar credenciais
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ] || [ -z "$SUPABASE_SERVICE_KEY" ]; then
        print_error "Credenciais incompletas. Operação cancelada."
        return 1
    fi

    print_success "Credenciais obtidas"
}

# Extrair informações do Supabase
extract_db_info() {
    # Extrair host da URL
    SUPABASE_HOST=$(echo "$SUPABASE_URL" | sed 's|https://||g' | sed 's|\.supabase\.co||g' | sed 's|\.co||g')

    # Construir variáveis de conexão
    DB_HOST="${SUPABASE_HOST}.supabase.co"
    DB_PORT="5432"
    DB_NAME="postgres"
    DB_USER="postgres"

    print_info "Host do banco: $DB_HOST"
}

# Função para executar migration
run_migration() {
    local migration_file=$1
    local migration_number=$2

    if [ ! -f "$migration_file" ]; then
        print_error "Arquivo de migration não encontrado: $migration_file"
        return 1
    fi

    print_info "Executando migration: $(basename $migration_file)"

    # Tentar usar supabase CLI se disponível
    if command -v supabase &> /dev/null; then
        if supabase db push --file "$migration_file" 2>/dev/null; then
            print_success "Migration $migration_number executada com sucesso"
            return 0
        fi
    fi

    # Fallback para psql direto
    print_warning "Usando psql direto para executar migration..."

    # Extracting password from service key is not possible, so we'll use PGPASSWORD approach
    # For Supabase, the password is the service_role_key
    PGPASSWORD="$SUPABASE_SERVICE_KEY" psql \
        -h "$DB_HOST" \
        -p "$DB_PORT" \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        -f "$migration_file" 2>/dev/null

    if [ $? -eq 0 ]; then
        print_success "Migration $migration_number executada com sucesso"
        return 0
    else
        print_error "Falha ao executar migration $migration_number"
        return 1
    fi
}

# Executar todas as migrations
run_migrations() {
    print_header "Executando Migrations do Banco de Dados"

    # Obter o diretório do script
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
    MIGRATIONS_DIR="$PROJECT_ROOT/migrations"

    if [ ! -d "$MIGRATIONS_DIR" ]; then
        print_error "Diretório de migrations não encontrado: $MIGRATIONS_DIR"
        return 1
    fi

    print_info "Diretório de migrations: $MIGRATIONS_DIR"

    # Executar migrations em ordem
    local migrations=(
        "001_initial_schema.sql"
        "002_rls_policies.sql"
        "003_seed_data.sql"
    )

    local migration_count=0
    for migration in "${migrations[@]}"; do
        migration_count=$((migration_count + 1))
        migration_path="$MIGRATIONS_DIR/$migration"

        if ! run_migration "$migration_path" "$migration_count"; then
            print_error "Processo interrompido na migration: $migration"
            return 1
        fi
    done

    print_success "Todas as migrations executadas com sucesso"
}

# Atualizar arquivo de cliente JavaScript
update_client_config() {
    print_header "Configurando Cliente JavaScript"

    # Obter o diretório do script
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
    CLIENT_FILE="$PROJECT_ROOT/supabase_client_contab.js"

    if [ ! -f "$CLIENT_FILE" ]; then
        print_warning "Arquivo de cliente não encontrado: $CLIENT_FILE"
        print_info "Você precisará atualizar manualmente o arquivo com as credenciais"
        return 0
    fi

    print_info "Atualizando: $CLIENT_FILE"

    # Criar backup
    if [ -f "$CLIENT_FILE" ]; then
        cp "$CLIENT_FILE" "${CLIENT_FILE}.backup.$(date +%s)"
        print_success "Backup criado: ${CLIENT_FILE}.backup.*"
    fi

    # Atualizar URL e chave no arquivo
    # Escaping caracteres especiais para sed
    ESCAPED_URL=$(printf '%s\n' "$SUPABASE_URL" | sed 's/[&/\]/\\&/g')
    ESCAPED_KEY=$(printf '%s\n' "$SUPABASE_ANON_KEY" | sed 's/[&/\]/\\&/g')

    # Procurar por padrões comuns no arquivo
    if grep -q "const SUPABASE_URL" "$CLIENT_FILE"; then
        sed -i.tmp "s|const SUPABASE_URL = '.*'|const SUPABASE_URL = '$ESCAPED_URL'|g" "$CLIENT_FILE"
    fi

    if grep -q "const SUPABASE_KEY" "$CLIENT_FILE"; then
        sed -i.tmp "s|const SUPABASE_KEY = '.*'|const SUPABASE_KEY = '$ESCAPED_KEY'|g" "$CLIENT_FILE"
    fi

    if grep -q "const supabaseUrl" "$CLIENT_FILE"; then
        sed -i.tmp "s|const supabaseUrl = '.*'|const supabaseUrl = '$ESCAPED_URL'|g" "$CLIENT_FILE"
    fi

    if grep -q "const supabaseKey" "$CLIENT_FILE"; then
        sed -i.tmp "s|const supabaseKey = '.*'|const supabaseKey = '$ESCAPED_KEY'|g" "$CLIENT_FILE"
    fi

    # Limpar arquivo temporário
    [ -f "${CLIENT_FILE}.tmp" ] && rm "${CLIENT_FILE}.tmp"

    print_success "Cliente JavaScript configurado"
}

# Exibir resumo final
print_summary() {
    print_header "Resumo da Configuração"

    echo -e "${GREEN}Configuração do Supabase concluída com sucesso!${NC}\n"

    echo "Informações configuradas:"
    echo "  URL do Supabase: $SUPABASE_URL"
    echo "  Banco de dados: $DB_NAME @ $DB_HOST"
    echo "  Migrations executadas: 3"
    echo "  Cliente JavaScript: atualizado"
    echo ""

    echo "Próximos passos:"
    echo "  1. Acessar o Painel Supabase: https://app.supabase.com"
    echo "  2. Criar usuários no Authentication"
    echo "  3. Configurar permissões RLS nas tabelas"
    echo "  4. Testar a aplicação localmente"
    echo "  5. Fazer deploy em produção"
    echo ""

    echo "Documentação: Veja SETUP_GUIDE.md para detalhes completos"
    echo ""
}

# Função principal
main() {
    print_header "LUMA Contabilidade - Setup Supabase"

    # Executar etapas
    check_dependencies || exit 1

    get_credentials || exit 1

    extract_db_info

    run_migrations || exit 1

    update_client_config || exit 1

    print_summary

    print_success "Setup concluído com sucesso!"
    exit 0
}

# Executar função principal
main "$@"
