
--Conteo de filas
SELECT 'dim_tiempo' tabla, COUNT(*) FROM dw.dim_tiempo
UNION ALL SELECT 'dim_categoria', COUNT(*) FROM dw.dim_categoria
UNION ALL SELECT 'dim_proveedor', COUNT(*) FROM dw.dim_proveedor
UNION ALL SELECT 'dim_producto_compra', COUNT(*) FROM dw.dim_producto_compra
UNION ALL SELECT 'dim_producto_venta', COUNT(*) FROM dw.dim_producto_venta
UNION ALL SELECT 'fact_compras', COUNT(*) FROM dw.fact_compras
UNION ALL SELECT 'fact_ventas', COUNT(*) FROM dw.fact_ventas
UNION ALL SELECT 'compras con clave -1', COUNT(*) FROM dw.fact_compras
          WHERE tiempo_key = -1 OR proveedor_key = -1 OR producto_compra_key = -1
UNION ALL SELECT 'ventas con clave -1', COUNT(*) FROM dw.fact_ventas
          WHERE tiempo_key = -1 OR producto_venta_key = -1;


--Ningún hecho apunta a "Desconocido"
SELECT COUNT(*) AS compras_sin_clave FROM dw.fact_compras
WHERE tiempo_key = -1 OR proveedor_key = -1 OR producto_compra_key = -1;   
 
SELECT COUNT(*) AS ventas_sin_clave FROM dw.fact_ventas
WHERE tiempo_key = -1 OR producto_venta_key = -1;                          
 
SELECT COUNT(*) FROM dw.dim_producto_compra WHERE categoria_key = -1 AND producto_compra_key <> -1;  

--regla de limpieza aplicadas
SELECT MAX(precio_unitario) FROM dw.fact_compras;         
SELECT DISTINCT tarifa_iva_pct FROM dw.fact_compras;      
SELECT es_bonificacion, COUNT(*) FROM dw.fact_compras GROUP BY 1;   
SELECT COUNT(*) FROM dw.dim_proveedor WHERE LENGTH(ruc) <> 13;      
SELECT medida, COUNT(*) FROM dw.fact_ventas GROUP BY 1 ORDER BY 2 DESC;
  
