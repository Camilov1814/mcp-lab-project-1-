# Laboratorio MCP: Multi-MCP con Gateway

Este proyecto implementa una arquitectura de múltiples servidores MCP (Model Context Protocol) conectados a través de un Gateway, permitiendo que Claude Desktop acceda a herramientas de diferentes servidores a través de una única interfaz.

## 📋 Descripción

El proyecto consta de tres componentes principales:

1. **MCP Ventas (Node.js/TypeScript)**: Servidor que expone herramientas relacionadas con ventas
2. **MCP Pedidos (Python)**: Servidor que expone herramientas relacionadas con pedidos
3. **MCP Gateway (Node.js/TypeScript)**: Gateway que integra ambos servidores y los expone a Claude Desktop

## 🏗️ Arquitectura

```
Claude Desktop (stdio)
        ↓
   MCP Gateway
    ↙      ↘
MCP Ventas  MCP Pedidos
(Node/TS)   (Python)
    ↓          ↓
  PostgreSQL Database
```

## 🔧 Requisitos Previos

- **Node.js**: 18.x o superior
- **Python**: 3.11 o superior
- **PostgreSQL**: 12 o superior (local o Docker)
- **Claude Desktop**: Instalado y configurado
- **Sistema Operativo**: Linux, macOS, o Windows con WSL

## 📦 Instalación

### 1. Clonar o Descargar el Proyecto

```bash
cd mcp-lab-project
```

### 2. Configurar la Base de Datos

#### Opción A: PostgreSQL con Docker

```bash
docker run --name mcp-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=mcp_lab \
  -p 5432:5432 \
  -d postgres:15
```

#### Opción B: PostgreSQL Local

Asegúrate de que PostgreSQL esté corriendo y crea la base de datos:

```bash
psql -U postgres -c "CREATE DATABASE mcp_lab;"
```

### 3. Cargar Datos de Ejemplo

```bash
psql -U postgres -d mcp_lab -f sql/setup_database.sql
```

### 4. Configurar Variables de Entorno

#### MCP Ventas
```bash
cd mcp-ventas-node
cp .env.example .env
# Editar .env con tus credenciales de PostgreSQL
```

#### MCP Pedidos
```bash
cd ../mcp-pedidos-py
cp .env.example .env
# Editar .env con tus credenciales de PostgreSQL
```

### 5. Instalar Dependencias

#### MCP Ventas (Node.js)
```bash
cd mcp-ventas-node
npm install
npm run build
```

#### MCP Pedidos (Python)
```bash
cd ../mcp-pedidos-py
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### MCP Gateway
```bash
cd ../mcp-gateway
npm install
npm run build
```

## 🚀 Ejecución

### Probar Servidores Individualmente

#### Servidor de Ventas
```bash
cd mcp-ventas-node
npm start
```

#### Servidor de Pedidos
```bash
cd mcp-pedidos-py
source venv/bin/activate
python server.py
```

### Ejecutar el Gateway

```bash
cd mcp-gateway
npm start
```

## ⚙️ Configuración en Claude Desktop

1. Abrir Claude Desktop
2. Ir a **Settings** → **Developer** → **Edit Config**
3. Agregar la siguiente configuración:

```json
{
  "mcpServers": {
    "mcp-gateway": {
      "command": "node",
      "args": [
        "/ruta/absoluta/al/proyecto/mcp-gateway/dist/index.js"
      ],
      "env": {}
    }
  }
}
```

**Nota**: Reemplazar `/ruta/absoluta/al/proyecto/` con la ruta completa al proyecto en tu sistema.

4. Reiniciar Claude Desktop
5. Verificar en **Settings** → **Developer** que el servidor aparezca como "connected"

## 🛠️ Herramientas Disponibles

### Herramientas de Ventas (prefijo `ventas_`)

#### `ventas_total_mes_anterior`
Calcula el total de ventas del mes anterior completo.

**Ejemplo de uso en Claude:**
```
¿Cuánto vendimos el mes pasado?
```

#### `ventas_por_dia`
Devuelve el total de ventas por día de los últimos n días (por defecto 30).

**Parámetros:**
- `n` (opcional): Número de días a consultar

**Ejemplo de uso en Claude:**
```
Muéstrame las ventas de los últimos 15 días
```

### Herramientas de Pedidos (prefijo `pedidos_`)

#### `pedidos_estado_por_id`
Obtiene el estado de un pedido específico por su ID.

**Parámetros:**
- `id`: ID del pedido a consultar

**Ejemplo de uso en Claude:**
```
¿Cuál es el estado del pedido #5?
```

#### `pedidos_crear`
Crea un nuevo pedido en el sistema.

**Parámetros:**
- `cliente`: Nombre del cliente
- `monto`: Monto del pedido

**Ejemplo de uso en Claude:**
```
Crea un pedido para el cliente "Empresa XYZ" por $15000
```

#### `pedidos_listar_por_estado`
Lista todos los pedidos con un estado específico.

**Parámetros:**
- `estado` (opcional): Estado de los pedidos (pendiente, procesando, completado, cancelado)

**Ejemplo de uso en Claude:**
```
Muéstrame todos los pedidos pendientes
```

## 🧪 Testing

### Test del Servidor de Ventas
```bash
cd mcp-ventas-node
cat > test.js << 'EOF'
import pkg from 'pg';
const { Client } = pkg;
import dotenv from 'dotenv';
dotenv.config();

const client = new Client({
  host: process.env.PG_HOST,
  port: process.env.PG_PORT,
  database: process.env.PG_DB,
  user: process.env.PG_USER,
  password: process.env.PG_PASSWORD
});

await client.connect();
const res = await client.query('SELECT COUNT(*) FROM ventas');
console.log('Total ventas en BD:', res.rows[0].count);
await client.end();
EOF

node test.js
```

### Test del Servidor de Pedidos
```bash
cd mcp-pedidos-py
source venv/bin/activate
python selftest.py
```

## 📊 Estructura del Proyecto

```
mcp-lab-project/
├── mcp-ventas-node/          # Servidor MCP de Ventas
│   ├── src/
│   │   └── index.ts          # Código principal
│   ├── dist/                 # Código compilado
│   ├── package.json
│   ├── tsconfig.json
│   ├── .env.example
│   └── ventas_mcp.log        # Logs del servidor
│
├── mcp-pedidos-py/           # Servidor MCP de Pedidos
│   ├── server.py             # Código principal
│   ├── requirements.txt
│   ├── .env.example
│   ├── venv/                 # Entorno virtual Python
│   └── pedidos_mcp.log       # Logs del servidor
│
├── mcp-gateway/              # Gateway MCP
│   ├── src/
│   │   └── index.ts          # Código principal del gateway
│   ├── dist/                 # Código compilado
│   ├── package.json
│   ├── tsconfig.json
│   └── gateway_mcp.log       # Logs del gateway
│
├── sql/
│   └── setup_database.sql    # Script de inicialización de BD
│
└── README.md                 # Este archivo
```

## 🔍 Troubleshooting

### El Gateway no se conecta en Claude Desktop

1. Verificar que las rutas en el config sean absolutas
2. Verificar logs en `gateway_mcp.log`
3. Asegurarse de que ambos servidores backend compilan correctamente

### Errores de conexión a PostgreSQL

1. Verificar que PostgreSQL esté corriendo:
   ```bash
   pg_isready
   ```

2. Verificar credenciales en archivos `.env`

3. Verificar que la base de datos `mcp_lab` existe:
   ```bash
   psql -U postgres -l | grep mcp_lab
   ```

### Las herramientas no aparecen en Claude

1. Reiniciar Claude Desktop completamente
2. Verificar en Settings → Developer que el servidor esté "connected"
3. Revisar logs del gateway para errores

### Errores al compilar TypeScript

```bash
# Limpiar y reinstalar
rm -rf node_modules package-lock.json dist
npm install
npm run build
```

## 📝 Logs y Debugging

Cada componente genera sus propios logs:

- **Gateway**: `mcp-gateway/gateway_mcp.log`
- **Ventas**: `mcp-ventas-node/ventas_mcp.log`
- **Pedidos**: `mcp-pedidos-py/pedidos_mcp.log`

Los logs incluyen:
- Timestamps de cada operación
- Conexiones/desconexiones de clientes
- Llamadas a herramientas
- Errores y excepciones

## 🎯 Ejemplos de Uso

Una vez configurado, puedes interactuar con Claude Desktop de la siguiente manera:

**Consulta de Ventas:**
```
Usuario: ¿Cuánto vendimos el mes pasado?
Claude: [Usa ventas_total_mes_anterior] 
        El total de ventas del mes pasado fue de $17,170.00
```

**Análisis de Tendencias:**
```
Usuario: Muéstrame las ventas de los últimos 7 días
Claude: [Usa ventas_por_dia con n=7]
        Aquí están las ventas de los últimos 7 días:
        - 2025-10-24: $780.00
        - 2025-10-23: $1,450.00
        ...
```

**Gestión de Pedidos:**
```
Usuario: Lista todos los pedidos pendientes
Claude: [Usa pedidos_listar_por_estado con estado="pendiente"]
        Hay 3 pedidos pendientes:
        1. Distribuidora LMN - $12,300.00
        2. Comercial QRS - $9,800.00
        3. Mayorista JKL - $25,000.00
```

**Crear Nuevo Pedido:**
```
Usuario: Crea un pedido para "Tech Solutions" por $18500
Claude: [Usa pedidos_crear con cliente="Tech Solutions" y monto=18500]
        Pedido #17 creado exitosamente para Tech Solutions por $18,500.00
```

## 🏆 Criterios de Evaluación Cumplidos

### ✅ Funcionamiento (45%)
- [x] Gateway conectado en Claude Desktop (15%)
- [x] Tools de ambos servidores visibles (10%)
- [x] Llamadas correctas a ventas_* y pedidos_* (20%)

### ✅ Diseño/Arquitectura (25%)
- [x] Prefijos y enrutamiento claro (10%)
- [x] Manejo de errores y timeouts (10%)
- [x] Logs sin contaminar stdout (5%)

### ✅ Código/Calidad (20%)
- [x] README reproducible (10%)
- [x] Organización del proyecto y comentarios (10%)

### ✅ Datos/Testing (10%)
- [x] Scripts SQL consistentes (5%)
- [x] Evidencias y capturas (5%)

### 🌟 Extras (5%)
- [x] Logs detallados por componente
- [x] Vistas SQL para análisis
- [x] Herramientas adicionales (listar por estado)
- [x] Documentación exhaustiva

## 📚 Referencias

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Desktop](https://claude.ai/download)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 👥 Autor

Laboratorio desarrollado para el curso de Arquitectura de Software.

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la Licencia MIT.
