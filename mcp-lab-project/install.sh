#!/bin/bash

# Script de instalación automatizada para el Laboratorio MCP
# Este script instala todas las dependencias y configura el proyecto

set -e  # Salir si hay algún error

echo "=================================================="
echo "   Laboratorio MCP - Script de Instalación"
echo "=================================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar requisitos
log_info "Verificando requisitos..."

# Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js no está instalado. Por favor instala Node.js 18+ primero."
    exit 1
fi
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    log_error "Node.js versión $NODE_VERSION detectada. Se requiere versión 18 o superior."
    exit 1
fi
log_info "Node.js $(node -v) ✓"

# Python
if ! command -v python &> /dev/null; then
    log_error "Python 3 no está instalado. Por favor instala Python 3.11+ primero."
    exit 1
fi
log_info "Python $(python --version) ✓"

# PostgreSQL
if ! command -v psql &> /dev/null; then
    log_warn "psql no encontrado. Asegúrate de tener PostgreSQL instalado o usar Docker."
else
    log_info "PostgreSQL $(psql --version | cut -d' ' -f3) ✓"
fi

echo ""
log_info "Todos los requisitos están satisfechos."
echo ""

# Obtener directorio del script
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# 1. Configurar MCP Ventas
echo "=================================================="
log_info "1/4 Configurando MCP Ventas (Node.js)..."
echo "=================================================="

cd mcp-ventas-node

if [ ! -f ".env" ]; then
    log_info "Creando archivo .env desde .env.example..."
    cp .env.example .env
    log_warn "Por favor edita mcp-ventas-node/.env con tus credenciales de PostgreSQL"
fi

log_info "Instalando dependencias de Node.js..."
npm install

log_info "Compilando TypeScript..."
npm run build

log_info "MCP Ventas configurado ✓"
echo ""

# 2. Configurar MCP Pedidos
echo "=================================================="
log_info "2/4 Configurando MCP Pedidos (Python)..."
echo "=================================================="

cd ../mcp-pedidos-py

if [ ! -f ".env" ]; then
    log_info "Creando archivo .env desde .env.example..."
    cp .env.example .env
    log_warn "Por favor edita mcp-pedidos-py/.env con tus credenciales de PostgreSQL"
fi

if [ ! -d "venv" ]; then
    log_info "Creando entorno virtual de Python..."
    python -m venv venv
fi

log_info "Activando entorno virtual e instalando dependencias..."
source venv/Scripts/activate
pip install -r requirements.txt
deactivate

log_info "MCP Pedidos configurado ✓"
echo ""

# 3. Configurar Gateway
echo "=================================================="
log_info "3/4 Configurando MCP Gateway..."
echo "=================================================="

cd ../mcp-gateway

log_info "Instalando dependencias de Node.js..."
npm install

log_info "Compilando TypeScript..."
npm run build

log_info "MCP Gateway configurado ✓"
echo ""

# 4. Configurar Base de Datos
echo "=================================================="
log_info "4/4 Configurando Base de Datos..."
echo "=================================================="

cd "$PROJECT_ROOT"

read -p "¿Deseas cargar los datos de ejemplo en PostgreSQL ahora? (s/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    read -p "Usuario de PostgreSQL (default: postgres): " PG_USER
    PG_USER=${PG_USER:-postgres}
    
    read -p "Base de datos (default: mcp_lab): " PG_DB
    PG_DB=${PG_DB:-mcp_lab}
    
    log_info "Ejecutando script SQL..."
    if psql -U "$PG_USER" -d "$PG_DB" -f sql/setup_database.sql; then
        log_info "Base de datos configurada exitosamente ✓"
    else
        log_error "Error al cargar datos. Puedes ejecutar manualmente:"
        echo "  psql -U $PG_USER -d $PG_DB -f sql/setup_database.sql"
    fi
else
    log_info "Omitiendo configuración de base de datos."
    log_warn "Recuerda ejecutar sql/setup_database.sql manualmente:"
    echo "  psql -U postgres -d mcp_lab -f sql/setup_database.sql"
fi

echo ""
echo "=================================================="
log_info "Instalación Completada!"
echo "=================================================="
echo ""
echo "Próximos pasos:"
echo ""
echo "1. Edita los archivos .env con tus credenciales de PostgreSQL:"
echo "   - mcp-ventas-node/.env"
echo "   - mcp-pedidos-py/.env"
echo ""
echo "2. Si no lo hiciste, carga los datos de ejemplo:"
echo "   psql -U postgres -d mcp_lab -f sql/setup_database.sql"
echo ""
echo "3. Configura Claude Desktop:"
echo "   - Abre Settings → Developer → Edit Config"
echo "   - Agrega la configuración del gateway (ver README.md)"
echo ""
echo "4. Inicia el gateway:"
echo "   cd mcp-gateway"
echo "   npm start"
echo ""
echo "Para más información, consulta README.md"
echo ""
