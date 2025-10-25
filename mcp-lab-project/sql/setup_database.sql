-- Script SQL para crear las tablas y datos de ejemplo
-- Base de datos: mcp_lab

-- Crear la base de datos (ejecutar como superusuario)
-- CREATE DATABASE mcp_lab;

-- Conectarse a la base de datos
\c mcp_lab;

-- ====================================
-- Tabla: ventas
-- ====================================
DROP TABLE IF EXISTS ventas CASCADE;

CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    producto VARCHAR(100),
    vendedor VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para mejorar consultas por fecha
CREATE INDEX idx_ventas_fecha ON ventas(fecha);

-- Insertar datos de ejemplo (últimos 3 meses)
INSERT INTO ventas (fecha, monto, producto, vendedor) VALUES
    -- Mes anterior (septiembre 2025)
    ('2025-09-01', 1500.00, 'Laptop HP', 'Juan Pérez'),
    ('2025-09-03', 850.00, 'Mouse Logitech', 'María García'),
    ('2025-09-05', 2300.00, 'Monitor Samsung', 'Juan Pérez'),
    ('2025-09-07', 450.00, 'Teclado Mecánico', 'Carlos López'),
    ('2025-09-10', 3200.00, 'MacBook Pro', 'María García'),
    ('2025-09-12', 670.00, 'Webcam HD', 'Juan Pérez'),
    ('2025-09-15', 1200.00, 'Tablet iPad', 'Ana Martínez'),
    ('2025-09-18', 890.00, 'Auriculares Sony', 'Carlos López'),
    ('2025-09-20', 2100.00, 'PC Gamer', 'María García'),
    ('2025-09-22', 540.00, 'Impresora Canon', 'Juan Pérez'),
    ('2025-09-25', 1800.00, 'Dell XPS', 'Ana Martínez'),
    ('2025-09-28', 720.00, 'Disco SSD 1TB', 'Carlos López'),
    ('2025-09-30', 950.00, 'Router WiFi', 'María García'),
    
    -- Mes actual (octubre 2025)
    ('2025-10-01', 1650.00, 'Laptop Lenovo', 'Juan Pérez'),
    ('2025-10-02', 920.00, 'Mouse Razer', 'María García'),
    ('2025-10-03', 2450.00, 'Monitor LG', 'Carlos López'),
    ('2025-10-05', 580.00, 'Teclado Corsair', 'Ana Martínez'),
    ('2025-10-07', 3400.00, 'MacBook Air', 'Juan Pérez'),
    ('2025-10-09', 740.00, 'Cámara Web 4K', 'María García'),
    ('2025-10-10', 1350.00, 'Tablet Samsung', 'Carlos López'),
    ('2025-10-12', 960.00, 'Auriculares Bose', 'Ana Martínez'),
    ('2025-10-14', 2250.00, 'PC Workstation', 'Juan Pérez'),
    ('2025-10-15', 610.00, 'Scanner Epson', 'María García'),
    ('2025-10-17', 1950.00, 'HP Pavilion', 'Carlos López'),
    ('2025-10-19', 820.00, 'SSD NVMe 2TB', 'Ana Martínez'),
    ('2025-10-21', 1020.00, 'Switch Gigabit', 'Juan Pérez'),
    ('2025-10-23', 1450.00, 'Laptop Asus', 'María García'),
    ('2025-10-24', 780.00, 'Mousepad RGB', 'Carlos López'),
    
    -- Agosto 2025 (para tener más historia)
    ('2025-08-05', 1400.00, 'Laptop Dell', 'Juan Pérez'),
    ('2025-08-10', 800.00, 'Mouse Inalámbrico', 'María García'),
    ('2025-08-15', 2200.00, 'Monitor 4K', 'Carlos López'),
    ('2025-08-20', 950.00, 'Teclado RGB', 'Ana Martínez'),
    ('2025-08-25', 3100.00, 'iMac', 'Juan Pérez');

-- ====================================
-- Tabla: pedidos
-- ====================================
DROP TABLE IF EXISTS pedidos CASCADE;

CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    cliente VARCHAR(100) NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    estado VARCHAR(20) NOT NULL CHECK (estado IN ('pendiente', 'procesando', 'completado', 'cancelado')),
    fecha_pedido DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar consultas
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_pedidos_updated_at BEFORE UPDATE ON pedidos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insertar datos de ejemplo
INSERT INTO pedidos (cliente, monto, estado, fecha_pedido) VALUES
    ('Empresa ABC S.A.', 15000.00, 'completado', '2025-10-01'),
    ('Tienda XYZ', 8500.00, 'completado', '2025-10-05'),
    ('Corporación 123', 22000.00, 'procesando', '2025-10-10'),
    ('Distribuidora LMN', 12300.00, 'pendiente', '2025-10-15'),
    ('Comercial QRS', 9800.00, 'pendiente', '2025-10-18'),
    ('Empresa DEF', 18500.00, 'completado', '2025-10-20'),
    ('Tienda GHI', 7200.00, 'procesando', '2025-10-22'),
    ('Mayorista JKL', 25000.00, 'pendiente', '2025-10-23'),
    ('Retail MNO', 11500.00, 'completado', '2025-10-24'),
    
    -- Pedidos de septiembre
    ('Empresa PQR', 14000.00, 'completado', '2025-09-05'),
    ('Tienda STU', 9200.00, 'completado', '2025-09-10'),
    ('Corporación VWX', 19500.00, 'completado', '2025-09-15'),
    ('Distribuidora YZA', 10800.00, 'completado', '2025-09-20'),
    ('Comercial BCD', 13200.00, 'completado', '2025-09-25'),
    
    -- Algunos pedidos cancelados
    ('Cliente Cancelado 1', 5000.00, 'cancelado', '2025-10-12'),
    ('Cliente Cancelado 2', 3500.00, 'cancelado', '2025-09-18');

-- ====================================
-- Vistas útiles
-- ====================================

-- Vista: Resumen de ventas por mes
CREATE OR REPLACE VIEW ventas_por_mes AS
SELECT 
    DATE_TRUNC('month', fecha) as mes,
    COUNT(*) as total_transacciones,
    SUM(monto) as total_ventas,
    AVG(monto) as venta_promedio,
    MIN(monto) as venta_minima,
    MAX(monto) as venta_maxima
FROM ventas
GROUP BY DATE_TRUNC('month', fecha)
ORDER BY mes DESC;

-- Vista: Resumen de pedidos por estado
CREATE OR REPLACE VIEW pedidos_por_estado AS
SELECT 
    estado,
    COUNT(*) as cantidad,
    SUM(monto) as monto_total,
    AVG(monto) as monto_promedio
FROM pedidos
GROUP BY estado
ORDER BY estado;

-- Vista: Top vendedores del mes actual
CREATE OR REPLACE VIEW top_vendedores_mes_actual AS
SELECT 
    vendedor,
    COUNT(*) as ventas_realizadas,
    SUM(monto) as total_vendido,
    AVG(monto) as venta_promedio
FROM ventas
WHERE DATE_TRUNC('month', fecha) = DATE_TRUNC('month', CURRENT_DATE)
GROUP BY vendedor
ORDER BY total_vendido DESC;

-- ====================================
-- Consultas de verificación
-- ====================================

-- Ver resumen de ventas
SELECT * FROM ventas_por_mes;

-- Ver resumen de pedidos
SELECT * FROM pedidos_por_estado;

-- Ver top vendedores
SELECT * FROM top_vendedores_mes_actual;

-- Total de registros
SELECT 
    'ventas' as tabla, 
    COUNT(*) as registros 
FROM ventas
UNION ALL
SELECT 
    'pedidos' as tabla, 
    COUNT(*) as registros 
FROM pedidos;

-- Mensaje final
SELECT 'Base de datos configurada exitosamente!' as mensaje;
