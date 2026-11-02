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