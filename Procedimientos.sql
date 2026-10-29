-- =============================================================
-- UTN Hardware - Procedimientos almacenados
-- Base de Datos II - Equipo 16
-- Orden de ejecución: Creacion.sql -> Datos.sql -> Funciones.sql
--                     -> Vistas.sql -> Procedimientos.sql
-- =============================================================
-- El script se puede ejecutar varias veces: si el procedimiento ya
-- existe, lo elimina y lo vuelve a crear.
-- =============================================================

USE UTN_Hardware;
GO

-- =============================================================
-- PARTE 3 - PROCEDIMIENTOS DE REPORTE
-- Reciben un rango de fechas y devuelven resultados sin escribir.
-- Reglas comunes:
--   - Las dos fechas son obligatorias y @Desde no puede ser mayor
--     que @Hasta; si no, se rechaza con un mensaje claro.
--   - @Hasta se incluye completo: como las fechas guardadas tienen
--     hora, se filtra con Fecha < @Hasta + 1 día.
-- =============================================================

-- -------------------------------------------------------------
-- pa_VentasPorPeriodo
-- Unidades y monto vendidos por producto entre dos fechas.
-- Solo cuenta pedidos Confirmados y Entregados (regla de los
-- reportes de ventas). Usa el precio guardado en DetallePedido.
-- Ordena por monto vendido, de mayor a menor.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.pa_VentasPorPeriodo', 'P') IS NOT NULL
    DROP PROCEDURE dbo.pa_VentasPorPeriodo;
GO

CREATE PROCEDURE dbo.pa_VentasPorPeriodo
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @Desde IS NULL OR @Hasta IS NULL
        THROW 50001, 'Las fechas Desde y Hasta son obligatorias.', 1;

    IF @Desde > @Hasta
        THROW 50002, 'Rango de fechas inválido: Desde no puede ser mayor que Hasta.', 1;

    SELECT
        P.IdProducto,
        C.Nombre                                AS Categoria,
        M.Nombre                                AS Marca,
        P.Modelo,
        SUM(DP.Cantidad)                        AS UnidadesVendidas,
        SUM(DP.Cantidad * DP.PrecioUnitario)    AS MontoVendido
    FROM Pedidos AS PE
    INNER JOIN DetallePedido AS DP ON DP.IdPedido    = PE.IdPedido
    INNER JOIN Productos     AS P  ON P.IdProducto   = DP.IdProducto
    INNER JOIN Categorias    AS C  ON C.IdCategoria  = P.IdCategoria
    INNER JOIN Marcas        AS M  ON M.IdMarca      = P.IdMarca
    WHERE PE.Estado IN ('Confirmado', 'Entregado')
      AND PE.Fecha >= @Desde
      AND PE.Fecha <  DATEADD(DAY, 1, @Hasta)
    GROUP BY P.IdProducto, C.Nombre, M.Nombre, P.Modelo
    ORDER BY MontoVendido DESC;
END;
GO

-- -------------------------------------------------------------
-- pa_ComprasPorPeriodo
-- Compras a proveedores entre dos fechas, con proveedor, factura,
-- estado y total (calculado con fn_TotalCompra).
-- Muestra todas las compras, en cualquier estado (Recibida,
-- Pendiente o Anulada): el reporte es un listado de lo que se
-- registró en el período, y la columna Estado permite distinguirlas.
-- Ordena por fecha.
-- -------------------------------------------------------------
IF OBJECT_ID('dbo.pa_ComprasPorPeriodo', 'P') IS NOT NULL
    DROP PROCEDURE dbo.pa_ComprasPorPeriodo;
GO

CREATE PROCEDURE dbo.pa_ComprasPorPeriodo
    @Desde DATE,
    @Hasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF @Desde IS NULL OR @Hasta IS NULL
        THROW 50001, 'Las fechas Desde y Hasta son obligatorias.', 1;

    IF @Desde > @Hasta
        THROW 50002, 'Rango de fechas inválido: Desde no puede ser mayor que Hasta.', 1;

    SELECT
        CO.IdCompra,
        CO.Fecha,
        PR.RazonSocial                  AS Proveedor,
        CO.NroFactura,
        CO.Estado,
        dbo.fn_TotalCompra(CO.IdCompra) AS Total
    FROM Compras AS CO
    INNER JOIN Proveedores AS PR ON PR.IdProveedor = CO.IdProveedor
    WHERE CO.Fecha >= @Desde
      AND CO.Fecha <  DATEADD(DAY, 1, @Hasta)
    ORDER BY CO.Fecha;
END;
GO
