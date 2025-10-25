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
<img width="917" height="296" alt="imagen" src="https://github.com/user-attachments/assets/21c6623f-730e-47d2-a321-bb16310d9afe" />

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
<img width="927" height="476" alt="imagen" src="https://github.com/user-attachments/assets/cb82e542-ade2-4caa-b46b-789b9fb220cc" />


#### `pedidos_crear`
Crea un nuevo pedido en el sistema.

**Parámetros:**
- `cliente`: Nombre del cliente
- `monto`: Monto del pedido

**Ejemplo de uso en Claude:**
```
Crea un pedido para el cliente "Empresa XYZ" por $15000
```
<img width="938" height="472" alt="imagen" src="https://github.com/user-attachments/assets/f30df289-36c2-401d-b810-9f83fdb85754" />

<img width="1308" height="268" alt="imagen" src="https://github.com/user-attachments/assets/74e70226-c4fa-4f0f-85c7-71ceafd1c475" />


#### `pedidos_listar_por_estado`
Lista todos los pedidos con un estado específico.

**Parámetros:**
- `estado` (opcional): Estado de los pedidos (pendiente, procesando, completado, cancelado)

**Ejemplo de uso en Claude:**
```
Muéstrame todos los pedidos pendientes
```
<img width="917" height="679" alt="imagen" src="https://github.com/user-attachments/assets/b31968ac-d636-4332-addf-2fa10872a1b6" />


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

## 👥 Autor

Laboratorio realizado por Samuel Corrales y Camilo Valencia.

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la Licencia MIT.
