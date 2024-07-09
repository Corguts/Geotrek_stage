--a regarder le mieux entre les deux script
--pour seulement l'intersection la plus proche
--script rapprochement à l'intersection la plus proche a une certaine distance,
DROP TABLE IF EXISTS geotrek.signage_intersection;

-- Créer la nouvelle table geotrek.signage_intersection
CREATE TABLE geotrek.signage_intersection AS
SELECT
    ROW_NUMBER() OVER () AS id,
    geom_path,
    CASE
        WHEN ST_Distance(geom_path, nearest_intersection) <= 50 THEN nearest_intersection
        ELSE geom_path
    END AS geom_topo,
    CASE
        WHEN ST_Distance(geom_path, nearest_intersection) <= 50 THEN ST_Distance(geom_path, nearest_intersection)
        ELSE 0
    END AS distance_topo
FROM (
    SELECT 
        sc.geom_path,
        ST_ClosestPoint(i.intersection_geom, sc.geom_path) AS nearest_intersection
    FROM
        geotrek.signage_iti21m sc
    LEFT JOIN LATERAL (
        SELECT 
            ST_Intersection(a.geom, b.geom) AS intersection_geom
        FROM
            public.core_path a
        JOIN
            public.core_path b ON ST_Intersects(a.geom, b.geom) AND a.id <> b.id
        WHERE
            ST_DWithin(sc.geom_path, a.geom, 200) -- Limite de recherche à 200m autour du point
        ORDER BY
            ST_Distance(sc.geom_path, ST_ClosestPoint(ST_Intersection(a.geom, b.geom), sc.geom_path)) -- Ordonner par distance
        LIMIT 1 -- Limiter à une seule intersection (la plus proche)
    ) AS i ON true
) AS subquery;


--le meilleur pour le moment
-- Supprimer la table existante si elle existe
DROP TABLE IF EXISTS geotrek.signage_intersection;

-- Créer la nouvelle table signage_intersection
CREATE TABLE geotrek.signage_intersection AS
SELECT
    ROW_NUMBER() OVER () AS id,
    geom_path,
    CASE
        WHEN ST_Distance(geom_path, nearest_point) <= 50 THEN nearest_point
        ELSE geom_path
    END AS geom_topo,
    CASE
        WHEN ST_Distance(geom_path, nearest_point) <= 50 THEN ST_Distance(geom_path, nearest_point)
        ELSE 0
    END AS distance_topo
FROM (
    SELECT DISTINCT ON (sc.geom_path)
        sc.geom_path,
        ST_ClosestPoint(tr.geom, sc.geom_path) AS nearest_point
    FROM
        geotrek.signage_iti21m sc
    LEFT JOIN
        public.core_path tr ON ST_DWithin(sc.geom_path, tr.geom, 50) -- Limite de recherche à 50m
) AS subquery;


--le meilleur pour le moment avec les intersections il faudrait seulerment un
-- Supprimer la table existante si elle existe
DROP TABLE IF EXISTS geotrek.signage_intersection;

-- Créer la nouvelle table geotrek.signage_intersection
CREATE TABLE geotrek.signage_intersection AS
SELECT
    ROW_NUMBER() OVER () AS id,
    geom_path,
    CASE
        WHEN ST_Distance(geom_path, nearest_intersection) <= 50 THEN nearest_intersection
        ELSE geom_path
    END AS geom_topo,
    CASE
        WHEN ST_Distance(geom_path, nearest_intersection) <= 50 THEN ST_Distance(geom_path, nearest_intersection)
        ELSE 0
    END AS distance_topo
FROM (
    SELECT 
        sc.geom_path,
        CASE 
            WHEN MIN(ST_DISTANCE(sc.geom_path, ST_ClosestPoint(i.intersection_geom, sc.geom_path))) <= 50 THEN
                ST_ClosestPoint(i.intersection_geom, sc.geom_path)
            ELSE
                sc.geom_path
        END AS nearest_intersection
    FROM
        geotrek.signage_iti21m sc
    LEFT JOIN LATERAL (
        SELECT 
            ST_Intersection(a.geom, b.geom) AS intersection_geom
        FROM
            public.core_path a
        JOIN
            public.core_path b ON ST_Intersects(a.geom, b.geom) AND a.id <> b.id
        WHERE
            ST_DWithin(sc.geom_path, a.geom, 200) -- Limite de recherche à 200m autour du point
    ) AS i ON true
    GROUP BY sc.geom_path, i.intersection_geom
) AS subquery;
