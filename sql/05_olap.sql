-- =========================================================
-- 05_olap.sql  ·  Tienda Mariana  ·  Análisis OLAP
-- Operaciones: roll-up, drill-down, slice, dice, pivot, cubo y drill-across
-- =========================================================

-- ---------------------------------------------------------
-- 0. VISTAS "CUBO": unen cada hecho con sus dimensiones.
--    Excel y Power BI leen estas vistas como si fueran un cubo.
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW dw.v_cubo_compras AS
SELECT t.fecha, t.anio, t.trimestre, t.mes, t.nombre_mes, t.nombre_dia,
       pr.razon_social      AS proveedor,
       pr.es_mercaderia,
       pr.categoria_gasto,
       c.nombre_categoria   AS categoria,
       p.descripcion        AS producto,
       f.numero_factura,
       f.cantidad, f.subtotal, f.iva, f.total
FROM dw.fact_compras f
JOIN dw.dim_tiempo          t  ON t.tiempo_key          = f.tiempo_key
JOIN dw.dim_proveedor       pr ON pr.proveedor_key      = f.proveedor_key
JOIN dw.dim_producto_compra p  ON p.producto_compra_key = f.producto_compra_key
JOIN dw.dim_categoria       c  ON c.categoria_key       = p.categoria_key;

CREATE OR REPLACE VIEW dw.v_cubo_ventas AS
SELECT t.fecha, t.anio, t.mes, t.nombre_mes, t.dia_semana, t.nombre_dia, t.es_fin_semana,
       c.nombre_categoria AS categoria,
       p.nombre_producto  AS producto,
       f.cantidad, f.medida, f.valor
FROM dw.fact_ventas f
JOIN dw.dim_tiempo         t ON t.tiempo_key         = f.tiempo_key
JOIN dw.dim_producto_venta p ON p.producto_venta_key = f.producto_venta_key
JOIN dw.dim_categoria      c ON c.categoria_key      = p.categoria_key;


-- ---------------------------------------------------------
-- 1. ROLL-UP (subir en la jerarquía y resumir)
--    Mes -> Trimestre -> Año -> Total general.
--    ROLLUP agrega automáticamente las filas de subtotal (NULL = "todos").
-- ---------------------------------------------------------
SELECT CASE WHEN GROUPING(anio) = 1 THEN 'TOTAL GENERAL' ELSE anio::text END AS anio,
       CASE WHEN GROUPING(anio) = 1 THEN ''
            WHEN GROUPING(trimestre) = 1 THEN 'Total ' || anio
            ELSE 'T' || trimestre END                                        AS trimestre,
       CASE WHEN GROUPING(trimestre) = 1 THEN ''
            WHEN GROUPING(mes) = 1 THEN 'Subtotal T' || trimestre
            ELSE nombre_mes END                                              AS mes,
       SUM(total)                                                            AS compras
FROM dw.v_cubo_compras
GROUP BY ROLLUP (anio, trimestre, (mes, nombre_mes))
ORDER BY GROUPING(v_cubo_compras.anio), v_cubo_compras.anio,
         GROUPING(v_cubo_compras.trimestre), v_cubo_compras.trimestre,
         GROUPING(v_cubo_compras.mes), v_cubo_compras.mes;

-- Roll-up simple: de meses a años
SELECT anio, SUM(total) AS compras
FROM dw.v_cubo_compras
GROUP BY anio
ORDER BY anio;


-- ---------------------------------------------------------
-- 2. DRILL-DOWN (bajar en la jerarquía y ver más detalle)
--    Paso a: compras por año
--    Paso b: el año 2025 abierto por trimestre
--    Paso c: el trimestre 4 de 2025 abierto por mes
-- ---------------------------------------------------------
SELECT anio, SUM(total) AS compras
FROM dw.v_cubo_compras GROUP BY anio ORDER BY anio;                         -- a

SELECT anio, trimestre, SUM(total) AS compras
FROM dw.v_cubo_compras WHERE anio = 2025
GROUP BY anio, trimestre ORDER BY trimestre;                                -- b

SELECT anio, trimestre, mes, nombre_mes, SUM(total) AS compras
FROM dw.v_cubo_compras WHERE anio = 2025 AND trimestre = 4
GROUP BY anio, trimestre, mes, nombre_mes ORDER BY mes;                     -- c

-- Drill-down en producto: categoría "Bebidas" abierta por producto (ventas)
SELECT producto, SUM(valor) AS ventas, COUNT(*) AS veces_vendido
FROM dw.v_cubo_ventas WHERE categoria = 'Bebidas'
GROUP BY producto ORDER BY ventas DESC LIMIT 10;


-- ---------------------------------------------------------
-- 3. SLICE (fijar UN valor de UNA dimensión)
--    Rebanada: Año = 2025. Se ve compras por categoría solo de ese año.
-- ---------------------------------------------------------
SELECT categoria, SUM(total) AS compras_2025,
       ROUND(100 * SUM(total) / SUM(SUM(total)) OVER (), 1) AS pct
FROM dw.v_cubo_compras
WHERE anio = 2025                       -- <- el corte (slice)
GROUP BY categoria
ORDER BY compras_2025 DESC;

-- Slice en ventas: solo los fines de semana
SELECT categoria, SUM(valor) AS ventas_fin_semana
FROM dw.v_cubo_ventas
WHERE es_fin_semana = 'S'               -- <- el corte (slice)
GROUP BY categoria ORDER BY ventas_fin_semana DESC;


-- ---------------------------------------------------------
-- 4. DICE (elegir varios valores en DOS o más dimensiones = sub-cubo)
--    Tiempo: trimestre 4 de 2025 · Categoría: Bebidas y Snacks y dulces
--    · Proveedor: solo mercadería
-- ---------------------------------------------------------
SELECT nombre_mes, categoria, SUM(total) AS compras
FROM dw.v_cubo_compras
WHERE anio = 2025 AND trimestre = 4                          -- dimensión tiempo
  AND categoria IN ('Bebidas', 'Snacks y dulces')            -- dimensión categoría
  AND es_mercaderia = 'SI'                                   -- dimensión proveedor
GROUP BY mes, nombre_mes, categoria
ORDER BY mes, categoria;


-- ---------------------------------------------------------
-- 5. PIVOT (rotar: las filas pasan a columnas)
--    Filas = categoría, columnas = trimestres de 2025
-- ---------------------------------------------------------
SELECT categoria,
       SUM(total) FILTER (WHERE trimestre = 1) AS "T1_2025",
       SUM(total) FILTER (WHERE trimestre = 2) AS "T2_2025",
       SUM(total) FILTER (WHERE trimestre = 3) AS "T3_2025",
       SUM(total) FILTER (WHERE trimestre = 4) AS "T4_2025",
       SUM(total)                              AS total_2025
FROM dw.v_cubo_compras
WHERE anio = 2025
GROUP BY categoria
ORDER BY total_2025 DESC;

-- Pivot en ventas: filas = categoría, columnas = día de la semana
SELECT categoria,
       SUM(valor) FILTER (WHERE dia_semana = 1) AS lunes,
       SUM(valor) FILTER (WHERE dia_semana = 2) AS martes,
       SUM(valor) FILTER (WHERE dia_semana = 3) AS miercoles,
       SUM(valor) FILTER (WHERE dia_semana = 4) AS jueves,
       SUM(valor) FILTER (WHERE dia_semana = 5) AS viernes,
       SUM(valor) FILTER (WHERE dia_semana = 6) AS sabado,
       SUM(valor) FILTER (WHERE dia_semana = 7) AS domingo,
       SUM(valor) AS total
FROM dw.v_cubo_ventas
GROUP BY categoria
ORDER BY total DESC;


-- ---------------------------------------------------------
-- 6. CUBE (todas las combinaciones de subtotales)
--    Año x mercadería: total por año, por tipo y total general
-- ---------------------------------------------------------
SELECT COALESCE(anio::text, 'Todos los años')   AS anio,
       COALESCE(es_mercaderia, 'Todos')          AS es_mercaderia,
       SUM(total)                                AS compras
FROM dw.v_cubo_compras
GROUP BY CUBE (anio, es_mercaderia)
ORDER BY v_cubo_compras.anio NULLS LAST, v_cubo_compras.es_mercaderia NULLS LAST;


-- ---------------------------------------------------------
-- 7. DRILL-ACROSS (propio de la CONSTELACIÓN)
--    Cruza los dos hechos usando la dimensión compartida dim_categoria:
--    ¿en qué categorías se compra mucho y se vende poco?
--    (los hechos NO se unen entre sí: cada uno se agrupa por separado
--     y se juntan por la dimensión conformada)
-- ---------------------------------------------------------
WITH c AS (
  SELECT categoria, SUM(total) AS compras FROM dw.v_cubo_compras
  WHERE categoria <> 'No mercadería' GROUP BY categoria
), v AS (
  SELECT categoria, SUM(valor) AS ventas FROM dw.v_cubo_ventas GROUP BY categoria
)
SELECT COALESCE(c.categoria, v.categoria) AS categoria,
       COALESCE(c.compras, 0) AS compras,
       COALESCE(v.ventas, 0)  AS ventas,
       ROUND(100 * COALESCE(c.compras,0) / SUM(COALESCE(c.compras,0)) OVER (), 1) AS pct_compras,
       ROUND(100 * COALESCE(v.ventas,0)  / SUM(COALESCE(v.ventas,0))  OVER (), 1) AS pct_ventas
FROM c FULL JOIN v ON v.categoria = c.categoria
ORDER BY pct_compras DESC;
