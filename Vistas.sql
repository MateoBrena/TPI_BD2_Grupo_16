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
