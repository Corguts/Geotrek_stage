--script rapprochement à l'intersection la plus proche a une certaine distance,
DROP TABLE IF EXISTS geotrek.signage_intersection;

-- Créer la nouvelle table geotrek.signage_intersection
CREATE TABLE geotrek.signage_intersection AS
SELECT
    ROW_NUMBER() OVER () AS id,
    geometry,
    CASE
        WHEN ST_Distance(geometry, nearest_intersection) <= 16 THEN nearest_intersection
        ELSE geometry
    END AS geom_topo,
    CASE
        WHEN ST_Distance(geometry, nearest_intersection) <= 16 THEN ST_Distance(geometry, nearest_intersection)
        ELSE 0
    END AS distance_topo
FROM (
    SELECT 
        sc.geometry,
        ST_ClosestPoint(i.intersection_geom, sc.geometry) AS nearest_intersection
    FROM
        geotrek.signaletique_collector sc
    LEFT JOIN LATERAL (
        SELECT 
            ST_Intersection(a.geom, b.geom) AS intersection_geom
        FROM
            public.core_path a
        JOIN
            public.core_path b ON ST_Intersects(a.geom, b.geom) AND a.id <> b.id
        WHERE
            ST_DWithin(sc.geometry, a.geom, 200) -- Limite de recherche à 200m autour du point
        ORDER BY
            ST_Distance(sc.geometry, ST_ClosestPoint(ST_Intersection(a.geom, b.geom), sc.geometry)) -- Ordonner par distance
        LIMIT 1 -- Limiter à une seule intersection (la plus proche)
    ) AS i ON true
) AS subquery;






--ce script permet de récupérer tous les intersections de core_path (pas necessaire)
SELECT
    ST_Intersection(a.geom, b.geom) AS intersection_geom
FROM
    public.core_path a
JOIN
    public.core_path b ON ST_Intersects(a.geom, b.geom) AND a.id <> b.id;







