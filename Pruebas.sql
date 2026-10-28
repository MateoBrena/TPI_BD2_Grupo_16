--==============================================================================
-- PRUEBAS DE FUNCIONES
-- =============================================================================

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
