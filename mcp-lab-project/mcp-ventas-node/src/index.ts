import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import pkg from "pg";
const { Client } = pkg;
import dotenv from "dotenv";
import fs from "fs";

dotenv.config();

// Logging a archivo para no contaminar stdout
function log(message: string) {
  const timestamp = new Date().toISOString();
  fs.appendFileSync(
    "ventas_mcp.log",
    `[${timestamp}] ${message}\n`,
    "utf-8"
  );
  console.error(`[VENTAS-MCP] ${message}`); // stderr está OK
}

// Función para obtener conexión a la BD
function getDbClient() {
  return new Client({
    host: process.env.PG_HOST || "localhost",
    port: parseInt(process.env.PG_PORT || "5432"),
    database: process.env.PG_DB || "mcp_lab",
    user: process.env.PG_USER || "postgres",
    password: process.env.PG_PASSWORD || "postgres",
  });
}

// Tool 1: Ventas total mes anterior
async function ventasTotalMesAnterior(): Promise<number> {
  const client = getDbClient();
  try {
    await client.connect();
    const query = `
      SELECT COALESCE(SUM(monto), 0) as total
      FROM ventas
      WHERE fecha >= date_trunc('month', CURRENT_DATE) - INTERVAL '1 month'
        AND fecha < date_trunc('month', CURRENT_DATE);
    `;
    const result = await client.query(query);
    return parseFloat(result.rows[0].total);
  } catch (error) {
    log(`Error en ventasTotalMesAnterior: ${error}`);
    throw error;
  } finally {
    await client.end();
  }
}

// Tool 2: Ventas por día (últimos n días)
async function ventasPorDia(n: number = 30): Promise<Array<{ fecha: string; total_dia: number }>> {
  const client = getDbClient();
  try {
    await client.connect();
    const query = `
      SELECT fecha, COALESCE(SUM(monto), 0) as total_dia
      FROM ventas
      WHERE fecha >= CURRENT_DATE - INTERVAL '${n} days'
      GROUP BY fecha
      ORDER BY fecha DESC;
    `;
    const result = await client.query(query);
    return result.rows.map((row) => ({
      fecha: row.fecha.toISOString().split("T")[0],
      total_dia: parseFloat(row.total_dia),
    }));
  } catch (error) {
    log(`Error en ventasPorDia: ${error}`);
    throw error;
  } finally {
    await client.end();
  }
}

// Crear servidor MCP
const server = new Server(
  {
    name: "mcp-ventas",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Registrar handlers
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "ventas_total_mes_anterior",
        description: "Calcula el total de ventas del mes anterior (mes pasado completo)",
        inputSchema: {
          type: "object",
          properties: {},
        },
      },
      {
        name: "ventas_por_dia",
        description: "Devuelve el total de ventas por día de los últimos n días",
        inputSchema: {
          type: "object",
          properties: {
            n: {
              type: "number",
              description: "Número de días a consultar (por defecto 30)",
              default: 30,
            },
          },
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  try {
    const { name, arguments: args } = request.params;

    switch (name) {
      case "ventas_total_mes_anterior": {
        const total = await ventasTotalMesAnterior();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ total_mes_anterior: total }, null, 2),
            },
          ],
        };
      }

      case "ventas_por_dia": {
        const n = (args as any)?.n || 30;
        const ventas = await ventasPorDia(n);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ ventas_por_dia: ventas }, null, 2),
            },
          ],
        };
      }

      default:
        throw new Error(`Tool desconocida: ${name}`);
    }
  } catch (error: any) {
    log(`Error procesando tool: ${error.message}`);
    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({ error: error.message }),
        },
      ],
      isError: true,
    };
  }
});

// Iniciar servidor
async function main() {
  try {
    log("Iniciando MCP Ventas Server...");
    const transport = new StdioServerTransport();
    await server.connect(transport);
    log("MCP Ventas Server conectado exitosamente");
  } catch (error) {
    log(`Error fatal: ${error}`);
    process.exit(1);
  }
}

main();
