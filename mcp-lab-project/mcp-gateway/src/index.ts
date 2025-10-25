import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn, ChildProcess } from "child_process";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";

dotenv.config();

// Logging seguro (no contamina stdout)
function log(message: string) {
  const timestamp = new Date().toISOString();
  fs.appendFileSync(
    "gateway_mcp.log",
    `[${timestamp}] ${message}\n`,
    "utf-8"
  );
  console.error(`[GATEWAY-MCP] ${message}`);
}

// Interfaz para configuración de backend
interface BackendConfig {
  name: string;
  prefix: string;
  command: string;
  args: string[];
  cwd: string;
}

// Cliente MCP para cada backend
class BackendClient {
  private client: Client;
  private config: BackendConfig;
  private connected: boolean = false;

  constructor(config: BackendConfig) {
    this.config = config;
    this.client = new Client(
      {
        name: `gateway-client-${config.name}`,
        version: "1.0.0",
      },
      {
        capabilities: {},
      }
    );
  }

  async connect(): Promise<void> {
    try {
      log(`Conectando a backend: ${this.config.name}...`);


      // Crear transporte stdio
      const transport = new StdioClientTransport({
        command: this.config.command,
        args: this.config.args,
        env: Object.fromEntries(
          Object.entries(process.env).filter(([_, v]) => typeof v === "string") as [string, string][]
        ),
      });

      // Conectar cliente MCP
      await this.client.connect(transport);
      this.connected = true;
      log(`Backend ${this.config.name} conectado exitosamente`);
    } catch (error: any) {
      log(`Error conectando a ${this.config.name}: ${error.message}`);
      throw error;
    }
  }

  async listTools(): Promise<Tool[]> {
    if (!this.connected) {
      throw new Error(`Backend ${this.config.name} no está conectado`);
    }

    try {
      const response = await this.client.listTools();

      // Agregar prefijo a cada tool
      return response.tools.map((tool: Tool) => ({
        ...tool,
        name: `${this.config.prefix}${tool.name}`,
      }));
    } catch (error: any) {
      log(`Error listando tools de ${this.config.name}: ${error.message}`);
      return [];
    }
  }

  async callTool(name: string, args: any): Promise<any> {
    if (!this.connected) {
      throw new Error(`Backend ${this.config.name} no está conectado`);
    }

    try {
      // Remover prefijo antes de enviar al backend
      const toolName = name.replace(this.config.prefix, "");

      const response = await this.client.callTool({
        name: toolName,
        arguments: args || {},
      });

      return response;
    } catch (error: any) {
      log(`Error llamando tool ${name} en ${this.config.name}: ${error.message}`);
      throw error;
    }
  }

  isConnected(): boolean {
    return this.connected;
  }

  async disconnect(): Promise<void> {
    this.connected = false;
    await this.client.close();
  }
}

// Gateway MCP Server
class MCPGateway {
  private server: Server;
  private backends: Map<string, BackendClient> = new Map();
  private toolToBackend: Map<string, string> = new Map();

  constructor() {
    this.server = new Server(
      {
        name: "mcp-gateway",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // Handler para listar tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      const allTools: Tool[] = [];

      for (const [name, backend] of this.backends.entries()) {
        if (backend.isConnected()) {
          const tools = await backend.listTools();
          allTools.push(...tools);

          // Mapear cada tool a su backend
          tools.forEach((tool) => {
            this.toolToBackend.set(tool.name, name);
          });
        }
      }

      log(`Exponiendo ${allTools.length} tools al cliente`);
      return { tools: allTools };
    });

    // Handler para llamar tools
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        // Buscar el backend responsable
        const backendName = this.toolToBackend.get(name);
        if (!backendName) {
          throw new Error(`Tool '${name}' no encontrada en ningún backend`);
        }

        const backend = this.backends.get(backendName);
        if (!backend || !backend.isConnected()) {
          throw new Error(`Backend '${backendName}' no disponible`);
        }

        // Delegar la llamada al backend
        log(`Delegando ${name} a backend ${backendName}`);
        const result = await backend.callTool(name, args);

        return result;
      } catch (error: any) {
        log(`Error procesando tool ${name}: ${error.message}`);
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
  }

  async registerBackend(config: BackendConfig): Promise<void> {
    try {
      const backend = new BackendClient(config);
      await backend.connect();
      this.backends.set(config.name, backend);
      log(`Backend ${config.name} registrado exitosamente`);
    } catch (error: any) {
      log(`Error registrando backend ${config.name}: ${error.message}`);
      throw error;
    }
  }

  async start(): Promise<void> {
    try {
      log("Iniciando MCP Gateway...");

      const transport = new StdioServerTransport();
      await this.server.connect(transport);

      log("MCP Gateway conectado y listo");
    } catch (error: any) {
      log(`Error iniciando Gateway: ${error.message}`);
      throw error;
    }
  }

  async shutdown(): Promise<void> {
    log("Cerrando Gateway...");
    for (const backend of this.backends.values()) {
      await backend.disconnect();
    }
  }
}

// Main
async function main() {
  const gateway = new MCPGateway();

  // Rutas absolutas en Windows
  const ventasPath = "C:/Users/camil/Downloads/mcp-lab-project(1)/mcp-lab-project/mcp-ventas-node";
  const pedidosPath = "C:/Users/camil/Downloads/mcp-lab-project(1)/mcp-lab-project/mcp-pedidos-py";

  try {
    // Registrar backend de Ventas (Node.js)
    await gateway.registerBackend({
      name: "ventas",
      prefix: "ventas_",
      command: "node",
      args: ["C:/Users/camil/Downloads/mcp-lab-project(1)/mcp-lab-project/mcp-ventas-node/dist/index.js"],
      cwd: ventasPath,
    });

    // Registrar backend de Pedidos (Python)
    await gateway.registerBackend({
      name: "pedidos",
      prefix: "pedidos_",
      command: "C:/Users/camil/Downloads/mcp-lab-project(1)/mcp-lab-project/mcp-pedidos-py/venv/Scripts/python.exe",
      args: ["C:/Users/camil/Downloads/mcp-lab-project(1)/mcp-lab-project/mcp-pedidos-py/server.py"],
      cwd: pedidosPath,
    });

    // Iniciar Gateway
    await gateway.start();

    // Cleanup al cerrar
    process.on("SIGINT", async () => {
      await gateway.shutdown();
      process.exit(0);
    });

    process.on("SIGTERM", async () => {
      await gateway.shutdown();
      process.exit(0);
    });
  } catch (error: any) {
    log(`Error fatal: ${error.message}`);
    process.exit(1);
  }
}

main();
