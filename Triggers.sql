-- =============================================================
-- UTN Hardware - Triggers
-- Base de Datos II - Equipo 16
-- Orden de ejecución: Creacion.sql -> Datos.sql -> Funciones.sql
--                     -> Vistas.sql -> Procedimientos.sql -> Triggers.sql
-- =============================================================
-- Los triggers se crean después de cargar los datos: si existieran
-- antes, los INSERT de Datos.sql los dispararían y el stock se
-- movería dos veces.
--
-- Todos manejan las tablas inserted y deleted como conjuntos: un
-- trigger se dispara una sola vez por sentencia, aunque la sentencia
-- afecte varias filas.
--
-- El script se puede ejecutar varias veces: si el trigger ya
-- existe, lo elimina y lo vuelve a crear.
-- =============================================================

USE UTN_Hardware;
GO

-- =============================================================
-- PARTE 4 - RECEPCIÓN DE COMPRAS
-- =============================================================

-- -------------------------------------------------------------
-- tr_Compras_Update
-- Se dispara al modificar compras.
-- 1) Valida las transiciones de estado. Solo se permiten:
--      Pendiente -> Recibida
--      Pendiente -> Anulada
--    Recibida y Anulada son finales. Si una compra Recibida pudiera
--    volver a Pendiente, se podría recibir dos veces y el stock se
--    sumaría dos veces. Si alguna fila no cumple, se deshace toda la
--    operación.
-- 2) Para cada compra que pasa de Pendiente a Recibida:
--      - suma al Stock de cada producto las unidades compradas,
--      - registra un Ingreso con origen Compra en MovimientosStock.
-- Las filas que no cambian de estado (por ejemplo, si solo se
-- corrige el número de factura) no se tocan.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.tr_Compras_Update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Compras_Update;
GO

CREATE TRIGGER dbo.tr_Compras_Update
ON Compras
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Transiciones no permitidas: cambió el estado y no es
    --    Pendiente -> Recibida ni Pendiente -> Anulada
    IF EXISTS (
        SELECT 1
        FROM inserted AS I
        INNER JOIN deleted AS D ON D.IdCompra = I.IdCompra
        WHERE I.Estado <> D.Estado
          AND NOT (D.Estado = 'Pendiente' AND I.Estado IN ('Recibida', 'Anulada'))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50010, 'Transición de estado no permitida: una compra solo puede pasar de Pendiente a Recibida o a Anulada.', 1;
    END;

    -- 2a) Sumar el stock. Se agrupa por producto porque un mismo
    --     UPDATE puede recibir varias compras que traen el mismo
    --     producto; sin agrupar, solo se sumaría una de ellas.
    UPDATE P
    SET P.Stock = P.Stock + R.Cantidad
    FROM Productos AS P
    INNER JOIN (
        SELECT DC.IdProducto, SUM(DC.Cantidad) AS Cantidad
        FROM inserted AS I
        INNER JOIN deleted       AS D  ON D.IdCompra  = I.IdCompra
        INNER JOIN DetalleCompra AS DC ON DC.IdCompra = I.IdCompra
        WHERE D.Estado = 'Pendiente'
          AND I.Estado = 'Recibida'
        GROUP BY DC.IdProducto
    ) AS R ON R.IdProducto = P.IdProducto;

    -- 2b) Registrar un Ingreso por cada producto de cada compra recibida
    INSERT INTO MovimientosStock (IdProducto, IdCompra, IdPedido, Fecha, Tipo, Origen, Cantidad)
    SELECT DC.IdProducto, DC.IdCompra, NULL, GETDATE(), 'Ingreso', 'Compra', DC.Cantidad
    FROM inserted AS I
    INNER JOIN deleted       AS D  ON D.IdCompra  = I.IdCompra
    INNER JOIN DetalleCompra AS DC ON DC.IdCompra = I.IdCompra
    WHERE D.Estado = 'Pendiente'
      AND I.Estado = 'Recibida';
END;
GO

-- =============================================================
-- PARTE 5 - TRIGGERS DE PEDIDOS
-- El stock se reserva al agregar un producto al pedido (no al
-- confirmarlo), para no vender dos veces la misma unidad. Cada
-- cambio de stock se registra en MovimientosStock en la misma
-- operación, así Stock y el historial nunca se desincronizan.
-- Solo se agregan o quitan productos de un pedido Pendiente.
-- =============================================================

-- -------------------------------------------------------------
-- tr_Pedidos_Update
-- Se dispara al modificar pedidos.
-- 1) Valida las transiciones de estado. Solo se permiten:
--      Pendiente  -> Confirmado
--      Confirmado -> Entregado
--      Pendiente  -> Cancelado
--      Confirmado -> Cancelado
--    Entregado y Cancelado son finales. Si un pedido Cancelado
--    pudiera volver a Pendiente, se podría cancelar dos veces y el
--    stock se repondría dos veces. Si alguna fila no cumple, se
--    deshace toda la operación.
-- 2) Para cada pedido que pasa a Cancelado:
--      - repone el stock de todos sus productos,
--      - registra un Ingreso con origen Cancelación por cada uno.
--    El pedido y su detalle no se borran: la venta cancelada queda
--    registrada.
-- Confirmar o entregar no mueve el stock: ya se descontó al agregar
-- los productos. Las filas que no cambian de estado (por ejemplo,
-- si solo se corrige la dirección de envío) no se tocan.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.tr_Pedidos_Update', 'TR') IS NOT NULL
    DROP TRIGGER dbo.tr_Pedidos_Update;
GO

CREATE TRIGGER dbo.tr_Pedidos_Update
ON Pedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Transiciones no permitidas
    IF EXISTS (
        SELECT 1
        FROM inserted AS I
        INNER JOIN deleted AS D ON D.IdPedido = I.IdPedido
        WHERE I.Estado <> D.Estado
          AND NOT (   (D.Estado = 'Pendiente'  AND I.Estado IN ('Confirmado', 'Cancelado'))
                   OR (D.Estado = 'Confirmado' AND I.Estado IN ('Entregado', 'Cancelado')))
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50034, 'Transición de estado no permitida: Pendiente -> Confirmado -> Entregado, o Pendiente/Confirmado -> Cancelado. Entregado y Cancelado son finales.', 1;
    END;

    -- 2a) Reponer el stock de los pedidos cancelados (agrupado por producto)
    UPDATE P
    SET P.Stock = P.Stock + R.Cantidad
    FROM Productos AS P
    INNER JOIN (
        SELECT DP.IdProducto, SUM(DP.Cantidad) AS Cantidad
        FROM inserted AS I
        INNER JOIN deleted       AS D  ON D.IdPedido  = I.IdPedido
        INNER JOIN DetallePedido AS DP ON DP.IdPedido = I.IdPedido
        WHERE D.Estado <> 'Cancelado'
          AND I.Estado = 'Cancelado'
        GROUP BY DP.IdProducto
    ) AS R ON R.IdProducto = P.IdProducto;

    -- 2b) Registrar un Ingreso por cada producto de cada pedido cancelado
    INSERT INTO MovimientosStock (IdProducto, IdCompra, IdPedido, Fecha, Tipo, Origen, Cantidad)
    SELECT DP.IdProducto, NULL, DP.IdPedido, GETDATE(), 'Ingreso', 'Cancelación', DP.Cantidad
    FROM inserted AS I
    INNER JOIN deleted       AS D  ON D.IdPedido  = I.IdPedido
    INNER JOIN DetallePedido AS DP ON DP.IdPedido = I.IdPedido
    WHERE D.Estado <> 'Cancelado'
      AND I.Estado = 'Cancelado';
END;
GO