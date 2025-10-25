import pkg from 'pg';
const { Client } = pkg;
import dotenv from 'dotenv';

dotenv.config();

console.log('===================================');
console.log('Test del Servidor MCP Ventas');
console.log('===================================\n');

const client = new Client({
  host: process.env.PG_HOST || 'localhost',
  port: process.env.PG_PORT || 5432,
  database: process.env.PG_DB || 'mcp_lab',
  user: process.env.PG_USER || 'postgres',
  password: process.env.PG_PASSWORD || 'postgres'
});

try {
  console.log('1. Conectando a PostgreSQL...');
  await client.connect();
  console.log('   ✓ Conexión exitosa\n');

  // Test 1: Total de ventas
  console.log('2. Probando query de total de ventas...');
  const resCount = await client.query('SELECT COUNT(*) FROM ventas');
  console.log(`   ✓ Total de registros en ventas: ${resCount.rows[0].count}\n`);

  // Test 2: Ventas del mes anterior
  console.log('3. Probando query de ventas del mes anterior...');
  const resLastMonth = await client.query(`
    SELECT COALESCE(SUM(monto), 0) as total
    FROM ventas
    WHERE fecha >= date_trunc('month', CURRENT_DATE) - INTERVAL '1 month'
      AND fecha < date_trunc('month', CURRENT_DATE);
  `);
  console.log(`   ✓ Total ventas mes anterior: $${parseFloat(resLastMonth.rows[0].total).toFixed(2)}\n`);

  // Test 3: Ventas por día (últimos 7 días)
  console.log('4. Probando query de ventas por día (últimos 7 días)...');
  const resDaily = await client.query(`
    SELECT fecha, COALESCE(SUM(monto), 0) as total_dia
    FROM ventas
    WHERE fecha >= CURRENT_DATE - INTERVAL '7 days'
    GROUP BY fecha
    ORDER BY fecha DESC;
  `);
  console.log(`   ✓ Registros encontrados: ${resDaily.rows.length}`);
  resDaily.rows.forEach(row => {
    console.log(`     - ${row.fecha.toISOString().split('T')[0]}: $${parseFloat(row.total_dia).toFixed(2)}`);
  });

  console.log('\n===================================');
  console.log('Todos los tests pasaron exitosamente ✓');
  console.log('===================================');

} catch (error) {
  console.error('\n❌ Error durante los tests:', error.message);
  process.exit(1);
} finally {
  await client.end();
}
