-- =============================================================
-- UTN Hardware - Creación de la base de datos y sus tablas
-- Base de Datos II - Equipo 16
-- Ejecutar antes que Datos.sql. Si la base ya existe, la elimina
-- y la vuelve a crear vacía.
-- =============================================================

-- -------------------------------------------------------------
-- 1. Creación de la base de datos
-- -------------------------------------------------------------
USE master;
GO

IF DB_ID('UTN_Hardware') IS NOT NULL
BEGIN
    ALTER DATABASE UTN_Hardware SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UTN_Hardware;
END
GO

CREATE DATABASE UTN_Hardware;
GO

USE UTN_Hardware;
GO

-- -------------------------------------------------------------
-- 2. Creación de tablas
-- -------------------------------------------------------------
CREATE TABLE Categorias (
    IdCategoria INT IDENTITY(1,1) NOT NULL,
    Nombre      VARCHAR(50)  NOT NULL,
    Descripcion VARCHAR(200) NULL,
    CONSTRAINT PK_Categorias PRIMARY KEY (IdCategoria),
    CONSTRAINT UQ_Categorias_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE Marcas (
    IdMarca    INT IDENTITY(1,1) NOT NULL,
    Nombre     VARCHAR(50) NOT NULL,
    PaisOrigen VARCHAR(50) NULL,
    CONSTRAINT PK_Marcas PRIMARY KEY (IdMarca),
    CONSTRAINT UQ_Marcas_Nombre UNIQUE (Nombre)
);
GO

CREATE TABLE Proveedores (
    IdProveedor INT IDENTITY(1,1) NOT NULL,
    RazonSocial VARCHAR(100) NOT NULL,
    CUIT        CHAR(11)     NOT NULL,
    Email       VARCHAR(100) NULL,
    Telefono    VARCHAR(20)  NULL,
    CONSTRAINT PK_Proveedores PRIMARY KEY (IdProveedor),
    CONSTRAINT UQ_Proveedores_CUIT UNIQUE (CUIT),
    CONSTRAINT CK_Proveedores_CUIT CHECK (CUIT NOT LIKE '%[^0-9]%' AND LEN(CUIT) = 11)
);
GO

CREATE TABLE Clientes (
    IdCliente INT IDENTITY(1,1) NOT NULL,
    DNI       VARCHAR(8)   NOT NULL,
    Nombre    VARCHAR(50)  NOT NULL,
    Apellido  VARCHAR(50)  NOT NULL,
    Email     VARCHAR(100) NOT NULL,
    Telefono  VARCHAR(20)  NULL,
    FechaAlta DATE NOT NULL CONSTRAINT DF_Clientes_FechaAlta DEFAULT (GETDATE()),
    CONSTRAINT PK_Clientes PRIMARY KEY (IdCliente),
    CONSTRAINT UQ_Clientes_DNI UNIQUE (DNI),
    CONSTRAINT UQ_Clientes_Email UNIQUE (Email),
    CONSTRAINT CK_Clientes_DNI
        CHECK (DNI NOT LIKE '%[^0-9]%' AND LEN(DNI) BETWEEN 7 AND 8),
    CONSTRAINT CK_Clientes_Email CHECK (Email LIKE '%_@_%._%')
);
GO

CREATE TABLE Productos (
    IdProducto  INT IDENTITY(1,1) NOT NULL,
    IdCategoria INT NOT NULL,
    IdMarca     INT NOT NULL,
    Modelo      VARCHAR(100) NOT NULL,
    Descripcion VARCHAR(300) NULL,
    Precio      DECIMAL(12,2) NOT NULL,
    Stock       INT NOT NULL CONSTRAINT DF_Productos_Stock DEFAULT (0),
    StockMinimo INT NOT NULL CONSTRAINT DF_Productos_StockMinimo DEFAULT (0),
    Activo      BIT NOT NULL CONSTRAINT DF_Productos_Activo DEFAULT (1),
    CONSTRAINT PK_Productos PRIMARY KEY (IdProducto),
    CONSTRAINT FK_Productos_Categorias FOREIGN KEY (IdCategoria)
        REFERENCES Categorias (IdCategoria),
    CONSTRAINT FK_Productos_Marcas FOREIGN KEY (IdMarca) REFERENCES Marcas (IdMarca),
    CONSTRAINT CK_Productos_Precio CHECK (Precio > 0),
    CONSTRAINT CK_Productos_Stock CHECK (Stock >= 0),
    CONSTRAINT CK_Productos_StockMinimo CHECK (StockMinimo >= 0)
);
GO

CREATE TABLE Compras (
    IdCompra    INT IDENTITY(1,1) NOT NULL,
    IdProveedor INT NOT NULL,
    Fecha       DATETIME NOT NULL CONSTRAINT DF_Compras_Fecha DEFAULT (GETDATE()),
    NroFactura  VARCHAR(20) NOT NULL,
    Estado      VARCHAR(20) NOT NULL CONSTRAINT DF_Compras_Estado DEFAULT ('Pendiente'),
    CONSTRAINT PK_Compras PRIMARY KEY (IdCompra),
    CONSTRAINT FK_Compras_Proveedores FOREIGN KEY (IdProveedor)
        REFERENCES Proveedores (IdProveedor),
    CONSTRAINT CK_Compras_Estado CHECK (Estado IN ('Pendiente', 'Recibida', 'Anulada'))
);
GO

CREATE TABLE DetalleCompra (
    IdCompra      INT NOT NULL,
    IdProducto    INT NOT NULL,
    Cantidad      INT NOT NULL,
    CostoUnitario DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_DetalleCompra PRIMARY KEY (IdCompra, IdProducto),
    CONSTRAINT FK_DetalleCompra_Compras FOREIGN KEY (IdCompra)
        REFERENCES Compras (IdCompra),
    CONSTRAINT FK_DetalleCompra_Productos FOREIGN KEY (IdProducto)
        REFERENCES Productos (IdProducto),
    CONSTRAINT CK_DetalleCompra_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetalleCompra_Costo CHECK (CostoUnitario > 0)
);
GO

CREATE TABLE Pedidos (
    IdPedido       INT IDENTITY(1,1) NOT NULL,
    IdCliente      INT NOT NULL,
    Fecha          DATETIME NOT NULL CONSTRAINT DF_Pedidos_Fecha DEFAULT (GETDATE()),
    Estado         VARCHAR(20)  NOT NULL
        CONSTRAINT DF_Pedidos_Estado DEFAULT ('Pendiente'),
    DireccionEnvio VARCHAR(200) NOT NULL,
    CONSTRAINT PK_Pedidos PRIMARY KEY (IdPedido),
    CONSTRAINT FK_Pedidos_Clientes FOREIGN KEY (IdCliente)
        REFERENCES Clientes (IdCliente),
    CONSTRAINT CK_Pedidos_Estado
        CHECK (Estado IN ('Pendiente', 'Confirmado', 'Entregado', 'Cancelado'))
);
GO

CREATE TABLE DetallePedido (
    IdPedido       INT NOT NULL,
    IdProducto     INT NOT NULL,
    Cantidad       INT NOT NULL,
    PrecioUnitario DECIMAL(12,2) NOT NULL,
    CONSTRAINT PK_DetallePedido PRIMARY KEY (IdPedido, IdProducto),
    CONSTRAINT FK_DetallePedido_Pedidos FOREIGN KEY (IdPedido)
        REFERENCES Pedidos (IdPedido),
    CONSTRAINT FK_DetallePedido_Productos FOREIGN KEY (IdProducto)
        REFERENCES Productos (IdProducto),
    CONSTRAINT CK_DetallePedido_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_DetallePedido_Precio CHECK (PrecioUnitario > 0)
);
GO

CREATE TABLE MovimientosStock (
    IdMovimiento INT IDENTITY(1,1) NOT NULL,
    IdProducto   INT NOT NULL,
    IdCompra     INT NULL,
    IdPedido     INT NULL,
    Fecha        DATETIME NOT NULL CONSTRAINT DF_Movimientos_Fecha DEFAULT (GETDATE()),
    Tipo         VARCHAR(10) NOT NULL,
    Origen       VARCHAR(20) NOT NULL,
    Cantidad     INT NOT NULL,
    CONSTRAINT PK_MovimientosStock PRIMARY KEY (IdMovimiento),
    CONSTRAINT FK_Movimientos_Productos FOREIGN KEY (IdProducto)
        REFERENCES Productos (IdProducto),
    CONSTRAINT FK_Movimientos_Compras FOREIGN KEY (IdCompra)
        REFERENCES Compras (IdCompra),
    CONSTRAINT FK_Movimientos_Pedidos FOREIGN KEY (IdPedido)
        REFERENCES Pedidos (IdPedido),
    CONSTRAINT CK_Movimientos_Tipo CHECK (Tipo IN ('Ingreso', 'Egreso')),
    CONSTRAINT CK_Movimientos_Cantidad CHECK (Cantidad > 0),
    -- El origen determina el tipo de movimiento y a qué operación se vincula
    CONSTRAINT CK_Movimientos_Origen CHECK (
        (Origen = 'Compra' AND Tipo = 'Ingreso'
            AND IdCompra IS NOT NULL AND IdPedido IS NULL)
     OR (Origen = 'Venta' AND Tipo = 'Egreso'
            AND IdPedido IS NOT NULL AND IdCompra IS NULL)
     OR (Origen IN ('Cancelación', 'Baja de ítem') AND Tipo = 'Ingreso'
            AND IdPedido IS NOT NULL AND IdCompra IS NULL)
    )
);
GO
