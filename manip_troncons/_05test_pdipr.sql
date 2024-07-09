
--script réussi pour importer sur core_topology et importer dans land_landedge les informations
--supprimer ce qu'il y avait avant si des tests avant
DELETE FROM land_landedge;

--script pour la préparation à l'importation et faire le lien avec les tronçons de la BD topo

DROP TABLE IF EXISTS geotrek.prepa_pdipr;
CREATE TABLE geotrek.prepa_pdipr AS 
WITH core_paths AS (
    SELECT 
        a."objectid_1" AS id_pdipr, 
        a.nom_chemin,
        a.date_delib,
        a.nomcom,
        a.comcom,
        ARRAY_AGG(b.id) AS id_core_path,
        ST_LineMerge(ST_UNION(b.geom)) AS merged_geom,
        ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) AS length_core_path,
        ST_LENGTH(a.geometry) AS length_pdipr,
        (ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float AS dif_length
    FROM geotrek."pdipr" a
    LEFT JOIN core_path b ON ST_WITHIN(b.geom, ST_BUFFER(a.geometry, 15)) 
    WHERE b.id IS NOT NULL
    GROUP BY a."objectid_1", a.geometry, a.nom_chemin, a.date_delib, a.nomcom, a.comcom
    HAVING abs((ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float) < 0.05
),
line_strings AS (
    SELECT 
        cp.id_pdipr,
        ct.id AS topo_object_id,
        cp.nom_chemin,
        cp.date_delib,
        cp.nomcom,
        cp.comcom,
        cp.id_core_path,
        cp.merged_geom AS geom,
        cp.length_core_path,
        cp.length_pdipr,
        cp.dif_length
    FROM core_paths cp
    LEFT JOIN core_topology ct ON ST_Equals(cp.merged_geom, ct.geom)
    WHERE GeometryType(cp.merged_geom) = 'LINESTRING'
),
multi_line_strings AS (
    SELECT 
        cp.id_pdipr,
        ct.id AS topo_object_id,
        cp.nom_chemin,
        cp.date_delib,
        cp.nomcom,
        cp.comcom,
        cp.id_core_path,
        (ST_Dump(cp.merged_geom)).geom AS geom,
        cp.length_core_path,
        cp.length_pdipr,
        cp.dif_length
    FROM core_paths cp
    LEFT JOIN core_topology ct ON ST_Equals(cp.merged_geom, ct.geom)
    WHERE GeometryType(cp.merged_geom) = 'MULTILINESTRING'
)
SELECT * FROM line_strings
UNION ALL
SELECT * FROM multi_line_strings;




--peut etre a faire ca avant l'importation a voir
DO $$
DECLARE
    record RECORD;
    new_id integer;
    elevation elevation_infos;
BEGIN
    -- Boucle sur toutes les lignes de la table prepa_pdipr
    FOR record IN
        SELECT geom FROM geotrek.prepa_pdipr
    LOOP
        -- Insérer une nouvelle ligne en dupliquant la géométrie
        INSERT INTO core_topology (geom, kind)
        VALUES (record.geom, 'LANDEDGE')
        RETURNING id INTO new_id;

        -- Appeler la fonction pour obtenir les informations d'élévation pour la nouvelle géométrie
        SELECT * FROM ft_elevation_infos(record.geom, 1.0) INTO elevation;

        -- Mettre à jour la nouvelle ligne avec les informations retournées
        UPDATE core_topology
        SET geom_3d = elevation.draped,
            "length" = ST_3DLength(elevation.draped),
            slope = elevation.slope,
            min_elevation = elevation.min_elevation,
            max_elevation = elevation.max_elevation,
            ascent = elevation.positive_gain,
            descent = elevation.negative_gain
        WHERE id = new_id;
    END LOOP;
END $$;



--importation pour le lien avec statut_foncier
INSERT INTO land_landedge (land_type_id, topo_object_id, owner)
SELECT 
    14, -- land_type_id est toujours 14
    prepa_pdipr.topo_object_id AS topo_object_id, -- on récupère l'id de core_topology
    CONCAT_WS(', ', prepa_pdipr.nom_chemin, prepa_pdipr.date_delib, prepa_pdipr.nomcom, prepa_pdipr.comcom) AS owner -- concaténation des informations pour owner
FROM 
    geotrek.prepa_pdipr
	
/*
--script d'ajout seulement des tracés de core_topology sans infos
INSERT INTO land_landedge (land_type_id, topo_object_id)
SELECT 
    14, -- land_type_id est toujours 14
    core_topology.id AS topo_object_id -- on récupère l'id de core_topology
FROM 
    core_topology
WHERE 
    core_topology.kind = 'LANDEDGE' -- on filtre sur la valeur de kind
*/
/* script de départ pour seulement les geom dans core_topologie
DROP TABLE IF EXISTS geotrek.prepa_pdipr;
CREATE TABLE geotrek.prepa_pdipr AS 
WITH core_paths AS (
    SELECT 
        "objectid_1" as id_pdipr, 
        ARRAY_AGG(b.id) as id_core_path,
        ST_LineMerge(ST_UNION(b.geom)) as merged_geom,
        ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) as length_core_path,
        ST_LENGTH(a.geometry) as length_pdipr,
        (ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float as dif_length
    FROM geotrek."pdipr" a
    LEFT JOIN core_path b ON ST_WITHIN(b.geom, ST_BUFFER(a.geometry, 15)) 
    WHERE b.id IS NOT NULL
    GROUP BY "objectid_1", a.geometry
    HAVING abs((ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float) < 0.05
),
line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        merged_geom as geom,
        length_core_path,
        length_pdipr,
        dif_length
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'LINESTRING'
),
multi_line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        (ST_Dump(merged_geom)).geom as geom,
        length_core_path,
        length_pdipr,
        dif_length
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'MULTILINESTRING'
)
SELECT * FROM line_strings
UNION ALL
SELECT * FROM multi_line_strings;

DO $$
DECLARE
    record RECORD;
    new_id integer;
    elevation elevation_infos;
BEGIN
    -- Loop over all rows in the table prepa_pdipr
    FOR record IN
        SELECT geom FROM geotrek.prepa_pdipr
    LOOP
        -- Insert a new row by duplicating the geometry
        INSERT INTO core_topology (geom, kind)
        VALUES (record.geom, 'LANDEDGE')
        RETURNING id INTO new_id;

        -- Call the function to get elevation information for the new geometry
        SELECT * FROM ft_elevation_infos(record.geom, 1.0) INTO elevation;

        -- Update the new row with the returned information
        UPDATE core_topology
        SET geom_3d = elevation.draped,
            "length" = ST_3DLength(elevation.draped),
            slope = elevation.slope,
            min_elevation = elevation.min_elevation,
            max_elevation = elevation.max_elevation,
            ascent = elevation.positive_gain,
            descent = elevation.negative_gain
        WHERE id = new_id;
    END LOOP;
END $$;




*/







/* supprimer les lignes pdipr, à faire dans l'ordre actuel des delete
DELETE FROM core_pathaggregation
WHERE topo_object_id = 17628;

DELETE FROM land_landedge
Where topo_object_id = 17628;

DELETE FROM core_topology
WHERE kind = 'LANDEDGE';
*/

/*
SELECT DISTINCT ST_GEOMETRYTYPE(geom) as type, count(distinct id_pdipr)
FROM
geotrek.prepa_pdipr
GROUP BY type
*/



/*
--creation d'une table temporaire
DROP TABLE IF EXISTS geotrek.tmp_test_pdipr;
CREATE TABLE geotrek.tmp_test_pdipr AS 

SELECT 
"OBJECTID_1" as id_pdipr, 
ARRAY_AGG(b.id) as id_core_path,
ST_UNION(b.geom) as geom,
ST_LENGTH(ST_UNION(b.geom)) as length_core_path,
ST_LENGTH(geometry) as length_pdipr,
(ST_LENGTH(ST_UNION(b.geom))-ST_LENGTH(geometry))/ST_LENGTH(geometry)::float as dif_length
FROM geotrek."PDIPR" a
LEFT JOIN core_path b ON ST_WITHIN(b.geom, ST_BUFFER(a.geometry, 15)) 
WHERE
	b.id IS NOT NULL
GROUP BY id_pdipr, length_pdipr
HAVING
    abs((ST_LENGTH(ST_UNION(b.geom))-ST_LENGTH(geometry))/ST_LENGTH(geometry)::float) < 0.05;


--autre solution en cours
DROP TABLE IF EXISTS geotrek.matching_core_paths;
CREATE TABLE geotrek.matching_core_paths AS 
SELECT 
    a."objectid_1" AS id_pdipr, 
    ARRAY_AGG(b.id) AS id_core_path,
    ST_UNION(ST_Intersection(b.geom, ST_BUFFER(a.geometry, 10))) AS geom,
    SUM(ST_Length(ST_Intersection(b.geom, ST_BUFFER(a.geometry, 10)))) AS length_core_path,
    ST_Length(ST_UNION(a.geometry)) AS length_pdipr
FROM 
    geotrek."pdipr" a
JOIN 
    core_path b ON ST_DWithin(a.geometry, b.geom, 15)
GROUP BY 
    a."objectid_1"
HAVING 
    SUM(ST_Length(ST_Intersection(b.geom, ST_BUFFER(a.geometry, 10,'endcap=flat')))) / NULLIF(ST_Length(ST_UNION(a.geometry)), 0) > 0.6;
--	ABS(SUM(ST_Length(ST_Intersection(b.geom, ST_BUFFER(a.geometry, 10, 'endcap=flat')))) - ST_Length(ST_UNION(a.geometry))) > 0.6;
*/






/*
--importation en mettant l'ensemble manuellement sans trigger donc on va éviter de l'utiliser

--importation topology_pdipr qui marche soit 2500 sur les 7500
 INSERT INTO public.core_topology (geom,kind,offset)
 SELECT ST_FORCE2D(geom),
        ST_Force3D(geom) AS geom_3d,
        'LANDEDGE' AS kind,
        -5,
        ST_Length(geom) AS length
 FROM geotrek.tmp_test_pdipr
 LIMIT 3;


-- import de l'altitude dans min_elevation et max_elevation dans topology
UPDATE public.core_topology
SET min_elevation = (
        SELECT MIN(ST_Value(altimetry_dem.rast, points.geom))
        FROM public.altimetry_dem
        CROSS JOIN LATERAL ST_DumpPoints(core_topology.geom) AS points
        WHERE ST_Intersects(altimetry_dem.rast, core_topology.geom)
    ),
    max_elevation = (
        SELECT MAX(ST_Value(altimetry_dem.rast, points.geom))
        FROM public.altimetry_dem
        CROSS JOIN LATERAL ST_DumpPoints(core_topology.geom) AS points
        WHERE ST_Intersects(altimetry_dem.rast, core_topology.geom)
    ),
WHERE core_topology.id IN (17632,17633,17634);

*/

/*
--scipt réussi de la table des pdipr concordant avec la BD topo 

DROP TABLE IF EXISTS geotrek.prepa_pdipr;
CREATE TABLE geotrek.prepa_pdipr AS 

SELECT 
    "objectid_1" as id_pdipr, 
    ARRAY_AGG(b.id) as id_core_path,
    ST_LineMerge(ST_UNION(b.geom)) as geom,
    ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) as length_core_path,
    ST_LENGTH(geometry) as length_pdipr,
    (ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(geometry)) / ST_LENGTH(geometry)::float as dif_length
FROM geotrek."pdipr" a
LEFT JOIN core_path b ON ST_WITHIN(b.geom, ST_BUFFER(a.geometry, 15)) 
WHERE
    b.id IS NOT NULL
GROUP BY id_pdipr, length_pdipr
HAVING
    abs((ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(geometry)) / ST_LENGTH(geometry)::float) < 0.05;


--je pense que ceux qui ont une différence de 0 ont le slope ainsi que min et max car certains l'ont mais l'ensemble n'en ont pas

--script réussi de l'importation du shp.pdipr à core_topology avecla fonction pour récupérer du raster
DO $$
DECLARE
    record RECORD;
    new_id integer;
    elevation elevation_infos;
BEGIN
    -- Boucle sur toutes les lignes de la table prepa_pdipr
    FOR record IN
        SELECT geom FROM geotrek.prepa_pdipr
    LOOP
        -- Insérer une nouvelle ligne en dupliquant la géométrie
        INSERT INTO core_topology (geom, kind)
        VALUES (record.geom, 'LANDEDGE')
        RETURNING id INTO new_id;

        -- Appeler la fonction pour obtenir les informations d'élévation pour la nouvelle géométrie
        SELECT * FROM ft_elevation_infos(record.geom, 1.0) INTO elevation;

        -- Mettre à jour la nouvelle ligne avec les informations retournées
        UPDATE core_topology
        SET geom_3d = elevation.draped,
            "length" = ST_3DLength(elevation.draped),
            slope = elevation.slope,
            min_elevation = elevation.min_elevation,
            max_elevation = elevation.max_elevation,
            ascent = elevation.positive_gain,
            descent = elevation.negative_gain
        WHERE id = new_id;
    END LOOP;
END $$;


*/

--en cours


DROP TABLE IF EXISTS geotrek.prepa_pdipr;
CREATE TABLE geotrek.prepa_pdipr AS 
WITH core_paths AS (
    SELECT 
        "objectid_1" as id_pdipr,
		a.nom_chemin,
        a.date_delib,
        a.nomcom,
        a.comcom,
        ARRAY_AGG(b.id) as id_core_path,
        ST_LineMerge(ST_UNION(b.geom)) as merged_geom,
        ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) as length_core_path,
        ST_LENGTH(a.geometry) as length_pdipr,
        (ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float as dif_length
    FROM geotrek."pdipr" a
    LEFT JOIN core_path b ON ST_WITHIN(b.geom, ST_BUFFER(a.geometry, 15)) 
    WHERE b.id IS NOT NULL
    GROUP BY "objectid_1", a.nom_chemin, a.date_delib, a.nomcom, a.comcom, a.geometry
    HAVING abs((ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float) < 0.05
),
line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        merged_geom as geom,
        length_core_path,
        length_pdipr,
        dif_length,
        nom_chemin,
        date_delib,
        nomcom,
        comcom
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'LINESTRING'
),
multi_line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        (ST_Dump(merged_geom)).geom as geom,
        length_core_path,
        length_pdipr,
        dif_length,
        nom_chemin,
        date_delib,
        nomcom,
        comcom
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'MULTILINESTRING'
)
SELECT * FROM line_strings
UNION ALL
SELECT * FROM multi_line_strings;








--supprimer rapidement
DELETE FROM core_topology
WHERE date_insert = '2024-06-05 12:24:43.658496+00';

--plusiuers insertion



-- Insérer les géométries dans core_topology
INSERT INTO core_topology (geom, kind)
SELECT 
    ST_UNION(b.geom),
    'LANDEDGE'
FROM geotrek.prepa_pdipr AS p
JOIN core_path AS b ON b.id = ANY(p.id_core_path)
GROUP BY p.id_pdipr;

-- Appeler la fonction pour obtenir les informations d'élévation pour chaque nouvelle géométrie
DO $$
DECLARE
    new_id INTEGER;
    elevation RECORD;
BEGIN
    FOR new_id IN (SELECT id FROM core_topology WHERE geom_3d IS NULL) LOOP
        SELECT * FROM ft_elevation_infos((SELECT geom FROM core_topology WHERE id = new_id), 1.0) INTO elevation;
        
        -- Mettre à jour la nouvelle ligne avec les informations retournées
        UPDATE core_topology
        SET 
            geom_3d = elevation.draped,
            "length" = ST_3DLength(elevation.draped),
            slope = elevation.slope,
            min_elevation = elevation.min_elevation,
            max_elevation = elevation.max_elevation,
            ascent = elevation.positive_gain,
            descent = elevation.negative_gain
        WHERE id = new_id;
    END LOOP;
END $$;












-- Mettre à jour la colonne topo_object_id avec les valeurs appropriées de core_topology
UPDATE geotrek.prepa_pdipr AS p
SET topo_object_id = sub.ids
FROM (
    SELECT 
        p.id_pdipr,
		
        ARRAY_AGG(t.id) AS ids
    FROM geotrek.prepa_pdipr p
    JOIN core_topology t ON ST_Within(p.geom, t.geom) AND t.kind = 'LANDEDGE'
    GROUP BY p.id_pdipr
) AS sub
WHERE p.id_pdipr = sub.id_pdipr;



-- Sélectionner les enregistrements avec des doublons dans topo_object_id
SELECT id_pdipr, topo_object_id
FROM (
    SELECT id_pdipr, topo_object_id,
           COUNT(*) AS num_elements,
           COUNT(DISTINCT element) AS num_distinct_elements
    FROM (
        SELECT id_pdipr, topo_object_id, unnest(topo_object_id) AS element
        FROM geotrek.prepa_pdipr
    ) AS unnested
    GROUP BY id_pdipr, topo_object_id
) AS grouped
WHERE num_elements > num_distinct_elements;





--vrai script
--création de d'une table de préparation en divisant les pdipr en plusieurs morceaux pour récupérer les troncons
DROP TABLE IF EXISTS geotrek.prepa_pdipr;
CREATE TABLE geotrek.prepa_pdipr AS 
WITH core_paths AS (
    SELECT 
        "objectid_1" as id_pdipr,
		a.nom_chemin,
        a.date_delib,
        a.nomcom,
        a.comcom,
        ARRAY_AGG(b.id) as id_core_path,
        ST_LineMerge(ST_UNION(b.geom)) as merged_geom,
        ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) as length_core_path,
        ST_LENGTH(a.geometry) as length_pdipr,
        (ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float as dif_length
    FROM geotrek."pdipr" a
    LEFT JOIN core_path b ON ST_WITHIN(b.geom, ST_BUFFER(a.geometry, 15)) 
    WHERE b.id IS NOT NULL
    GROUP BY "objectid_1", a.nom_chemin, a.date_delib, a.nomcom, a.comcom, a.geometry
    HAVING abs((ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float) < 0.05
),
line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        merged_geom as geom,
        length_core_path,
        length_pdipr,
        dif_length,
        nom_chemin,
        date_delib,
        nomcom,
        comcom
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'LINESTRING'
),
multi_line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        (ST_Dump(merged_geom)).geom as geom,
        length_core_path,
        length_pdipr,
        dif_length,
        nom_chemin,
        date_delib,
        nomcom,
        comcom
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'MULTILINESTRING'
)
SELECT * FROM line_strings
UNION ALL
SELECT * FROM multi_line_strings;

--insertion dans core_topology en faisant une union des id de core_path mais ce qui fait q'il n'y a plus 
--de min/max elevation pour ceux qui ont plusieurs branches(avoir si c'est bon ou enlever l'union)
DO $$
DECLARE
    original_geom geometry;
    new_id integer;
    elevation elevation_infos;
    rec RECORD;
BEGIN
    -- Ouvrir un curseur pour l'instruction SELECT
    FOR rec IN
        SELECT 
            ST_UNION(b.geom) AS geom,
            'LANDEDGE' AS kind
        FROM geotrek.prepa_pdipr AS p
        JOIN core_path AS b ON b.id = ANY(p.id_core_path)
        GROUP BY p.id_pdipr
    LOOP
        -- Insérer la ligne et récupérer l'id et la géométrie insérée
        INSERT INTO core_topology (geom, kind)
        VALUES (rec.geom, rec.kind)
        RETURNING id, geom INTO new_id, original_geom;

        -- Appeler la fonction pour obtenir les informations d'élévation pour la nouvelle géométrie
        SELECT * FROM ft_elevation_infos(original_geom, 1.0) INTO elevation;

        -- Mettre à jour la nouvelle ligne avec les informations retournées
        UPDATE core_topology
        SET geom_3d = elevation.draped,
            "length" = ST_3DLength(elevation.draped),
            slope = elevation.slope,
            min_elevation = elevation.min_elevation,
            max_elevation = elevation.max_elevation,
            ascent = elevation.positive_gain,
            descent = elevation.negative_gain
        WHERE id = new_id;
    END LOOP;
END $$;

ALTER TABLE geotrek.prepa_pdipr
ADD COLUMN topo_object_id integer;

UPDATE geotrek.prepa_pdipr AS p
SET topo_object_id = t.id
FROM core_topology AS t
WHERE ST_Within(p.geom, t.geom);


--insertion par distinct de topo_object_id dans l'idée de n'avoir qu'un seul id car prepa_pdipr est morcelé et que j'ai fait une union
INSERT INTO land_landedge (land_type_id, topo_object_id, owner)
SELECT DISTINCT 
    14 AS land_type_id, -- land_type_id est toujours 14
    p.topo_object_id AS topo_object_id, -- on récupère l'id de core_topology
    CONCAT_WS(', ', p.date_delib,p.tranche) AS owner -- concaténation des informations pour owner
FROM core_topology t
JOIN geotrek.prepa_pdipr p ON t.id = p.topo_object_id
WHERE t.kind = 'LANDEDGE'
ON CONFLICT (topo_object_id) DO NOTHING;



--recent:

-- Supprimer les lignes de core_path_aggregation qui n'ont pas de correspondance dans signage_signage, trekking_trek, et land_landedge
DELETE FROM core_pathaggregation
WHERE topo_object_id NOT IN (
    SELECT topo_object_id FROM signage_signage
)
AND topo_object_id NOT IN (
    SELECT topo_object_id FROM trekking_trek
)
AND topo_object_id NOT IN (
    SELECT topo_object_id FROM land_landedge
)
AND topo_object_id NOT IN (
    SELECT topo_object_id FROM core_trail
);


supprimer les lignes pdipr, à faire dans l'ordre actuel des delete
DELETE FROM land_landedge

DELETE FROM core_pathaggregation
WHERE topo_object_id = 17628;

DELETE FROM land_landedge
Where topo_object_id = 17628;

DELETE FROM core_topology
WHERE kind = 'LANDEDGE';


--création d'une table de préparation en divisant les pdipr en plusieurs morceaux pour récupérer les troncons
DROP TABLE IF EXISTS geotrek.prepa_pdipr;
CREATE TABLE geotrek.prepa_pdipr AS 
WITH core_paths AS (
    SELECT 
        "objectid_1" as id_pdipr,
        a.nom_chemin,
        a.date_delib,
        a.nomcom,
        a.comcom,
        a.tranche,
        ARRAY_AGG(b.id) as id_core_path,
        ST_LineMerge(ST_UNION(b.geom)) as merged_geom,
        ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) as length_core_path,
        ST_LENGTH(a.geometry) as length_pdipr,
        (ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float as dif_length
    FROM geotrek."pdipr" a
    LEFT JOIN core_path b ON ST_WITHIN(b.geom, ST_BUFFER(a.geometry, 15)) 
    WHERE b.id IS NOT NULL
    GROUP BY "objectid_1", a.nom_chemin, a.date_delib, a.nomcom, a.comcom, a.tranche, a.geometry
    HAVING abs((ST_LENGTH(ST_LineMerge(ST_UNION(b.geom))) - ST_LENGTH(a.geometry)) / ST_LENGTH(a.geometry)::float) < 0.05
),
line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        merged_geom as geom,
        length_core_path,
        length_pdipr,
        dif_length,
        nom_chemin,
        date_delib,
        nomcom,
        comcom,
        tranche
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'LINESTRING'
),
multi_line_strings AS (
    SELECT 
        id_pdipr,
        id_core_path,
        (ST_Dump(merged_geom)).geom as geom,
        length_core_path,
        length_pdipr,
        dif_length,
        nom_chemin,
        date_delib,
        nomcom,
        comcom,
        tranche
    FROM core_paths
    WHERE GeometryType(merged_geom) = 'MULTILINESTRING'
)
SELECT 
    id_pdipr,
    id_core_path,
    geom,
    length_core_path,
    length_pdipr,
    dif_length,
    nom_chemin,
    date_delib,
    nomcom,
    comcom,
    tranche
FROM line_strings
UNION ALL
SELECT 
    id_pdipr,
    id_core_path,
    geom,
    length_core_path,
    length_pdipr,
    dif_length,
    nom_chemin,
    date_delib,
    nomcom,
    comcom,
    tranche
FROM multi_line_strings;

--insertion dans core_topology en faisant une union des id de core_path mais ce qui fait q'il n'y a plus 
--de min/max elevation pour ceux qui ont plusieurs branches(avoir si c'est bon ou enlever l'union)
DO $$
DECLARE
    original_geom geometry;
    new_id integer;
    elevation elevation_infos;
    rec RECORD;
BEGIN
    -- Ouvrir un curseur pour l'instruction SELECT
    FOR rec IN
        SELECT 
            ST_UNION(b.geom) AS geom,
            'LANDEDGE' AS kind
        FROM geotrek.prepa_pdipr AS p
        JOIN core_path AS b ON b.id = ANY(p.id_core_path)
        GROUP BY p.id_pdipr
    LOOP
        -- Insérer la ligne et récupérer l'id et la géométrie insérée
        INSERT INTO core_topology (geom, kind)
        VALUES (rec.geom, rec.kind)
        RETURNING id, geom INTO new_id, original_geom;

        -- Appeler la fonction pour obtenir les informations d'élévation pour la nouvelle géométrie
        SELECT * FROM ft_elevation_infos(original_geom, 1.0) INTO elevation;

        -- Mettre à jour la nouvelle ligne avec les informations retournées
        UPDATE core_topology
        SET geom_3d = elevation.draped,
            "length" = ST_3DLength(elevation.draped),
            slope = elevation.slope,
            min_elevation = elevation.min_elevation,
            max_elevation = elevation.max_elevation,
            ascent = elevation.positive_gain,
            descent = elevation.negative_gain
        WHERE id = new_id;
    END LOOP;
END $$;

ALTER TABLE geotrek.prepa_pdipr
ADD COLUMN topo_object_id integer;

UPDATE geotrek.prepa_pdipr AS p
SET topo_object_id = t.id
FROM core_topology AS t
WHERE ST_Within(p.geom, t.geom);


--insertion par distinct de topo_object_id dans l'idée de n'avoir qu'un seul id car prepa_pdipr est morcelé et que j'ai fait une union
INSERT INTO land_landedge (land_type_id, topo_object_id, owner)
SELECT DISTINCT 
    14 AS land_type_id, -- land_type_id est toujours 14
    p.topo_object_id AS topo_object_id, -- on récupère l'id de core_topology
    CONCAT_WS(', ', p.date_delib,p.tranche) AS owner -- concaténation des informations pour owner
FROM core_topology t
JOIN geotrek.prepa_pdipr p ON t.id = p.topo_object_id
WHERE t.kind = 'LANDEDGE'
ON CONFLICT (topo_object_id) DO NOTHING;


WITH intersecting_paths AS (
    SELECT 
        p.*,
        t.id AS topo_id
    FROM 
        public.core_path AS p
    JOIN 
        public.core_topology AS t ON ST_Intersects(p.geom, ST_Buffer(t.geom, 1))--je fais un buffer car les points ne sont pas reconnu,ne s'intersecte pas alors qu'ils sont bien dessus
    WHERE 
        t.kind = 'LANDEDGE'
),
insert_data AS (
    INSERT INTO public.core_pathaggregation ("order", path_id, topo_object_id, start_position, end_position)
    SELECT 
        0 AS "order",--ici c'est l'odre ,comme c'est un point c'est 0 , si c'était unitinéraire alors ca aurait indiquer à tous les points l'ordre logique pour arriver au point d'arrivé
        p.id AS path_id,
        ip.topo_id AS topo_object_id,
        ST_LineLocatePoint(p.geom, t.geom) AS start_position,
        ST_LineLocatePoint(p.geom, t.geom) AS end_position
    FROM 
        intersecting_paths AS ip
        INNER JOIN core_path AS p ON ip.id = p.id
        INNER JOIN core_topology AS t ON ip.topo_id = t.id 
    RETURNING *
)
SELECT * FROM insert_data;


WITH intersecting_paths AS (
    SELECT 
        p.*,
        t.id AS topo_id,
        t.geom AS topo_geom,
        ST_Intersection(p.geom, ST_Buffer(t.geom, 1)) AS intersect_geom -- Intersection des géométries
    FROM 
        public.core_path AS p
    JOIN 
        public.core_topology AS t ON ST_Intersects(p.geom, ST_Buffer(t.geom, 1)) -- Buffer pour gérer les intersections
    WHERE 
        t.kind = 'LANDEDGE'
),
valid_intersections AS (
    SELECT 
        ip.*,
        ST_StartPoint(ip.intersect_geom) AS start_point,
        ST_EndPoint(ip.intersect_geom) AS end_point
    FROM 
        intersecting_paths AS ip
    WHERE 
        ST_GeometryType(ip.intersect_geom) IN ('ST_LineString', 'ST_MultiLineString')
        AND ST_Length(ip.intersect_geom) > 0
),
insert_data AS (
    INSERT INTO public.core_pathaggregation ("order", path_id, topo_object_id, start_position, end_position)
    SELECT 
        row_number() OVER (PARTITION BY vi.topo_id ORDER BY ST_LineLocatePoint(vi.geom, vi.start_point)) - 1 AS "order", -- Calcul de l'ordre pour les lignes
        vi.id AS path_id,
        vi.topo_id AS topo_object_id,
        ST_LineLocatePoint(vi.geom, vi.start_point) AS start_position, -- Position de début
        ST_LineLocatePoint(vi.geom, vi.end_point) AS end_position -- Position de fin
    FROM 
        valid_intersections AS vi
    WHERE 
        vi.start_point IS NOT NULL AND vi.end_point IS NOT NULL
    RETURNING *
)
SELECT * FROM insert_data;




