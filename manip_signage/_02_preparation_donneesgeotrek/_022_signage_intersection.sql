--script rapprochement des points selon les intersections et les lignes de BD topo le plus proche, réussi

DROP TABLE IF EXISTS geotrek.signage_intersection;

-- Créer la nouvelle table geotrek.signage_intersection
CREATE TABLE geotrek.signage_intersection AS
SELECT
    ROW_NUMBER() OVER () AS id,
    geometry,
	subquery."N_Poteau",
	subquery."date_clean",
    CASE
        WHEN ST_Distance(geometry, nearest_intersection) <= 10 THEN nearest_intersection
        WHEN ST_Distance(geometry, nearest_line_point) <= 20 THEN nearest_line_point
        ELSE geometry
    END AS geom_topo,
    CASE
        WHEN ST_Distance(geometry, nearest_intersection) <= 10 THEN ST_Distance(geometry, nearest_intersection)
        WHEN ST_Distance(geometry, nearest_line_point) <= 20 THEN ST_Distance(geometry, nearest_line_point)
        ELSE 0
    END AS distance_topo
FROM (
    SELECT
		sc."date_clean",
		sc."N_Poteau",
        sc.geometry,
        COALESCE(
            ST_ClosestPoint(i.intersection_geom, sc.geometry),
            ST_ClosestPoint(l.nearest_line_geom, sc.geometry)
        ) AS nearest_intersection,
        l.nearest_line_geom AS nearest_line_point
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
    LEFT JOIN LATERAL (
        SELECT 
            ST_ClosestPoint(a.geom, sc.geometry) AS nearest_line_geom
        FROM
            public.core_path a
        WHERE
            ST_DWithin(sc.geometry, a.geom, 20) -- Limite de recherche à 20m autour du point
        ORDER BY
            ST_Distance(sc.geometry, ST_ClosestPoint(a.geom, sc.geometry)) -- Ordonner par distance
        LIMIT 1 -- Limiter à un seul point sur la ligne (le plus proche)
    ) AS l ON true
) AS subquery;



--il faut ajouter  une nouvelle colonne qui servira a mettre les clés étrangères pour faire le lien entre signage300m et signage_signage ainsi que l'ajout d'information pour chaque signaletique
ALTER TABLE geotrek.signage_intersection
ADD COLUMN topo_object_id integer,
ADD COLUMN description text;
-- Ajouter une clé primaire sur la colonne id_signaletique
--ALTER TABLE geotrek.signage_intersection ADD PRIMARY KEY (id_signaletique);



--ajout des informations pour chaque signalétique
--toujours pas possible de mettre d'accent ni d'apostrophe
UPDATE geotrek.signage_intersection AS si
SET description = TRIM(CONCAT(
	CASE 
        WHEN COALESCE("Type_iti", '') <> '' THEN 'Type d_itineraire: ' || COALESCE("Type_iti", '') || ', '
        ELSE ''
    END,
    CASE 
        WHEN COALESCE("Proprietai", '') <> '' THEN 'Proprietaire: ' || COALESCE("Proprietai", '') || ', '
        ELSE ''
    END,
    CASE 
        WHEN COALESCE("FLECHE_pb", '') <> '' THEN 'FLECHE_pb: ' || COALESCE("FLECHE_pb", '') || ', '
        ELSE ''
    END,
    CASE 
        WHEN COALESCE("Type_herbe", '') <> '' THEN 'Type d_hebergement: ' || COALESCE("Type_herbe", '') || ', '
        ELSE ''
    END,
    CASE 
        WHEN LOWER("Tour_du_Lo") = 'x' THEN 'Tour du Lot, '
        WHEN COALESCE("Tour_du_Lo", '') <> '' THEN 'Tour du Lot: ' || "Tour_du_Lo" || ', '
        ELSE ''
    END,
    CASE 
        WHEN COALESCE("DateTerrai", '') <> ''  AND "DateTerrai" <> '1899-12-30' THEN 'Derniere fois sur place: ' || "DateTerrai" || ', '
        ELSE ''
    END,
    CASE 
        WHEN COALESCE("photo", '') <> '' THEN 'Derniere photo: ' || RIGHT("photo", 4) || ', '
        ELSE ''
    END,
    CASE 
        WHEN "abri" IS NOT NULL THEN 'abris, '
        WHEN "abri" ~* 'abri' OR COALESCE("FLECHE_1", "FLECHE_2", "FLECHE_3", "FLECHE_4", "FLECHE_5") ~* '(?<![a-zA-Z])abri' OR COALESCE("FLECHE_1", "FLECHE_2", "FLECHE_3", "FLECHE_4", "FLECHE_5") ~* 'cayrou' THEN 'abris, '
        ELSE ''
    END,
    CASE 
        WHEN "eau" IS NOT NULL THEN 'point d_eau, '
        WHEN "eau" ~* '\((eau)' OR "eau" ~* 'point\sd\Seau' OR COALESCE("FLECHE_1", "FLECHE_2", "FLECHE_3", "FLECHE_4", "FLECHE_5") ~* 'eau' THEN 'point d_eau, '
        ELSE ''
    END
))
FROM geotrek.signaletique_collector AS sc
WHERE si.geometry = sc.geometry;







/*



UPDATE geotrek.signage_intersection AS si
SET description = CONCAT(
    --'Type d_itinéraire: ', COALESCE("Type_iti", 'N/A'), ', ',
    'Type d_itinéraire: ', 
    CASE 
        WHEN LOWER("Type_iti") = 'x' THEN 'N/A'
        ELSE COALESCE("Type_iti", 'N/A')
    END,
    ', ',
    'Propiétaire: ', COALESCE("Proprietai", 'N/A'), ', ',
    'FLECHE_pb: ', COALESCE("FLECHE_pb", 'N/A'), ', ',
    'Type d_hébergement: ', COALESCE("Type_herbe", 'N/A'), ', ',
    'Tour du Lot: ', COALESCE("Tour_du_Lo", 'N/A'), ', ',
    'Date dernière sortie de terrain: ', COALESCE("DateTerrai", 'N/A'), ', ',
    'Date dernière photo: ', RIGHT(COALESCE("photo", 'N/A'), 4)
)
FROM geotrek.signaletique_collector AS sc
WHERE si.geometry = sc.geometry;
*/
/*
UPDATE geotrek.signage_intersection AS si
SET description = CONCAT(
    'Type d_itinéraire: ', 
    CASE 
        WHEN LOWER("Type_iti") = 'x' THEN 'N/A'
        ELSE COALESCE("Type_iti", 'N/A')
    END,
    ', ',
    'Propiétaire: ', COALESCE("Proprietai", 'N/A'), ', ',
    'FLECHE_pb: ', COALESCE("FLECHE_pb", 'N/A'), ', ',
    'Type d_hébergement: ', COALESCE("Type_herbe", 'N/A'), ', ',
    'Tour du Lot: ',
    CASE 
        WHEN LOWER("Tour_du_Lo") = 'x' THEN '16'
        ELSE COALESCE("Tour_du_Lo", 'N/A')
    END,
    ', ',
    'Date dernière fois sur place: ', COALESCE("DateTerrai", 'N/A'), ', ',
    'Année dernière photo: ', RIGHT(COALESCE("photo", 'N/A'), 4),
    ', ',
    'abris: ',
    CASE 
        WHEN "abri" IS NOT NULL THEN 'abris'
        WHEN "abri" ~* 'abri' OR COALESCE("FLECHE_1", "FLECHE_2", "FLECHE_3", "FLECHE_4", "FLECHE_5") ~* '(?<![a-zA-Z])abri' THEN '3'
        ELSE COALESCE("abri", 'N/A')
    END,
    ', ',
    'eau: ',
    CASE 
        WHEN "eau" IS NOT NULL THEN '4'
        WHEN "eau" ~* '\((eau)' OR "eau" ~* 'point\sd\Seau' OR COALESCE("FLECHE_1", "FLECHE_2", "FLECHE_3", "FLECHE_4", "FLECHE_5") ~* 'eau' THEN '4'
        ELSE COALESCE("eau", 'N/A')
    END
)
FROM geotrek.signaletique_collector AS sc
WHERE si.geometry = sc.geometry;




*/