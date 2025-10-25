import os
import sys
import psycopg2
import datetime
import traceback
from dotenv import load_dotenv
from mcp.server.fastmcp import FastMCP

load_dotenv()

# Logging a archivo para no contaminar stdout
def log(message: str):
    timestamp = datetime.datetime.now().isoformat()
    with open("pedidos_mcp.log", "a", encoding="utf-8") as f:
        f.write(f"[{timestamp}] {message}\n")
    # stderr está OK para logs
    print(f"[PEDIDOS-MCP] {message}", file=sys.stderr, flush=True)

# Crear servidor MCP
mcp = FastMCP("mcp-pedidos")

def get_conn():
    """Obtiene una conexión a la base de datos"""
    return psycopg2.connect(
        host=os.getenv("PG_HOST", "localhost"),
        port=os.getenv("PG_PORT", "5432"),
        database=os.getenv("PG_DB", "mcp_lab"),
        user=os.getenv("PG_USER", "postgres"),
        password=os.getenv("PG_PASSWORD", "postgres")
    )

@mcp.tool()
def pedidos_estado_por_id(id: int) -> dict:
    """
    Obtiene el estado de un pedido por su ID.
    
    Args:
        id: ID del pedido a consultar
    
    Returns:
        Diccionario con información del pedido (id, cliente, monto, estado, fecha)
    """
    try:
        sql = """
            SELECT id, cliente, monto, estado, fecha_pedido
            FROM pedidos
            WHERE id = %s;
        """
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (id,))
                row = cur.fetchone()
                
                if row is None:
                    return {
                        "error": f"Pedido con ID {id} no encontrado",
                        "found": False
                    }
                
                return {
                    "id": row[0],
                    "cliente": row[1],
                    "monto": float(row[2]),
                    "estado": row[3],
                    "fecha_pedido": str(row[4]),
                    "found": True
                }
    except Exception as e:
        log(f"Error en pedidos_estado_por_id: {str(e)}")
        return {"error": str(e)}

@mcp.tool()
def pedidos_crear(cliente: str, monto: float) -> dict:
    """
    Crea un nuevo pedido en el sistema.
    
    Args:
        cliente: Nombre del cliente
        monto: Monto del pedido
    
    Returns:
        Diccionario con el ID del pedido creado y información adicional
    """
    try:
        sql = """
            INSERT INTO pedidos (cliente, monto, estado, fecha_pedido)
            VALUES (%s, %s, 'pendiente', CURRENT_DATE)
            RETURNING id, cliente, monto, estado, fecha_pedido;
        """
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (cliente, monto))
                row = cur.fetchone()
                conn.commit()
                
                return {
                    "success": True,
                    "id": row[0],
                    "cliente": row[1],
                    "monto": float(row[2]),
                    "estado": row[3],
                    "fecha_pedido": str(row[4]),
                    "mensaje": f"Pedido #{row[0]} creado exitosamente"
                }
    except Exception as e:
        log(f"Error en pedidos_crear: {str(e)}")
        return {
            "success": False,
            "error": str(e)
        }

@mcp.tool()
def pedidos_listar_por_estado(estado: str = "pendiente") -> list[dict]:
    """
    Lista todos los pedidos con un estado específico.
    
    Args:
        estado: Estado de los pedidos a listar (pendiente, procesando, completado, cancelado)
    
    Returns:
        Lista de pedidos con el estado especificado
    """
    try:
        sql = """
            SELECT id, cliente, monto, estado, fecha_pedido
            FROM pedidos
            WHERE estado = %s
            ORDER BY fecha_pedido DESC;
        """
        with get_conn() as conn:
            with conn.cursor() as cur:
                cur.execute(sql, (estado,))
                rows = cur.fetchall()
                
                return [
                    {
                        "id": row[0],
                        "cliente": row[1],
                        "monto": float(row[2]),
                        "estado": row[3],
                        "fecha_pedido": str(row[4])
                    }
                    for row in rows
                ]
    except Exception as e:
        log(f"Error en pedidos_listar_por_estado: {str(e)}")
        return [{"error": str(e)}]

if __name__ == "__main__":
    try:
        log("Iniciando MCP Pedidos Server...")
        
        # Log adicional a archivo
        with open("mcp_pedidos_boot.log", "a", encoding="utf-8") as f:
            f.write(f"[{datetime.datetime.now()}] MCP Pedidos starting. CWD={os.getcwd()}\n")
        
        # Iniciar servidor con transporte stdio
        mcp.run(transport="stdio")
        
    except Exception as e:
        log(f"Error fatal: {str(e)}")
        with open("mcp_pedidos_error.log", "a", encoding="utf-8") as f:
            f.write(f"[{datetime.datetime.now()}]\n{traceback.format_exc()}\n")
        raise
