import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

print("=" * 50)
print("Test del Servidor MCP Pedidos")
print("=" * 50)
print()

try:
    print("1. Conectando a PostgreSQL...")
    conn = psycopg2.connect(
        host=os.getenv("PG_HOST", "localhost"),
        port=os.getenv("PG_PORT", "5432"),
        database=os.getenv("PG_DB", "mcp_lab"),
        user=os.getenv("PG_USER", "postgres"),
        password=os.getenv("PG_PASSWORD", "postgres")
    )
    cur = conn.cursor()
    print("   ✓ Conexión exitosa\n")

    # Test 1: Total de pedidos
    print("2. Probando query de total de pedidos...")
    cur.execute("SELECT COUNT(*) FROM pedidos")
    count = cur.fetchone()[0]
    print(f"   ✓ Total de registros en pedidos: {count}\n")

    # Test 2: Pedidos por estado
    print("3. Probando query de pedidos por estado...")
    cur.execute("""
        SELECT estado, COUNT(*) as cantidad, SUM(monto) as total
        FROM pedidos
        GROUP BY estado
        ORDER BY estado;
    """)
    print("   ✓ Pedidos por estado:")
    for row in cur.fetchall():
        estado, cantidad, total = row
        print(f"     - {estado}: {cantidad} pedidos, Total: ${float(total):,.2f}")
    print()

    # Test 3: Buscar un pedido específico
    print("4. Probando query de pedido por ID...")
    cur.execute("""
        SELECT id, cliente, monto, estado, fecha_pedido
        FROM pedidos
        WHERE id = 1;
    """)
    row = cur.fetchone()
    if row:
        print(f"   ✓ Pedido encontrado:")
        print(f"     - ID: {row[0]}")
        print(f"     - Cliente: {row[1]}")
        print(f"     - Monto: ${float(row[2]):,.2f}")
        print(f"     - Estado: {row[3]}")
        print(f"     - Fecha: {row[4]}")
    print()

    # Test 4: Simular creación de pedido (sin commit)
    print("5. Probando query de creación de pedido (simulación)...")
    cur.execute("""
        INSERT INTO pedidos (cliente, monto, estado, fecha_pedido)
        VALUES ('Test Cliente', 5000.00, 'pendiente', CURRENT_DATE)
        RETURNING id, cliente, monto;
    """)
    row = cur.fetchone()
    print(f"   ✓ Pedido creado (simulación):")
    print(f"     - ID: {row[0]}")
    print(f"     - Cliente: {row[1]}")
    print(f"     - Monto: ${float(row[2]):,.2f}")
    # Rollback para no persistir el test
    conn.rollback()
    print("     - (Cambios revertidos - test only)\n")

    print("=" * 50)
    print("Todos los tests pasaron exitosamente ✓")
    print("=" * 50)

except Exception as e:
    print(f"\n❌ Error durante los tests: {str(e)}")
    exit(1)
finally:
    if cur:
        cur.close()
    if conn:
        conn.close()
