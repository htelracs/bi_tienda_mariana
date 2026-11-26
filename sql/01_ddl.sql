-- =========================================================
-- 01_ddl.sql  ·  Tienda Mariana  ·  Grupo F
-- =========================================================
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;
 
-- ---------------- STAGING  -------------------------------
DROP TABLE IF EXISTS staging.stg_facturas;
CREATE TABLE staging.stg_facturas (
  id_factura BIGINT, tipo_comprobante TEXT, numero_factura TEXT,
  establecimiento BIGINT, punto_emision BIGINT, secuencial BIGINT,
  fecha_emision DATE, anio BIGINT, mes_numero BIGINT, mes_nombre TEXT,
  fecha_autorizacion TIMESTAMP, ambiente TEXT, tipo_emision TEXT,
  ruc_proveedor BIGINT, razon_social_proveedor TEXT, nombre_comercial TEXT,
  direccion_matriz TEXT, direccion_sucursal TEXT, contribuyente_especial TEXT,
  obligado_contabilidad TEXT, regimen TEXT, agente_retencion TEXT,
  cliente_nombre TEXT, cliente_identificacion BIGINT, cliente_direccion TEXT,
  guia_remision TEXT, subtotal_15 NUMERIC, subtotal_5 NUMERIC, subtotal_0 NUMERIC,
  subtotal_no_objeto_iva NUMERIC, subtotal_exento_iva NUMERIC,
  subtotal_sin_impuestos NUMERIC, total_descuento NUMERIC, ice NUMERIC,
  iva NUMERIC, irbpnr NUMERIC, propina NUMERIC, valor_total NUMERIC,
  forma_pago_codigo BIGINT, forma_pago TEXT, valor_pagado NUMERIC,
  num_items BIGINT, info_adicional TEXT
);

DROP TABLE IF EXISTS staging.stg_detalle;
CREATE TABLE staging.stg_detalle (
  id_detalle BIGINT, id_factura BIGINT, numero_factura TEXT, fecha_emision DATE,
  anio BIGINT, mes_numero BIGINT, ruc_proveedor BIGINT, razon_social_proveedor TEXT,
  linea BIGINT, codigo_producto TEXT, codigo_principal TEXT, codigo_auxiliar TEXT,
  descripcion TEXT, detalle_adicional TEXT, cantidad NUMERIC, precio_unitario NUMERIC,
  subsidio NUMERIC, precio_sin_subsidio NUMERIC, descuento NUMERIC,
  subtotal_linea NUMERIC, tarifa_iva_pct NUMERIC, tarifa_iva_desc TEXT,
  iva_linea NUMERIC, total_linea NUMERIC
);
 
DROP TABLE IF EXISTS staging.stg_proveedores;
CREATE TABLE staging.stg_proveedores (
  ruc_proveedor BIGINT, razon_social TEXT, nombre_comercial TEXT,
  direccion_matriz TEXT, obligado_contabilidad TEXT, regimen TEXT,
  contribuyente_especial TEXT, categoria_gasto TEXT, es_mercaderia TEXT
);
 
DROP TABLE IF EXISTS staging.stg_productos;
CREATE TABLE staging.stg_productos (
  codigo_producto TEXT, razon_social_proveedor TEXT, codigo_principal TEXT,
  codigo_auxiliar TEXT, descripcion TEXT, tarifa_iva_desc TEXT, categoria TEXT
);
 
DROP TABLE IF EXISTS staging.stg_dias_venta;
CREATE TABLE staging.stg_dias_venta (id_dia BIGINT, fecha DATE, dia TEXT);
 
DROP TABLE IF EXISTS staging.stg_ventas;
CREATE TABLE staging.stg_ventas (
  id_venta BIGINT, id_fecha BIGINT, producto TEXT, cantidad TEXT, medida TEXT,
  valor NUMERIC, producto_normalizado TEXT, categoria TEXT
);
 
DROP TABLE IF EXISTS staging.stg_categorias;
CREATE TABLE staging.stg_categorias (id_categoria BIGINT, categoria TEXT, aparece_en TEXT);
 
-- ---------------- DATA WAREHOUSE ----------------
DROP TABLE IF EXISTS dw.fact_ventas, dw.fact_compras, dw.dim_producto_venta,
  dw.dim_producto_compra, dw.dim_proveedor, dw.dim_categoria, dw.dim_tiempo CASCADE;
 
CREATE TABLE dw.dim_tiempo (
  tiempo_key    INTEGER PRIMARY KEY,          -- formato AAAAMMDD, ej. 20261012
  fecha         DATE NOT NULL UNIQUE,
  anio          INTEGER, trimestre INTEGER, mes INTEGER, nombre_mes VARCHAR(12),
  dia           INTEGER, dia_semana INTEGER, nombre_dia VARCHAR(10),
  es_fin_semana CHAR(1)
);
 
CREATE TABLE dw.dim_categoria (
  categoria_key    SERIAL PRIMARY KEY,
  id_categoria     INTEGER UNIQUE,
  nombre_categoria VARCHAR(30) NOT NULL UNIQUE,
  aparece_en       VARCHAR(20)
);
 
CREATE TABLE dw.dim_proveedor (
  proveedor_key         SERIAL PRIMARY KEY,
  ruc                   VARCHAR(13) NOT NULL UNIQUE,
  razon_social          VARCHAR(100),
  nombre_comercial      VARCHAR(100),
  regimen               VARCHAR(30),
  obligado_contabilidad VARCHAR(2),
  categoria_gasto       VARCHAR(30),
  es_mercaderia         VARCHAR(2)
);
 
CREATE TABLE dw.dim_producto_compra (
  producto_compra_key SERIAL PRIMARY KEY,
  codigo_producto     VARCHAR(60) NOT NULL UNIQUE,
  descripcion         VARCHAR(200),
  categoria_key       INTEGER NOT NULL REFERENCES dw.dim_categoria(categoria_key)
);
 
CREATE TABLE dw.dim_producto_venta (
  producto_venta_key SERIAL PRIMARY KEY,
  nombre_producto    VARCHAR(60) NOT NULL UNIQUE,
  categoria_key      INTEGER NOT NULL REFERENCES dw.dim_categoria(categoria_key)
);
 
CREATE TABLE dw.fact_compras (
  compra_key          BIGSERIAL PRIMARY KEY,
  tiempo_key          INTEGER NOT NULL REFERENCES dw.dim_tiempo(tiempo_key),
  proveedor_key       INTEGER NOT NULL REFERENCES dw.dim_proveedor(proveedor_key),
  producto_compra_key INTEGER NOT NULL REFERENCES dw.dim_producto_compra(producto_compra_key),
  numero_factura      VARCHAR(20) NOT NULL,   -- dimensión degenerada
  linea               INTEGER,
  forma_pago          VARCHAR(50),
  cantidad            NUMERIC(12,6),
  precio_unitario     NUMERIC(12,4),
  descuento           NUMERIC(12,2),
  subtotal            NUMERIC(12,2),
  tarifa_iva_pct      NUMERIC(5,2),
  iva                 NUMERIC(12,2),
  total               NUMERIC(12,2),
  es_bonificacion     CHAR(1),
  UNIQUE (proveedor_key, numero_factura, linea)
);
 
CREATE TABLE dw.fact_ventas (
  venta_key          BIGSERIAL PRIMARY KEY,
  id_venta           INTEGER NOT NULL UNIQUE,
  tiempo_key         INTEGER NOT NULL REFERENCES dw.dim_tiempo(tiempo_key),
  producto_venta_key INTEGER NOT NULL REFERENCES dw.dim_producto_venta(producto_venta_key),
  cantidad           NUMERIC(10,2),
  medida             VARCHAR(20),
  valor              NUMERIC(10,2),
  precio_unitario    NUMERIC(10,4)
);

ALTER TABLE dw.dim_tiempo ALTER COLUMN nombre_dia TYPE VARCHAR(12);