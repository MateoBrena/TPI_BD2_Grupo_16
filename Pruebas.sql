--==============================================================================
-- PRUEBAS DE FUNCIONES
-- =============================================================================

USE UTN_Hardware;
GO

SELECT dbo.fn_TotalPedido(1);          -- 555000.00
SELECT dbo.fn_TotalPedido(5);          -- 930000.00
SELECT dbo.fn_TotalPedido(4);          -- 980000.00 (cancelado: igual calcula el total)
SELECT dbo.fn_TotalCompra(1);          -- 5500000.00
SELECT dbo.fn_TotalCompra(4);          -- 800000.00 (anulada: igual calcula el total)
SELECT dbo.fn_StockComprometido(3);    -- 2 (pedido 6, Confirmado)
SELECT dbo.fn_StockComprometido(4);    -- 1 (pedido 7, Pendiente)
SELECT dbo.fn_StockComprometido(6);    -- 2 (pedido 8, Pendiente)
SELECT dbo.fn_StockComprometido(5);    -- 0 (solo está en el pedido 4, Cancelado)
SELECT dbo.fn_StockComprometido(1);    -- 0 (solo está en el pedido 1, Entregado)
SELECT dbo.fn_TotalComprasCliente(1);  -- 555000.00 (no suma su pedido 7, Pendiente)
SELECT dbo.fn_TotalComprasCliente(4);  -- 0.00 (su único pedido está Cancelado)
SELECT dbo.fn_TotalComprasCliente(6);  -- 590000.00 (Confirmado cuenta)

SELECT dbo.fn_TotalPedido(999), dbo.fn_TotalCompra(999),
       dbo.fn_StockComprometido(13),      -- producto inactivo sin pedidos
       dbo.fn_TotalComprasCliente(999),
       dbo.fn_TotalPedido(NULL);

BEGIN TRAN;
  UPDATE Pedidos SET Estado = 'Confirmado' WHERE IdPedido = 7;
  SELECT dbo.fn_TotalComprasCliente(1);  -- tiene que subir a 1075000.00
  SELECT dbo.fn_StockComprometido(4);    -- sigue en 1
  UPDATE Pedidos SET Estado = 'Entregado' WHERE IdPedido = 7;
  SELECT dbo.fn_StockComprometido(4);    -- tiene que bajar a 0
ROLLBACK;

SELECT SUM(dbo.fn_TotalPedido(IdPedido)) FROM Pedidos;          -- 4555000.00
SELECT SUM(Cantidad * PrecioUnitario) FROM DetallePedido;       -- 4555000.00

-- =============================================================================
-- PRUEBAS DE VISTAS
-- =============================================================================

SELECT * FROM vi_ProductosBajoStock;
-- 2 filas: Ryzen 7 7800X3D y TUF Radeon RX 7800 XT (3 de 3). No aparece el Core i3 (inactivo).

SELECT * FROM vi_PedidosResumen ORDER BY IdPedido;
-- 8 filas: 555.000 · 665.000 · 165.000 · 980.000 (Cancelado) · 930.000 · 590.000 · 520.000 · 150.000

SELECT * FROM vi_RankingClientes ORDER BY TotalComprado DESC;
-- Lucía Fernández 930.000 · Tomás Mosgidis 665.000 · Martín Gómez 590.000 ·
-- Mateo Brena 555.000 · Joaquín Paredes 165.000 · Mauricio José Pla 0 (con 0 pedidos)

SELECT * FROM vi_VentasPorCategoria ORDER BY MontoVendido DESC;
-- Procesadores 1.415.000 (4 u.) · Placas de video 520.000 (1) · Almacenamiento 350.000 (4) ·
-- Memorias RAM 310.000 (3) · Periféricos 165.000 (2) · Fuentes 145.000 (1)

SELECT SUM(MontoVendido) FROM vi_VentasPorCategoria;
-- 2.905.000: tiene que coincidir con SUM(TotalComprado) de vi_RankingClientes

SELECT * FROM vi_StockDisponible;
-- Fury Beast: 16 / 2 / 18 · Core i5-14400F: 6 / 2 / 8 · NV2: 13 / 2 / 15 · RTX 4060: 4 / 1 / 5

SELECT * FROM vi_ComprasResumen ORDER BY IdCompra;
-- 5 filas: 1 TecnoSur Recibida 3 prod. 5.500.000 · 2 Delta Digital Recibida 3 prod. 5.205.000 ·
-- 3 Importadora del Plata Recibida 6 prod. 4.708.000 · 4 Delta Digital Anulada 1 prod. 800.000 ·
-- 5 TecnoSur Pendiente 2 prod. 1.965.000

SELECT SUM(Total) FROM vi_ComprasResumen;
-- 18.178.000: tiene que coincidir con SUM(Cantidad * CostoUnitario) de DetalleCompra
SELECT SUM(Cantidad * CostoUnitario) FROM DetalleCompra;
-- 18.178.000

-- =============================================================================
-- Pruebas de Procedimientos de reporte (no modifican datos)
-- =============================================================================

EXEC pa_VentasPorPeriodo '2026-09-01', '2026-09-30';
-- 9 filas (productos de los pedidos 1, 2, 3 y 5). La suma de MontoVendido da 2.315.000.
-- No aparece la RX 7800 XT (pedido 4, Cancelado).

EXEC pa_VentasPorPeriodo '2026-10-01', '2026-10-31';
-- 2 filas: Core i5-14400F 480.000 (2 u.) y NV2 110.000 (2 u.). Total 590.000.
-- No incluye los pedidos 7 y 8 (Pendientes).

EXEC pa_VentasPorPeriodo '2026-09-10', '2026-09-10';
-- 3 filas del pedido 1 (Ryzen 5, Fury Beast, 990 EVO). Total 555.000.
-- El pedido es de las 14:20: prueba que Hasta se incluye completo.

EXEC pa_VentasPorPeriodo '2026-08-01', '2026-08-31';
-- 0 filas, sin error (período sin ventas).

EXEC pa_VentasPorPeriodo '2026-10-31', '2026-10-01';
-- Error 50002: Rango de fechas inválido.

EXEC pa_VentasPorPeriodo NULL, '2026-10-31';
-- Error 50001: Las fechas Desde y Hasta son obligatorias.

EXEC pa_ComprasPorPeriodo '2026-09-01', '2026-09-30';
-- 4 filas: compras 1, 2 y 3 (Recibidas: 5.500.000 · 5.205.000 · 4.708.000)
-- y la 4 (Anulada: 800.000).

EXEC pa_ComprasPorPeriodo '2026-10-01', '2026-10-31';
-- 1 fila: compra 5, Pendiente, 1.965.000.

EXEC pa_ComprasPorPeriodo '2026-10-31', '2026-10-01';
-- Error 50002.

GO
-- =============================================================================
-- Pruebas de Recepción de compras (procedimiento + trigger de UPDATE en Compras)
-- Todo se hace dentro de transacciones que terminan en ROLLBACK, así la base
-- queda igual que antes y el archivo se puede volver a ejecutar.
-- Los casos que deben fallar se capturan con TRY/CATCH para ver el número y el
-- mensaje del error sin cortar la ejecución.
-- =============================================================================

-- Prueba 1: recibir la compra 5 (Pendiente, TecnoSur: 5 Ryzen 5 7600 y 5 Core i5-14400F)
BEGIN TRAN;

    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 3);
    -- Antes: Ryzen 5 7600 = 9 · Core i5-14400F = 6

    EXEC pa_RecibirCompra 5;

    SELECT IdCompra, Estado FROM Compras WHERE IdCompra = 5;
    -- Recibida

    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 3);
    -- Después: Ryzen 5 7600 = 14 · Core i5-14400F = 11

    SELECT IdProducto, IdCompra, Tipo, Origen, Cantidad
    FROM MovimientosStock
    WHERE IdCompra = 5;
    -- 2 filas: producto 1 y producto 3, Ingreso, Compra, 5 unidades cada uno

    -- Casos que deben fallar
    BEGIN TRY
        EXEC pa_RecibirCompra 5;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
    -- 50021: La compra ya fue recibida.

    BEGIN TRY
        EXEC pa_RecibirCompra 4;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
    -- 50022: No se puede recibir una compra anulada.

    BEGIN TRY
        EXEC pa_RecibirCompra 999;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
    -- 50020: La compra no existe.

    INSERT INTO Compras (IdProveedor, NroFactura) VALUES (3, 'PRUEBA-SIN-DETALLE');
    DECLARE @CompraVacia INT = SCOPE_IDENTITY();
    BEGIN TRY
        EXEC pa_RecibirCompra @CompraVacia;
    END TRY
    BEGIN CATCH
        SELECT ERROR_NUMBER() AS Error, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
    -- 50023: La compra no tiene productos.

    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 3);
    -- Los errores no movieron el stock: siguen 14 y 11

    -- Control: el stock coincide con los movimientos
    SELECT P.IdProducto, P.Modelo, P.Stock, ISNULL(M.Saldo, 0) AS SaldoMovimientos
    FROM Productos AS P
    LEFT JOIN (
        SELECT IdProducto,
               SUM(CASE WHEN Tipo = 'Ingreso' THEN Cantidad ELSE -Cantidad END) AS Saldo
        FROM MovimientosStock
        GROUP BY IdProducto
    ) AS M ON M.IdProducto = P.IdProducto
    WHERE P.Stock <> ISNULL(M.Saldo, 0);
    -- 0 filas

ROLLBACK;
GO

SELECT IdCompra, Estado FROM Compras WHERE IdCompra = 5;
-- Volvió a Pendiente (se deshizo la prueba)
SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 3);
-- Volvió a 9 y 6
GO

-- Prueba 2: el trigger también funciona con un UPDATE directo y con varias filas
BEGIN TRAN;

    -- Dos compras pendientes que traen el mismo producto (Ryzen 5 7600)
    INSERT INTO Compras (IdProveedor, NroFactura) VALUES (3, 'PRUEBA-0001');
    DECLARE @CompraA INT = SCOPE_IDENTITY();
    INSERT INTO Compras (IdProveedor, NroFactura) VALUES (3, 'PRUEBA-0002');
    DECLARE @CompraB INT = SCOPE_IDENTITY();
    INSERT INTO DetalleCompra (IdCompra, IdProducto, Cantidad, CostoUnitario) VALUES
        (@CompraA, 1, 2, 215000.00),
        (@CompraB, 1, 3, 215000.00);

    -- Se reciben las dos en un solo UPDATE
    UPDATE Compras SET Estado = 'Recibida' WHERE IdCompra IN (@CompraA, @CompraB);

    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 1;
    -- 14 (9 + 2 + 3): suma las dos compras, no solo una

    SELECT IdCompra, Tipo, Origen, Cantidad
    FROM MovimientosStock
    WHERE IdCompra IN (@CompraA, @CompraB);
    -- 2 filas: Ingreso, Compra, 2 y 3 unidades

    -- Anular una compra pendiente no mueve el stock
    UPDATE Compras SET Estado = 'Anulada' WHERE IdCompra = 5;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 3);
    -- Ryzen 5 7600 sigue en 14 · Core i5-14400F sigue en 6

    -- Corregir la factura de una compra recibida no cambia el estado ni el stock
    UPDATE Compras SET NroFactura = 'A-0001-00001234-C' WHERE IdCompra = 1;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 3);
    -- Sin cambios: 14 y 6

ROLLBACK;
GO

-- Prueba 3: transiciones no permitidas (cada una en su propio lote, porque el
-- trigger deshace la operación y corta el lote). Ver el error en la pestaña Mensajes.
UPDATE Compras SET Estado = 'Pendiente' WHERE IdCompra = 1;
-- Error 50010: Transición de estado no permitida (Recibida es final).
-- Puede aparecer también el mensaje 3609 ("La transacción terminó en el
-- desencadenador"): es normal, indica que el trigger hizo ROLLBACK.
GO

UPDATE Compras SET Estado = 'Recibida' WHERE IdCompra = 4;
-- Error 50010 (Anulada es final).
GO

SELECT IdCompra, Estado FROM Compras WHERE IdCompra IN (1, 4);
-- Compra 1 sigue Recibida y compra 4 sigue Anulada
SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 4;
-- RTX 4060 sigue en 4 (la compra 4 anulada no sumó stock)
GO
-- =============================================================================
-- Pruebas de Triggers de pedidos (INSERT, DELETE y UPDATE en DetallePedido, UPDATE en Pedidos)
-- Stock inicial de los productos que se usan:
--   1 Ryzen 5 7600 = 9 · 2 Ryzen 7 7800X3D = 3 · 3 Core i5-14400F = 6 ·
--   4 RTX 4060 = 4 · 9 NV2 = 13 · 12 G213 Prodigy = 7 · 13 Core i3 (inactivo) = 0
-- Pedidos: 7 (Mateo) y 8 (Tomás) Pendientes · 6 Confirmado · 1 Entregado · 4 Cancelado
--
-- Los casos que deben fallar van cada uno en su propio lote (GO): el trigger
-- deshace la operación y corta el lote. El error se ve en la pestaña Mensajes,
-- a veces junto con el 3609 ("la transacción terminó en el desencadenador"),
-- que es normal. Cada uno está entre BEGIN TRAN y ROLLBACK: si el trigger
-- fallara y la operación se aceptara, el ROLLBACK la deshace igual.
-- =============================================================================

-- Prueba 4: dos clientes quieren el mismo producto (escenario del video)
-- Esta prueba deja los pedidos y el stock como estaban, pero los movimientos
-- quedan registrados en el historial, como pasaría en la realidad.
SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 2;
-- Ryzen 7 7800X3D = 3

-- 4.1 Mateo agrega las 3 unidades a su pedido (7)
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
VALUES (7, 2, 3, 650000.00);
SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 2;
-- 0
GO

-- 4.2 Tomás intenta agregar 1 a su pedido (8)
BEGIN TRAN;
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
VALUES (8, 2, 1, 650000.00);
ROLLBACK;
-- Error 50032: Stock insuficiente para Ryzen 7 7800X3D: disponible 0, solicitado 1.
GO

SELECT IdPedido, IdProducto, Cantidad FROM DetallePedido WHERE IdProducto = 2 AND IdPedido IN (7, 8);
-- 1 fila: solo el pedido 7, con 3 unidades

-- 4.3 Mateo quita el producto de su pedido: las unidades vuelven a estar disponibles
DELETE FROM DetallePedido WHERE IdPedido = 7 AND IdProducto = 2;
SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 2;
-- 3

-- 4.4 Ahora Tomás sí puede agregarlo
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
VALUES (8, 2, 1, 650000.00);
SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 2;
-- 2

SELECT IdPedido, Tipo, Origen, Cantidad
FROM MovimientosStock
WHERE IdProducto = 2 AND IdPedido IN (7, 8)
ORDER BY IdMovimiento;
-- 3 filas: pedido 7 Egreso Venta 3 · pedido 7 Ingreso Baja de ítem 3 · pedido 8 Egreso Venta 1
-- (si la prueba ya se ejecutó antes, aparecen también las filas de esas ejecuciones)

-- 4.5 Limpieza: Tomás también lo quita, para dejar el pedido como estaba
DELETE FROM DetallePedido WHERE IdPedido = 8 AND IdProducto = 2;
SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 2;
-- 3
GO

-- Prueba 5: varias filas en una misma sentencia
BEGIN TRAN;

    -- Un solo INSERT con dos productos
    INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario) VALUES
        (7, 1, 2, 285000.00),
        (7, 9, 1, 55000.00);
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 9);
    -- Ryzen 5 7600 = 7 (9 - 2) · NV2 = 12 (13 - 1)

    -- El mismo producto en dos pedidos a la vez: se descuenta la suma
    INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario) VALUES
        (7, 12, 1, 70000.00),
        (8, 12, 2, 70000.00);
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 12;
    -- G213 Prodigy = 4 (7 - 1 - 2)

    SELECT IdPedido, IdProducto, Tipo, Origen, Cantidad
    FROM MovimientosStock
    WHERE IdPedido IN (7, 8) AND IdProducto IN (1, 9, 12);
    -- 4 filas, todas Egreso Venta: (7,1,2) · (7,9,1) · (7,12,1) · (8,12,2)

    -- Un solo DELETE que quita los tres productos agregados al pedido 7
    DELETE FROM DetallePedido WHERE IdPedido = 7 AND IdProducto IN (1, 9, 12);
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 9, 12);
    -- Ryzen 5 7600 = 9 · NV2 = 13 · G213 Prodigy = 5 (siguen reservadas las 2 del pedido 8)

    SELECT dbo.fn_StockComprometido(12);
    -- 2 (pedido 8, Pendiente)

    -- Control: el stock coincide con los movimientos
    SELECT P.IdProducto, P.Modelo, P.Stock, ISNULL(M.Saldo, 0) AS SaldoMovimientos
    FROM Productos AS P
    LEFT JOIN (
        SELECT IdProducto,
               SUM(CASE WHEN Tipo = 'Ingreso' THEN Cantidad ELSE -Cantidad END) AS Saldo
        FROM MovimientosStock
        GROUP BY IdProducto
    ) AS M ON M.IdProducto = P.IdProducto
    WHERE P.Stock <> ISNULL(M.Saldo, 0);
    -- 0 filas

ROLLBACK;
GO

-- Prueba 6: altas y bajas que deben fallar
BEGIN TRAN;
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
VALUES (1, 9, 1, 55000.00);
ROLLBACK;
-- Error 50030: Solo se pueden agregar productos a un pedido Pendiente. El pedido 1 está Entregado.
GO

BEGIN TRAN;
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
VALUES (6, 9, 1, 55000.00);
ROLLBACK;
-- Error 50030: ... El pedido 6 está Confirmado.
GO

BEGIN TRAN;
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
VALUES (7, 13, 1, 120000.00);
ROLLBACK;
-- Error 50031: No se puede vender un producto inactivo: Core i3-10100F.
GO

BEGIN TRAN;
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
VALUES (7, 2, 4, 650000.00);
ROLLBACK;
-- Error 50032: Stock insuficiente para Ryzen 7 7800X3D: disponible 3, solicitado 4.
GO

-- Si una fila falla, no se agrega ninguna (el Ryzen 5 7600 sí tenía stock)
BEGIN TRAN;
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario) VALUES
    (7, 1, 1, 285000.00),
    (7, 2, 5, 650000.00);
ROLLBACK;
-- Error 50032: Stock insuficiente para Ryzen 7 7800X3D: disponible 3, solicitado 5.
GO

BEGIN TRAN;
DELETE FROM DetallePedido WHERE IdPedido = 6;
ROLLBACK;
-- Error 50033: Solo se pueden quitar productos de un pedido Pendiente. El pedido 6 está Confirmado.
GO

BEGIN TRAN;
DELETE FROM DetallePedido WHERE IdPedido = 4;
ROLLBACK;
-- Error 50033: ... El pedido 4 está Cancelado. (Su stock ya se repuso al cancelarlo.)
GO

SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (1, 2, 3, 5, 9);
-- Sin cambios: Ryzen 5 7600 = 9 · Ryzen 7 7800X3D = 3 · Core i5-14400F = 6 ·
-- RX 7800 XT = 3 · NV2 = 13
SELECT IdPedido, COUNT(*) AS Productos FROM DetallePedido WHERE IdPedido IN (4, 6, 7) GROUP BY IdPedido;
-- Pedido 4 = 1 · pedido 6 = 2 · pedido 7 = 1
GO

-- Prueba 7: cambios de estado de los pedidos
BEGIN TRAN;

    -- Cancelar dos pedidos en un solo UPDATE: el 7 (Pendiente) y el 6 (Confirmado)
    UPDATE Pedidos SET Estado = 'Cancelado' WHERE IdPedido IN (6, 7);
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (3, 4, 9);
    -- Core i5-14400F = 8 (6 + 2) · RTX 4060 = 5 (4 + 1) · NV2 = 15 (13 + 2)

    SELECT IdPedido, IdProducto, Tipo, Origen, Cantidad
    FROM MovimientosStock
    WHERE IdPedido IN (6, 7) AND Origen = 'Cancelación';
    -- 3 filas, Ingreso Cancelación: (6,3,2) · (6,9,2) · (7,4,1)

    SELECT IdPedido, IdProducto FROM DetallePedido WHERE IdPedido IN (6, 7);
    -- 3 filas: los pedidos cancelados conservan su detalle

    -- Confirmar y entregar el pedido 8: no mueve el stock (ya se descontó al agregar)
    UPDATE Pedidos SET Estado = 'Confirmado' WHERE IdPedido = 8;
    UPDATE Pedidos SET Estado = 'Entregado' WHERE IdPedido = 8;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 6;
    -- Fury Beast sigue en 16

    -- Corregir la dirección de un pedido Entregado: no cambia el estado ni el stock
    UPDATE Pedidos SET DireccionEnvio = 'Av. Santa Fe 1234, Piso 2, CABA' WHERE IdPedido = 2;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (4, 10);
    -- RTX 4060 = 5 · RM750e = 4 (sin cambios)

    -- Control: el stock coincide con los movimientos
    SELECT P.IdProducto, P.Modelo, P.Stock, ISNULL(M.Saldo, 0) AS SaldoMovimientos
    FROM Productos AS P
    LEFT JOIN (
        SELECT IdProducto,
               SUM(CASE WHEN Tipo = 'Ingreso' THEN Cantidad ELSE -Cantidad END) AS Saldo
        FROM MovimientosStock
        GROUP BY IdProducto
    ) AS M ON M.IdProducto = P.IdProducto
    WHERE P.Stock <> ISNULL(M.Saldo, 0);
    -- 0 filas

ROLLBACK;
GO

-- Prueba 8: transiciones de estado no permitidas
BEGIN TRAN;
UPDATE Pedidos SET Estado = 'Pendiente' WHERE IdPedido = 1;
ROLLBACK;
-- Error 50034 (Entregado es final)
GO

BEGIN TRAN;
UPDATE Pedidos SET Estado = 'Cancelado' WHERE IdPedido = 1;
ROLLBACK;
-- Error 50034 (un pedido entregado no se puede cancelar)
GO

BEGIN TRAN;
UPDATE Pedidos SET Estado = 'Pendiente' WHERE IdPedido = 4;
ROLLBACK;
-- Error 50034 (Cancelado es final: si volviera a Pendiente, se podría cancelar dos veces)
GO

BEGIN TRAN;
UPDATE Pedidos SET Estado = 'Entregado' WHERE IdPedido = 7;
ROLLBACK;
-- Error 50034 (no se puede saltear Confirmado)
GO

SELECT IdPedido, Estado FROM Pedidos WHERE IdPedido IN (1, 4, 7);
-- 1 Entregado · 4 Cancelado · 7 Pendiente
GO

-- Prueba 9: sumar y restar unidades de un producto del pedido (como en un carrito)
-- Pedido 8 (Tomás, Pendiente) tiene 2 Fury Beast (producto 6, stock 16).
-- Pedido 7 (Mateo, Pendiente) tiene 1 RTX 4060 (producto 4, stock 4).
BEGIN TRAN;

    -- Sumar 1 unidad: 2 -> 3
    UPDATE DetallePedido SET Cantidad = 3 WHERE IdPedido = 8 AND IdProducto = 6;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 6;
    -- 15 (se descuenta solo la unidad de más)

    -- Restar 2 unidades: 3 -> 1
    UPDATE DetallePedido SET Cantidad = 1 WHERE IdPedido = 8 AND IdProducto = 6;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 6;
    -- 17 (se reponen las 2 de menos)

    -- Varias filas en un solo UPDATE: +1 a cada producto de los pedidos 7 y 8
    UPDATE DetallePedido SET Cantidad = Cantidad + 1 WHERE IdPedido IN (7, 8);
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto IN (4, 6);
    -- RTX 4060 = 3 (4 - 1) · Fury Beast = 16 (17 - 1)

    -- Cambiar solo el precio: no mueve el stock ni registra movimientos
    UPDATE DetallePedido SET PrecioUnitario = 76000.00 WHERE IdPedido = 8 AND IdProducto = 6;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 6;
    -- Sigue en 16

    SELECT Tipo, Origen, Cantidad
    FROM MovimientosStock
    WHERE IdPedido = 8 AND IdProducto = 6
    ORDER BY IdMovimiento;
    -- 4 filas: Egreso Venta 2 (de Datos.sql) · Egreso Venta 1 · Ingreso Baja de ítem 2 ·
    -- Egreso Venta 1. El cambio de precio no agregó ninguna.

    -- Producto que se da de baja con unidades ya reservadas en un pedido:
    -- se puede reducir la cantidad y el pedido se puede confirmar igual.
    UPDATE Productos SET Activo = 0 WHERE IdProducto = 6;
    UPDATE DetallePedido SET Cantidad = 1 WHERE IdPedido = 8 AND IdProducto = 6;
    SELECT IdProducto, Modelo, Stock FROM Productos WHERE IdProducto = 6;
    -- 17 (2 -> 1: se repone 1)
    UPDATE Pedidos SET Estado = 'Confirmado' WHERE IdPedido = 8;
    SELECT IdPedido, Estado FROM Pedidos WHERE IdPedido = 8;
    -- Confirmado

    -- Control: el stock coincide con los movimientos
    SELECT P.IdProducto, P.Modelo, P.Stock, ISNULL(M.Saldo, 0) AS SaldoMovimientos
    FROM Productos AS P
    LEFT JOIN (
        SELECT IdProducto,
               SUM(CASE WHEN Tipo = 'Ingreso' THEN Cantidad ELSE -Cantidad END) AS Saldo
        FROM MovimientosStock
        GROUP BY IdProducto
    ) AS M ON M.IdProducto = P.IdProducto
    WHERE P.Stock <> ISNULL(M.Saldo, 0);
    -- 0 filas

ROLLBACK;
GO

-- Prueba 10: modificaciones que deben fallar
BEGIN TRAN;
UPDATE DetallePedido SET Cantidad = 3 WHERE IdPedido = 6 AND IdProducto = 3;
ROLLBACK;
-- Error 50036: Solo se pueden modificar productos de un pedido Pendiente. El pedido 6 está Confirmado.
GO

BEGIN TRAN;
UPDATE DetallePedido SET IdProducto = 7 WHERE IdPedido = 8 AND IdProducto = 6;
ROLLBACK;
-- Error 50035: No se puede cambiar el pedido ni el producto de un ítem.
GO

BEGIN TRAN;
UPDATE DetallePedido SET Cantidad = 20 WHERE IdPedido = 8 AND IdProducto = 6;
ROLLBACK;
-- Error 50032: Stock insuficiente para Fury Beast 16GB DDR5 5600: disponible 16, solicitado 18 más.
GO

-- Aumentar un producto que se dio de baja (la baja también se deshace)
BEGIN TRAN;
UPDATE Productos SET Activo = 0 WHERE IdProducto = 6;
UPDATE DetallePedido SET Cantidad = 3 WHERE IdPedido = 8 AND IdProducto = 6;
ROLLBACK;
-- Error 50031: No se puede vender un producto inactivo: Fury Beast 16GB DDR5 5600.
GO

-- Dejar la cantidad en 0: lo rechaza el CHECK (para eso se quita el producto con DELETE)
BEGIN TRAN;
UPDATE DetallePedido SET Cantidad = 0 WHERE IdPedido = 8 AND IdProducto = 6;
ROLLBACK;
-- Error 547: conflicto con la restricción CK_DetallePedido_Cantidad
GO

SELECT IdPedido, IdProducto, Cantidad FROM DetallePedido WHERE IdPedido IN (6, 8);
-- Sin cambios: (6,3,2) · (6,9,2) · (8,6,2)
SELECT IdProducto, Modelo, Stock, Activo FROM Productos WHERE IdProducto IN (3, 6);
-- Core i5-14400F = 6 · Fury Beast = 16, activo
GO

-- Prueba 11 (opcional, para la defensa): dos personas al mismo tiempo.
-- Abrir dos ventanas de consulta conectadas a UTN_Hardware.
--   Ventana A: BEGIN TRAN;
--              INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
--              VALUES (7, 2, 3, 650000.00);
--   Ventana B: INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioUnitario)
--              VALUES (8, 2, 1, 650000.00);
--              -> queda esperando: A tiene bloqueado el producto.
--   Ventana A: COMMIT;
--   Ventana B: sigue y falla con el error 50032 (disponible 0).
--   Limpieza (ventana A): DELETE FROM DetallePedido WHERE IdPedido = 7 AND IdProducto = 2;

-- =============================================================================
-- CORRECCIONES DE LA PRIMERA ENTREGA
-- =============================================================================

-- Una factura de compra no se puede cargar dos veces (corrección de la
-- primera entrega).
INSERT INTO Compras (IdProveedor, NroFactura) VALUES (1, 'A-0001-00001234');
-- Error: UQ_Compras_Proveedor_Factura (TecnoSur ya tiene esa factura, compra 1)

BEGIN TRAN;
    INSERT INTO Compras (IdProveedor, NroFactura) VALUES (2, 'A-0001-00001234');
    -- Se acepta: es el mismo número, pero de otro proveedor (Delta Digital)
ROLLBACK;

-- El stock coincide con los movimientos (corrección de la primera entrega).
-- Se ejecuta al final de todas las pruebas: los triggers tienen que haber
-- mantenido sincronizados Stock y MovimientosStock.
SELECT P.IdProducto, P.Modelo, P.Stock, ISNULL(M.Saldo, 0) AS SaldoMovimientos
FROM Productos AS P
LEFT JOIN (
    SELECT IdProducto,
           SUM(CASE WHEN Tipo = 'Ingreso' THEN Cantidad ELSE -Cantidad END) AS Saldo
    FROM MovimientosStock
    GROUP BY IdProducto
) AS M ON M.IdProducto = P.IdProducto
WHERE P.Stock <> ISNULL(M.Saldo, 0);
-- 0 filas
GO