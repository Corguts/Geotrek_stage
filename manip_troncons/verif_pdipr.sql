--en enleveant les date_delib null, on arrive au total à 7209

SELECT COUNT(*) 
FROM geotrek.pdipr 
WHERE date_delib IS NOT NULL;

--constatation de ligne  à plus de 50% avec une autre 

--verification directement sur la couche pdipr
--résultat 425 lignes ayant à 40% une autre ligne sur elle
WITH pdipr_pairs AS (
    SELECT 
        a.idpdipr AS idpdipr_a, 
        b.idpdipr AS idpdipr_b,
        a.geometry AS geom_a,
        b.geometry AS geom_b,
        ST_Intersection(a.geometry, b.geometry) AS intersection_geom,
        ST_Length(ST_Intersection(a.geometry, b.geometry)) / ST_Length(a.geometry) AS overlap_percentage_a,
        ST_Length(ST_Intersection(a.geometry, b.geometry)) / ST_Length(b.geometry) AS overlap_percentage_b
    FROM 
        geotrek.pdipr a
    JOIN 
        geotrek.pdipr b
    ON 
        a.idpdipr < b.idpdipr
    WHERE 
        ST_Intersects(a.geometry, b.geometry)
)
SELECT 
    idpdipr_a, 
    idpdipr_b, 
    overlap_percentage_a, 
    overlap_percentage_b
FROM 
    pdipr_pairs
WHERE 
    overlap_percentage_a > 0.4 OR overlap_percentage_b > 0.4;


--verification sur core_topology avec Landedge où se trouve les PDIPR
--résultat 96 lignes ayant 40% pareil qu'une autre

WITH landedges AS (
    SELECT id, geom
    FROM core_topology
    WHERE kind = 'LANDEDGE'
),
intersecting_pairs AS (
    SELECT 
        a.id AS id1, 
        b.id AS id2, 
        ST_Intersection(a.geom, b.geom) AS intersection_geom,
        ST_Length(ST_Intersection(a.geom, b.geom)) / ST_Length(a.geom) AS overlap_percentage
    FROM 
        landedges a
    JOIN 
        landedges b 
    ON 
        ST_Intersects(a.geom, b.geom) AND a.id < b.id
),
significant_overlaps AS (
    SELECT id1, id2, overlap_percentage
    FROM intersecting_pairs
    WHERE overlap_percentage > 0.40
)
SELECT * FROM significant_overlaps;
