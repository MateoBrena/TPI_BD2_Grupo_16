-- =============================================================
-- UTN Hardware - Funciones de usuario (Parte 1)
-- Base de Datos II - Equipo 16
-- Orden de ejecución: Creacion.sql -> Datos.sql -> Funciones.sql
-- =============================================================
-- Calculan los datos derivados (totales y stock comprometido) en un
-- solo lugar, para reutilizarlos en vistas y procedimientos. Los
-- totales no se guardan en ninguna columna: se calculan siempre a
-- partir del detalle, así nunca quedan desactualizados.
--
-- Todas devuelven 0 (y no NULL) cuando no hay filas para sumar, para
-- que se puedan usar directamente en cálculos y en reportes.
--
-- El script se puede ejecutar varias veces: si la función ya existe,
-- la elimina y la vuelve a crear.
-- =============================================================

USE UTN_Hardware;
GO

-- -------------------------------------------------------------
-- fn_TotalPedido
-- Devuelve el total de un pedido: suma de Cantidad x PrecioUnitario
-- de su detalle. Usa el precio guardado en DetallePedido (precio del
-- momento de la venta), no el precio actual del producto.
-- No filtra por estado: calcula el total de cualquier pedido.
-- Devuelve 0 si el pedido no tiene productos o no existe.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.fn_TotalPedido', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_TotalPedido;
GO

CREATE FUNCTION dbo.fn_TotalPedido (@IdPedido INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Total DECIMAL(12,2);

    SELECT @Total = SUM(DP.Cantidad * DP.PrecioUnitario)
    FROM DetallePedido AS DP
    WHERE DP.IdPedido = @IdPedido;

    RETURN ISNULL(@Total, 0);
END;
GO
-- -------------------------------------------------------------
-- fn_TotalComprasCliente
-- Devuelve el total comprado por un cliente. Solo cuenta pedidos
-- Confirmados y Entregados (regla de los reportes de ventas): un
-- pedido Pendiente todavía no es una venta cerrada y uno Cancelado
-- se dio de baja.
-- Devuelve 0 si el cliente no tiene compras que cuenten o no existe.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.fn_TotalComprasCliente', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_TotalComprasCliente;
GO

CREATE FUNCTION dbo.fn_TotalComprasCliente (@IdCliente INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @Total DECIMAL(12,2);

    SELECT @Total = SUM(DP.Cantidad * DP.PrecioUnitario)
    FROM Pedidos AS P
    INNER JOIN DetallePedido AS DP ON DP.IdPedido = P.IdPedido
    WHERE P.IdCliente = @IdCliente
      AND P.Estado IN ('Confirmado', 'Entregado');

    RETURN ISNULL(@Total, 0);
END;
GO

-- -------------------------------------------------------------
-- fn_StockComprometido
-- Devuelve las unidades de un producto que están en pedidos
-- Pendientes o Confirmados: ya se descontaron del Stock (reservadas)
-- pero todavía no salieron del depósito.
-- Es solo un cálculo de consulta: no mueve stock.
--   Stock (Productos)     = disponible para vender
--   Stock + comprometido  = físico en depósito
-- No cuenta pedidos Entregados (ya salieron) ni Cancelados (se repusieron).
-- Devuelve 0 si el producto no está en pedidos abiertos.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.fn_StockComprometido', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_StockComprometido;
GO

CREATE FUNCTION dbo.fn_StockComprometido (@IdProducto INT)
RETURNS INT
AS
BEGIN
    DECLARE @Comprometido INT;

    SELECT @Comprometido = SUM(DP.Cantidad)
    FROM DetallePedido AS DP
    INNER JOIN Pedidos AS P ON P.IdPedido = DP.IdPedido
    WHERE DP.IdProducto = @IdProducto
      AND P.Estado IN ('Pendiente', 'Confirmado');

    RETURN ISNULL(@Comprometido, 0);
END;
GO
