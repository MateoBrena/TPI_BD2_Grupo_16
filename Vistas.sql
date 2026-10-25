-- =============================================================
-- UTN Hardware - Vistas (Parte 2)
-- Base de Datos II - Equipo 16
-- Orden de ejecución: Creacion.sql -> Datos.sql -> Funciones.sql -> Vistas.sql
-- =============================================================

USE UTN_Hardware;
GO

-- -------------------------------------------------------------
-- vi_PedidosResumen
-- Un renglón por pedido: fecha, cliente, estado, cantidad de
-- productos distintos y total (calculado con fn_TotalPedido).
-- Muestra todos los pedidos, en cualquier estado.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.vi_PedidosResumen', 'V') IS NOT NULL
    DROP VIEW dbo.vi_PedidosResumen;
GO

CREATE VIEW dbo.vi_PedidosResumen
AS
SELECT
    PE.IdPedido,
    PE.Fecha,
    CL.Nombre + ' ' + CL.Apellido      AS Cliente,
    PE.Estado,
    COUNT(DP.IdProducto)               AS CantidadProductos,
    dbo.fn_TotalPedido(PE.IdPedido)    AS Total
FROM Pedidos AS PE
INNER JOIN Clientes AS CL ON CL.IdCliente = PE.IdCliente
LEFT JOIN DetallePedido AS DP ON DP.IdPedido = PE.IdPedido
GROUP BY PE.IdPedido, PE.Fecha, CL.Nombre, CL.Apellido, PE.Estado;
GO
-- -------------------------------------------------------------
-- vi_RankingClientes
-- Cada cliente con su cantidad de pedidos y el total comprado
-- (calculado con fn_TotalComprasCliente).
-- Igual que el total, la cantidad solo cuenta pedidos Confirmados y
-- Entregados (regla de los reportes de ventas), así las dos columnas
-- hablan de lo mismo. Aparecen todos los clientes, aunque no hayan
-- comprado (con 0).
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.vi_RankingClientes', 'V') IS NOT NULL
    DROP VIEW dbo.vi_RankingClientes;
GO

CREATE VIEW dbo.vi_RankingClientes
AS
SELECT
    CL.IdCliente,
    CL.Nombre + ' ' + CL.Apellido               AS Cliente,
    COUNT(PE.IdPedido)                          AS CantidadPedidos,
    dbo.fn_TotalComprasCliente(CL.IdCliente)    AS TotalComprado
FROM Clientes AS CL
LEFT JOIN Pedidos AS PE
    ON PE.IdCliente = CL.IdCliente
   AND PE.Estado IN ('Confirmado', 'Entregado')
GROUP BY CL.IdCliente, CL.Nombre, CL.Apellido;
GO

-- -------------------------------------------------------------
-- vi_StockDisponible
-- Por producto, las tres miradas del stock:
--   Disponible   = Stock de Productos (lo que se puede vender)
--   Comprometido = unidades en pedidos Pendientes o Confirmados
--                  (calculado con fn_StockComprometido)
--   Fisico       = Disponible + Comprometido (lo que hay en depósito)
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.vi_StockDisponible', 'V') IS NOT NULL
    DROP VIEW dbo.vi_StockDisponible;
GO

CREATE VIEW dbo.vi_StockDisponible
AS
SELECT
    P.IdProducto,
    M.Nombre                                        AS Marca,
    P.Modelo,
    P.Stock                                         AS Disponible,
    dbo.fn_StockComprometido(P.IdProducto)          AS Comprometido,
    P.Stock + dbo.fn_StockComprometido(P.IdProducto) AS Fisico
FROM Productos AS P
INNER JOIN Marcas AS M ON M.IdMarca = P.IdMarca;
GO
