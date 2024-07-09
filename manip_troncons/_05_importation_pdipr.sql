
--supprimer les lignes pdipr, à faire dans l ordre actuel des delete
DELETE FROM land_landedge


-- Supprimer les lignes de core_path_aggregation qui n'ont pas de correspondance dans signage_signage, trekking_trek, et land_landedge et core_trail
--ne rien changer dessus au risque de tout casser!!!!
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


--supprimer les lignes de PDIPR sur core_topology
DELETE FROM core_topology
WHERE kind = 'LANDEDGE';




--Ajout d'un identifiant unique à tous les PDIPR , d'une nouvelle colonne avec l'id sur la table temporaire PDIPR
--ALTER TABLE geotrek.pdipr ADD COLUMN idpdipr varchar(14);
WITH a AS(
SELECT*, 
'T'||LPAD(tranche, 2, '0')||LEFT(date_delib, 4)||insee2||LPAD((ROW_NUMBER() OVER (partition BY tranche, LEFT(date_delib, 4), insee2))::varchar, 2, '0') newid
FROM
geotrek.pdipr)

UPDATE geotrek.pdipr b SET idpdipr = newid
FROM
a
WHERE 
a.objectid_1 = b.objectid_1

SELECT*
FROM
geotrek.pdipr




--création d'une table de préparation en divisant les pdipr en plusieurs morceaux pour récupérer les troncons de la table temporaire pdipr
DROP TABLE IF EXISTS geotrek.prepa_pdipr;
CREATE TABLE geotrek.prepa_pdipr AS 
WITH core_paths AS (
    SELECT 
        "idpdipr" as id_pdipr,       --"objectid_1" as id_pdipr,
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
    GROUP BY "idpdipr", a.nom_chemin, a.date_delib, a.nomcom, a.comcom, a.tranche, a.geometry
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
WHERE id_pdipr IS NOT NULL
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
FROM multi_line_strings
WHERE id_pdipr IS NOT NULL;

--insertion dans core_topology en faisant une union des id de core_path mais ce qui fait q'il n'y a plus élévation pour certains

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


--rajout de la colonne pour ensuite y mettre les id de topology généré par core_topology dans la table temporaire
ALTER TABLE geotrek.prepa_pdipr
ADD COLUMN topo_object_id integer;



--importation des id générés
UPDATE geotrek.prepa_pdipr AS p
SET topo_object_id = t.id
FROM core_topology AS t
WHERE ST_Within(p.geom, t.geom);





/*
--version utilisée qui marche
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
*/


--nouvelle version pour ajouter du texte juste avant les valeurs des colonnes
INSERT INTO land_landedge (land_type_id, topo_object_id, owner)
SELECT DISTINCT 
    14 AS land_type_id, -- land_type_id est toujours 14
    p.topo_object_id AS topo_object_id, -- on récupère l'id de core_topology
    CONCAT_WS(', ', 
        CONCAT('identifiant: ', p.id_pdipr),
        CONCAT('date de délibération: ', p.date_delib),
        CONCAT('tranche: ', p.tranche)
    ) AS owner -- concaténation des informations pour owner avec les préfixes
FROM core_topology t
JOIN geotrek.prepa_pdipr p ON t.id = p.topo_object_id
WHERE t.kind = 'LANDEDGE'
ON CONFLICT (topo_object_id) DO NOTHING;








--importation dans core_pathaggregation pour faire le lien des PDIPR avec les tronçons et l'ensemble des tracés par dessus eux
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


/*
--update pour rechanger la colonne owner en remplacant les valeurs déjà présentent dans la colonne owner
UPDATE land_landedge le
SET owner = CONCAT_WS(', ', 
    CONCAT('date de délibération: ', p.date_delib),
    CONCAT('tranche: ', p.tranche)
)
FROM geotrek.prepa_pdipr p
JOIN core_topology t ON t.id = p.topo_object_id
WHERE le.topo_object_id = p.topo_object_id
AND t.kind = 'LANDEDGE';
*/