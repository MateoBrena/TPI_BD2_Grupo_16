-- =============================================================
-- UTN Hardware - Vistas (Parte 2)
-- Base de Datos II - Equipo 16
-- Orden de ejecución: Creacion.sql -> Datos.sql -> Funciones.sql -> Vistas.sql
-- =============================================================
-- Consultas del negocio listas para usar: productos con bajo
-- stock, resumen de pedidos, ranking de clientes, ventas por
-- categoría, stock disponible y resumen de compras. Cuatro se
-- apoyan en las funciones de Funciones.sql.
--
-- El script se puede ejecutar varias veces: si la vista ya existe,
-- la elimina y la vuelve a crear.
-- =============================================================

USE UTN_Hardware;
GO

-- -------------------------------------------------------------
-- vi_ProductosBajoStock
-- Productos activos cuyo stock disponible llegó a su stock mínimo
-- o está por debajo. Indica qué hay que reponer.
-- Los productos inactivos no se muestran porque ya no se venden.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.vi_ProductosBajoStock', 'V') IS NOT NULL
    DROP VIEW dbo.vi_ProductosBajoStock;
GO

CREATE VIEW dbo.vi_ProductosBajoStock
AS
SELECT
    P.IdProducto,
    C.Nombre    AS Categoria,
    M.Nombre    AS Marca,
    P.Modelo,
    P.Stock,
    P.StockMinimo
FROM Productos AS P
INNER JOIN Categorias AS C ON C.IdCategoria = P.IdCategoria
INNER JOIN Marcas     AS M ON M.IdMarca     = P.IdMarca
WHERE P.Activo = 1
  AND P.Stock <= P.StockMinimo;
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
-- vi_VentasPorCategoria
-- Unidades y monto vendidos por categoría. Solo cuenta pedidos
-- Confirmados y Entregados. Usa el precio guardado en DetallePedido.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.vi_VentasPorCategoria', 'V') IS NOT NULL
    DROP VIEW dbo.vi_VentasPorCategoria;
GO

CREATE VIEW dbo.vi_VentasPorCategoria
AS
SELECT
    C.IdCategoria,
    C.Nombre                                AS Categoria,
    SUM(DP.Cantidad)                        AS UnidadesVendidas,
    SUM(DP.Cantidad * DP.PrecioUnitario)    AS MontoVendido
FROM DetallePedido AS DP
INNER JOIN Pedidos    AS PE ON PE.IdPedido   = DP.IdPedido
INNER JOIN Productos  AS P  ON P.IdProducto  = DP.IdProducto
INNER JOIN Categorias AS C  ON C.IdCategoria = P.IdCategoria
WHERE PE.Estado IN ('Confirmado', 'Entregado')
GROUP BY C.IdCategoria, C.Nombre;
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

-- -------------------------------------------------------------
-- vi_ComprasResumen
-- Un renglón por compra: fecha, proveedor, número de factura,
-- estado, cantidad de productos distintos y total (calculado con
-- fn_TotalCompra). Muestra todas las compras, en cualquier estado.
-- Es la pareja de vi_PedidosResumen: las dos patas del modelo
-- (comprar y vender) tienen su resumen.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.vi_ComprasResumen', 'V') IS NOT NULL
    DROP VIEW dbo.vi_ComprasResumen;
GO

CREATE VIEW dbo.vi_ComprasResumen
AS
SELECT
    CO.IdCompra,
    CO.Fecha,
    PR.RazonSocial                     AS Proveedor,
    CO.NroFactura,
    CO.Estado,
    COUNT(DC.IdProducto)               AS CantidadProductos,
    dbo.fn_TotalCompra(CO.IdCompra)    AS Total
FROM Compras AS CO
INNER JOIN Proveedores AS PR ON PR.IdProveedor = CO.IdProveedor
LEFT JOIN DetalleCompra AS DC ON DC.IdCompra = CO.IdCompra
GROUP BY CO.IdCompra, CO.Fecha, PR.RazonSocial, CO.NroFactura, CO.Estado;
GO
