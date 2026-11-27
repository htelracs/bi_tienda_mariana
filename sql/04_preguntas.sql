--P1. ¿Qué productos generan más ingresos y cuáles se venden con más frecuencia?
SELECT p.nombre_producto,
       SUM(f.valor)  AS ingreso,
       COUNT(*)      AS veces_vendido
FROM dw.fact_ventas f
JOIN dw.dim_producto_venta p ON p.producto_venta_key = f.producto_venta_key
GROUP BY p.nombre_producto
ORDER BY ingreso DESC
LIMIT 10;


--P2. ¿Qué categorías aportan más a las ventas?
SELECT c.nombre_categoria,
       SUM(f.valor) AS ventas,
       ROUND(100 * SUM(f.valor) / SUM(SUM(f.valor)) OVER (), 1) AS pct
FROM dw.fact_ventas f
JOIN dw.dim_producto_venta p ON p.producto_venta_key = f.producto_venta_key
JOIN dw.dim_categoria c      ON c.categoria_key      = p.categoria_key
GROUP BY c.nombre_categoria
ORDER BY ventas DESC;


--P3. ¿Cómo varían las ventas según el día de la semana?
SELECT t.dia_semana, t.nombre_dia,
       COUNT(DISTINCT t.fecha) AS dias_registrados,
       SUM(f.valor) AS total,
       ROUND(SUM(f.valor) / COUNT(DISTINCT t.fecha), 2) AS promedio_diario
FROM dw.fact_ventas f
JOIN dw.dim_tiempo t ON t.tiempo_key = f.tiempo_key
GROUP BY t.dia_semana, t.nombre_dia
ORDER BY t.dia_semana;



--P4. ¿Cuánto se gasta por proveedor y qué tan concentradas están las compras?
SELECT pr.razon_social,
       SUM(f.total) AS compras,
       ROUND(100 * SUM(f.total) / SUM(SUM(f.total)) OVER (), 1) AS pct
FROM dw.fact_compras f
JOIN dw.dim_proveedor pr ON pr.proveedor_key = f.proveedor_key
WHERE pr.es_mercaderia = 'SI'
GROUP BY pr.razon_social
ORDER BY compras DESC
LIMIT 10;



--P5. ¿Cómo evoluciona el gasto en compras mes a mes?
SELECT t.anio, t.mes, t.nombre_mes, SUM(f.total) AS compras
FROM dw.fact_compras f
JOIN dw.dim_tiempo t ON t.tiempo_key = f.tiempo_key
GROUP BY t.anio, t.mes, t.nombre_mes
ORDER BY t.anio, t.mes;


--P6. ¿Qué parte de lo facturado a nombre de la tienda no es mercadería?
SELECT pr.es_mercaderia, pr.categoria_gasto,
       SUM(f.total) AS total,
       ROUND(100 * SUM(f.total) / SUM(SUM(f.total)) OVER (), 1) AS pct
FROM dw.fact_compras f
JOIN dw.dim_proveedor pr ON pr.proveedor_key = f.proveedor_key
GROUP BY pr.es_mercaderia, pr.categoria_gasto
ORDER BY total DESC;


--P7. ¿Las categorías en las que más se gasta son las que más se venden?
WITH c AS (
  SELECT cat.nombre_categoria, SUM(f.total) AS compras
  FROM dw.fact_compras f
  JOIN dw.dim_producto_compra p ON p.producto_compra_key = f.producto_compra_key
  JOIN dw.dim_categoria cat     ON cat.categoria_key     = p.categoria_key
  WHERE cat.nombre_categoria <> 'No mercadería'
  GROUP BY cat.nombre_categoria
), v AS (
  SELECT cat.nombre_categoria, SUM(f.valor) AS ventas
  FROM dw.fact_ventas f
  JOIN dw.dim_producto_venta p ON p.producto_venta_key = f.producto_venta_key
  JOIN dw.dim_categoria cat    ON cat.categoria_key    = p.categoria_key
  GROUP BY cat.nombre_categoria
)
SELECT COALESCE(c.nombre_categoria, v.nombre_categoria) AS categoria,
       ROUND(100 * COALESCE(c.compras,0) / SUM(COALESCE(c.compras,0)) OVER (), 1) AS pct_compras,
       ROUND(100 * COALESCE(v.ventas,0)  / SUM(COALESCE(v.ventas,0))  OVER (), 1) AS pct_ventas
FROM c FULL JOIN v ON v.nombre_categoria = c.nombre_categoria
ORDER BY pct_compras DESC;

