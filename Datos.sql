-- =============================================================
-- UTN Hardware - Carga de datos de prueba
-- Base de Datos II - Equipo 16
-- Requiere ejecutar antes Creacion.sql (base vacía).
-- =============================================================

USE UTN_Hardware;
GO

-- -------------------------------------------------------------
-- Carga de datos
-- -------------------------------------------------------------
INSERT INTO Categorias (Nombre, Descripcion) VALUES
    ('Procesadores', 'Microprocesadores para PC de escritorio'),
    ('Placas de video', 'Tarjetas gráficas dedicadas'),
    ('Memorias RAM', 'Módulos de memoria para PC de escritorio'),
    ('Almacenamiento', 'Discos de estado sólido y rígidos'),
    ('Fuentes', 'Fuentes de alimentación'),
    ('Periféricos', 'Mouses, teclados y accesorios');
GO

INSERT INTO Marcas (Nombre, PaisOrigen) VALUES
    ('AMD', 'Estados Unidos'),
    ('Intel', 'Estados Unidos'),
    ('ASUS', 'Taiwán'),
    ('Kingston', 'Estados Unidos'),
    ('Corsair', 'Estados Unidos'),
    ('Samsung', 'Corea del Sur'),
    ('Logitech', 'Suiza');
GO

INSERT INTO Proveedores (RazonSocial, CUIT, Email, Telefono) VALUES
    ('TecnoSur Mayorista S.A.', '30712345678', 'ventas@tecnosur.com.ar', '1145550101'),
    ('Delta Digital S.R.L.', '30709876543', 'ventas@deltadigital.com.ar', '1145550202'),
    ('Importadora del Plata S.A.', '33714567891', 'ventas@delplata.com.ar', '1145550303');
GO

INSERT INTO Clientes (DNI, Nombre, Apellido, Email, Telefono, FechaAlta) VALUES
    ('40123456', 'Mateo', 'Brena', 'mbrena@correo.com', '1160001001', '2026-03-02'),
    ('41234567', 'Tomás', 'Mosgidis', 'tmosgidis@correo.com', '1160001002', '2026-03-15'),
    ('42345678', 'Joaquín', 'Paredes', 'jparedes@correo.com', '1160001003', '2026-04-08'),
    ('39456789', 'Mauricio José', 'Pla', 'mpla@correo.com', '1160001004', '2026-05-20'),
    ('38567890', 'Lucía', 'Fernández', 'lfernandez@correo.com', '1160001005', '2026-06-11'),
    ('43678901', 'Martín', 'Gómez', 'mgomez@correo.com', '1160001006', '2026-07-03');
GO

-- El stock se inicializa en 0 y se calcula al final a partir de los movimientos
INSERT INTO Productos
    (IdCategoria, IdMarca, Modelo, Descripcion, Precio, StockMinimo, Activo) VALUES
    (1, 1, 'Ryzen 5 7600', '6 núcleos, 12 hilos, socket AM5', 285000.00, 3, 1),
    (1, 1, 'Ryzen 7 7800X3D', '8 núcleos, 16 hilos, socket AM5', 650000.00, 3, 1),
    (1, 2, 'Core i5-14400F', '10 núcleos, 16 hilos, socket LGA1700', 240000.00, 3, 1),
    (2, 3, 'Dual GeForce RTX 4060 8GB', 'Placa de video NVIDIA, 8 GB GDDR6', 520000.00, 2, 1),
    (2, 3, 'TUF Radeon RX 7800 XT 16GB', 'Placa de video AMD, 16 GB GDDR6', 980000.00, 3, 1),
    (3, 4, 'Fury Beast 16GB DDR5 5600', 'Módulo único de 16 GB', 75000.00, 5, 1),
    (3, 5, 'Vengeance 32GB (2x16) DDR5 6000', 'Kit de dos módulos de 16 GB', 160000.00, 3, 1),
    (4, 6, '990 EVO 1TB NVMe', 'SSD M.2 PCIe 4.0 de 1 TB', 120000.00, 4, 1),
    (4, 4, 'NV2 500GB NVMe', 'SSD M.2 PCIe 4.0 de 500 GB', 55000.00, 4, 1),
    (5, 5, 'RM750e 750W 80 Plus Gold', 'Fuente modular de 750 W', 145000.00, 2, 1),
    (6, 7, 'G502 X', 'Mouse gamer con cable', 95000.00, 3, 1),
    (6, 7, 'G213 Prodigy', 'Teclado gamer de membrana RGB', 70000.00, 3, 1),
    (1, 2, 'Core i3-10100F', '4 núcleos, 8 hilos, socket LGA1200', 120000.00, 0, 0);
GO

-- Compras a proveedores (3 recibidas, 1 anulada y 1 pendiente de recepción)
INSERT INTO Compras (IdProveedor, Fecha, NroFactura, Estado) VALUES
    (1, '2026-09-01T09:00:00', 'A-0001-00001234', 'Recibida'),
    (2, '2026-09-03T10:30:00', 'A-0003-00000456', 'Recibida'),
    (3, '2026-09-05T11:15:00', 'A-0002-00007890', 'Recibida'),
    (2, '2026-09-20T15:00:00', 'A-0003-00000470', 'Anulada'),
    (1, '2026-10-08T09:45:00', 'A-0001-00001302', 'Pendiente');
GO

INSERT INTO DetalleCompra (IdCompra, IdProducto, Cantidad, CostoUnitario) VALUES
    (1, 1, 10, 210000.00),
    (1, 2, 4, 500000.00),
    (1, 3, 8, 175000.00),
    (2, 4, 6, 400000.00),
    (2, 5, 3, 760000.00),
    (2, 10, 5, 105000.00),
    (3, 6, 20, 52000.00),
    (3, 7, 10, 115000.00),
    (3, 8, 12, 85000.00),
    (3, 9, 15, 38000.00),
    (3, 11, 8, 68000.00),
    (3, 12, 8, 48000.00),
    (4, 4, 2, 400000.00),
    (5, 1, 5, 215000.00),
    (5, 3, 5, 178000.00);
GO

-- Pedidos de clientes en sus distintos estados
INSERT INTO Pedidos (IdCliente, Fecha, Estado, DireccionEnvio) VALUES
    (1, '2026-09-10T14:20:00', 'Entregado', 'Av. Hipólito Yrigoyen 288, Gral. Pacheco'),
    (2, '2026-09-12T18:05:00', 'Entregado', 'Av. Santa Fe 1234, CABA'),
    (3, '2026-09-15T12:40:00', 'Entregado', 'Belgrano 456, Tigre'),
    (4, '2026-09-20T16:10:00', 'Cancelado', 'Av. Maipú 789, Vicente López'),
    (5, '2026-09-25T19:30:00', 'Entregado', 'Mitre 1500, San Isidro'),
    (6, '2026-10-02T11:00:00', 'Confirmado', 'Av. Constituyentes 3200, San Fernando'),
    (1, '2026-10-09T20:15:00', 'Pendiente', 'Av. Hipólito Yrigoyen 288, Gral. Pacheco'),
    (2, '2026-10-11T13:50:00', 'Pendiente', 'Av. Santa Fe 1234, CABA');
GO

-- El precio unitario es el precio de venta del producto al momento del pedido
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario) VALUES
    (1, 1, 1, 285000.00),
    (1, 6, 2, 75000.00),
    (1, 8, 1, 120000.00),
    (2, 4, 1, 520000.00),
    (2, 10, 1, 145000.00),
    (3, 11, 1, 95000.00),
    (3, 12, 1, 70000.00),
    (4, 5, 1, 980000.00),
    (5, 2, 1, 650000.00),
    (5, 7, 1, 160000.00),
    (5, 8, 1, 120000.00),
    (6, 3, 2, 240000.00),
    (6, 9, 2, 55000.00),
    (7, 4, 1, 520000.00),
    (8, 6, 2, 75000.00);
GO

-- Historial de movimientos que generaron las compras y los pedidos anteriores.
-- El pedido 4 fue cancelado y al pedido 7 se le quitó un ítem (G502 X).
INSERT INTO MovimientosStock
    (IdProducto, IdCompra, IdPedido, Fecha, Tipo, Origen, Cantidad) VALUES
    (1, 1, NULL, '2026-09-01T09:00:00', 'Ingreso', 'Compra', 10),
    (2, 1, NULL, '2026-09-01T09:00:00', 'Ingreso', 'Compra', 4),
    (3, 1, NULL, '2026-09-01T09:00:00', 'Ingreso', 'Compra', 8),
    (4, 2, NULL, '2026-09-03T10:30:00', 'Ingreso', 'Compra', 6),
    (5, 2, NULL, '2026-09-03T10:30:00', 'Ingreso', 'Compra', 3),
    (10, 2, NULL, '2026-09-03T10:30:00', 'Ingreso', 'Compra', 5),
    (6, 3, NULL, '2026-09-05T11:15:00', 'Ingreso', 'Compra', 20),
    (7, 3, NULL, '2026-09-05T11:15:00', 'Ingreso', 'Compra', 10),
    (8, 3, NULL, '2026-09-05T11:15:00', 'Ingreso', 'Compra', 12),
    (9, 3, NULL, '2026-09-05T11:15:00', 'Ingreso', 'Compra', 15),
    (11, 3, NULL, '2026-09-05T11:15:00', 'Ingreso', 'Compra', 8),
    (12, 3, NULL, '2026-09-05T11:15:00', 'Ingreso', 'Compra', 8),
    (1, NULL, 1, '2026-09-10T14:20:00', 'Egreso', 'Venta', 1),
    (6, NULL, 1, '2026-09-10T14:20:00', 'Egreso', 'Venta', 2),
    (8, NULL, 1, '2026-09-10T14:20:00', 'Egreso', 'Venta', 1),
    (4, NULL, 2, '2026-09-12T18:05:00', 'Egreso', 'Venta', 1),
    (10, NULL, 2, '2026-09-12T18:05:00', 'Egreso', 'Venta', 1),
    (11, NULL, 3, '2026-09-15T12:40:00', 'Egreso', 'Venta', 1),
    (12, NULL, 3, '2026-09-15T12:40:00', 'Egreso', 'Venta', 1),
    (5, NULL, 4, '2026-09-20T16:10:00', 'Egreso', 'Venta', 1),
    (5, NULL, 4, '2026-09-21T10:00:00', 'Ingreso', 'Cancelación', 1),
    (2, NULL, 5, '2026-09-25T19:30:00', 'Egreso', 'Venta', 1),
    (7, NULL, 5, '2026-09-25T19:30:00', 'Egreso', 'Venta', 1),
    (8, NULL, 5, '2026-09-25T19:30:00', 'Egreso', 'Venta', 1),
    (3, NULL, 6, '2026-10-02T11:00:00', 'Egreso', 'Venta', 2),
    (9, NULL, 6, '2026-10-02T11:00:00', 'Egreso', 'Venta', 2),
    (4, NULL, 7, '2026-10-09T20:15:00', 'Egreso', 'Venta', 1),
    (11, NULL, 7, '2026-10-09T20:15:00', 'Egreso', 'Venta', 1),
    (11, NULL, 7, '2026-10-09T20:25:00', 'Ingreso', 'Baja de ítem', 1),
    (6, NULL, 8, '2026-10-11T13:50:00', 'Egreso', 'Venta', 2);
GO

-- Stock actual de cada producto = ingresos - egresos registrados
UPDATE P
SET P.Stock = ISNULL(M.Saldo, 0)
FROM Productos AS P
LEFT JOIN (
    SELECT IdProducto,
           SUM(CASE WHEN Tipo = 'Ingreso' THEN Cantidad ELSE -Cantidad END) AS Saldo
    FROM MovimientosStock
    GROUP BY IdProducto
) AS M ON M.IdProducto = P.IdProducto;
GO
