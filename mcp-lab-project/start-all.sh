#!/bin/bash

# Script para iniciar todos los componentes del laboratorio MCP
# Útil para desarrollo y testing

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "   Iniciando Laboratorio MCP"
echo "=================================================="
echo ""

# Función para cleanup al salir
cleanup() {
    echo ""
    echo "Cerrando todos los servicios..."
    kill $(jobs -p) 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Verificar que todo esté compilado
echo "Verificando compilación..."

if [ ! -d "$PROJECT_ROOT/mcp-ventas-node/dist" ]; then
    echo "Compilando MCP Ventas..."
    cd "$PROJECT_ROOT/mcp-ventas-node"
    npm run build
fi

if [ ! -d "$PROJECT_ROOT/mcp-gateway/dist" ]; then
    echo "Compilando MCP Gateway..."
    cd "$PROJECT_ROOT/mcp-gateway"
    npm run build
fi

cd "$PROJECT_ROOT"

echo ""
echo "Iniciando servicios..."
echo ""

# Iniciar MCP Ventas
echo "[1/3] Iniciando MCP Ventas..."
cd "$PROJECT_ROOT/mcp-ventas-node"
node dist/index.js > /dev/null 2>&1 &
VENTAS_PID=$!
echo "  → MCP Ventas iniciado (PID: $VENTAS_PID)"

sleep 1

# Iniciar MCP Pedidos
echo "[2/3] Iniciando MCP Pedidos..."
cd "$PROJECT_ROOT/mcp-pedidos-py"
source venv/bin/activate
python server.py > /dev/null 2>&1 &
PEDIDOS_PID=$!
echo "  → MCP Pedidos iniciado (PID: $PEDIDOS_PID)"

sleep 1

# Iniciar Gateway
echo "[3/3] Iniciando MCP Gateway..."
cd "$PROJECT_ROOT/mcp-gateway"
node dist/index.js &
GATEWAY_PID=$!
echo "  → MCP Gateway iniciado (PID: $GATEWAY_PID)"

echo ""
echo "=================================================="
echo "Todos los servicios están corriendo"
echo "=================================================="
echo ""
echo "PIDs de los procesos:"
echo "  - Ventas:  $VENTAS_PID"
echo "  - Pedidos: $PEDIDOS_PID"
echo "  - Gateway: $GATEWAY_PID"
echo ""
echo "Logs disponibles en:"
echo "  - mcp-ventas-node/ventas_mcp.log"
echo "  - mcp-pedidos-py/pedidos_mcp.log"
echo "  - mcp-gateway/gateway_mcp.log"
echo ""
echo "Presiona Ctrl+C para detener todos los servicios"
echo ""

# Esperar a que termine el gateway (el proceso principal)
wait $GATEWAY_PID
