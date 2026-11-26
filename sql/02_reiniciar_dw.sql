-- 02_reiniciar_dw.sql
TRUNCATE TABLE dw.fact_compras, dw.fact_ventas, dw.dim_producto_compra,
  dw.dim_producto_venta, dw.dim_proveedor, dw.dim_categoria, dw.dim_tiempo
  RESTART IDENTITY;
 
INSERT INTO dw.dim_tiempo VALUES (-1, '1900-01-01', 0, 0, 0, 'Desconocido', 0, 0, 'Desconocido', 'N');
INSERT INTO dw.dim_categoria (categoria_key, id_categoria, nombre_categoria, aparece_en)
  VALUES (-1, -1, 'Desconocida', 'N/A');
INSERT INTO dw.dim_proveedor (proveedor_key, ruc, razon_social, categoria_gasto, es_mercaderia)
  VALUES (-1, '0000000000000', 'Desconocido', 'Desconocido', 'NO');
INSERT INTO dw.dim_producto_compra (producto_compra_key, codigo_producto, descripcion, categoria_key)
  VALUES (-1, 'DESCONOCIDO', 'Desconocido', -1);
INSERT INTO dw.dim_producto_venta (producto_venta_key, nombre_producto, categoria_key)
  VALUES (-1, 'Desconocido', -1);


