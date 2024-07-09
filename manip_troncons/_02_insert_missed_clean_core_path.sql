--on rajoute les troncons manquant dans le lot qui sont vers les limites du département car ceux de début sont ajoutés selon les communautés de commune

--vrai script de Gabriel où on insert par 10 000 en sachant qu'il faut pas mettre ceux deja present ainsi on arrive à tous les mettre
-- emprise du raster

DROP TABLE IF EXISTS geotrek.tmp_raster_bounds;
CREATE TABLE geotrek.tmp_raster_bounds AS
SELECT ST_SetSRID(ST_Extent(rast::geometry), 2154) as geom
FROM public.altimetry_dem;*/

-- import des tronçons manquants dans l'emprise
-- compartimenter cette requête en la lançant plusieurs fois (10000 lignes max)

WITH a AS
(SELECT
a.id,  
  CASE  
        WHEN nom_ban_g IS NOT NULL THEN nom_ban_g
        WHEN nom_coll_g IS NULL AND numero IS NOT NULL THEN numero
        ELSE NULL
    END AS name,
a.geom
FROM
geotrek.troncon_de_route_clean a
LEFT JOIN core_path b ON a.id = b.comments
LEFT JOIN geotrek.tmp_raster_bounds c ON ST_WITHIN (a.geom, c.geom)
WHERE b.id IS NULL)


INSERT INTO core_path (date_insert, valid, structure_id, source_id, draft, name, comments, geom)
SELECT  
    CURRENT_TIMESTAMP AS date_insert,
    ST_IsValid(geom) AS valid,
    1 AS structure_id,
    1 AS source_id,
    'false' AS draft,
   name ,
    id as comments,
    geom
      FROM
      a
      WHERE
       ST_Issimple(geom)='true'
      --LIMIT 10000
 ;
 
 --suppression des tronçons avec valeurs début ou fin hors rasters

DELETE FROM core_path
WHERE max_elevation <0 OR min_elevation <0;




-- Supprimer les enregistrements avec des géométries en doublon

DROP TABLE temp_duplicate_geometries;

CREATE TEMP TABLE temp_duplicate_geometries AS
SELECT 
    MIN(id) AS id
FROM 
    core_path
GROUP BY 
    geom
HAVING 
    COUNT(DISTINCT id) > 1;


DELETE FROM core_path
WHERE id IN (SELECT id FROM temp_duplicate_geometries);


-- Supprimer les enregistrements avec des géométries en doublon

CREATE TEMP TABLE temp_duplicate_geometries AS
SELECT 
    MIN(id) AS id
FROM 
    core_path
GROUP BY 
    geom
HAVING 
    COUNT(DISTINCT id) > 1;

DELETE FROM core_path
WHERE id IN (SELECT id FROM temp_duplicate_geometries);

DROP TABLE temp_duplicate_geometries;

--pourquoi le répéter? il existe un geom qui a trois fois le meme et je ne comprends pas pourquoi les deux doublons ne s'enlevent pas du premier coup donc je le refais une deuxieme fois





/*

--enlever les troncons sans valeurs
DELETE FROM public.core_path
WHERE min_elevation = -99999;

*/

/*
-- Requête pour vérifier s'il y a dans les geoms de 'core_path' ...
SELECT geom, COUNT(distinct id) as nb
FROM
core_path
GROUP BY geom
HAVING COUNT(distinct id)>1 limit 100;


...et des doublons dans la colonne 'comments'
SELECT comments, COUNT(distinct id) as nb
FROM
core_path
GROUP BY comments
HAVING COUNT(distinct id)>1 


--comment visualiser sur qgis aller sur le db manager ouvrir le schema de geotrek donc de la base de données qu'on veut , faire un select,
-- executer notre script dessus en appuyant sur gestionnaire db puis créer une couche 



-- Créer une table temporaire pour stocker les géométries en doublon
CREATE TEMP TABLE temp_duplicate_geometries AS
SELECT 
    MIN(id) AS id
FROM 
    core_path
GROUP BY 
    geom
HAVING 
    COUNT(DISTINCT id) > 1;


*/

















/*
--ce script ne marche pas  mais je garde
--pour éviter les perte de temps , on fait ca en deux parties une avec les codes de département 46

--supprimer la table précédente
DROP TABLE IF EXISTS geotrek.troncon_de_route_clipped;

-- Créer la table troncon_de_route_clipped
CREATE TABLE geotrek.troncon_de_route_clipped (
    id VARCHAR(255),
    nom_ban_g VARCHAR(255),
    nom_coll_g VARCHAR(255),
    numero VARCHAR(255),
    geom GEOMETRY(LineString, 2154) -- Assurez-vous de spécifier le type de géométrie et le SRID
);

-- Créer la table temporaire pour les limites du raster sans tampon
CREATE TEMP TABLE raster_bounds AS 
SELECT ST_SetSRID(ST_Extent(rast::geometry), 2154) AS raster_polygon
FROM public.altimetry_dem;

	
-- Créer la table temporaire et y insérer les géométries coupées
CREATE TEMP TABLE troncons_not_in_core_path AS
SELECT 
    t.id,
    t.nom_ban_g AS nom_ban_g,
    t.nom_coll_g AS nom_coll_g,
    t.numero AS numero,
    t.geom
FROM 
    geotrek.troncon_de_route_clean AS t
WHERE 
	(t.INSEECOM_G LIKE '46%' OR t.INSEECOM_G LIKE '12%' OR t.INSEECOM_G LIKE '82%') --si tout allait bien, il faut enlever le where pour tout mettre
    AND NOT EXISTS (
        SELECT 1
        FROM core_path AS c 
        WHERE c.comments = t.id
    );
	
	
CREATE TEMP TABLE temp_troncon_de_route_clipped AS 
WITH troncon_intermediate AS (
    SELECT 
        t.id,
        t.nom_ban_g,
        t.nom_coll_g,
        t.numero,
        ST_SetSRID((ST_Dump(ST_Intersection(t.geom, rb.raster_polygon))).geom, 2154) AS geom_dump
    FROM 
        troncons_not_in_core_path AS t
    INNER JOIN 
        raster_bounds AS rb ON ST_Intersects(t.geom, rb.raster_polygon)
)
SELECT
    ti.id,
    ti.nom_ban_g,
    ti.nom_coll_g,
    ti.numero,
    ti.geom_dump
FROM 
    troncon_intermediate AS ti
INNER JOIN 
    raster_bounds AS rb ON ST_Intersects(ti.geom_dump, rb.raster_polygon)
WHERE 
    NOT ST_Touches(ti.geom_dump, rb.raster_polygon);	
	
	
-- Insérer les géométries simples et valides dans troncon_de_route_clipped
INSERT INTO geotrek.troncon_de_route_clipped (id, nom_ban_g, nom_coll_g, numero, geom)
SELECT 
    id,
    nom_ban_g,
    nom_coll_g,
    numero,
    ST_MakeValid(ST_GeometryN(geom_dump, 1)) AS geom -- Réparer et s'assurer que ce sont des LineString
FROM 
    temp_troncon_de_route_clipped
WHERE 
    (ST_GeometryType(ST_MakeValid(geom_dump)) = 'ST_LineString' OR ST_GeometryType(ST_MakeValid(geom_dump)) = 'ST_MultiLineString')
    AND ST_IsValid(ST_MakeValid(geom_dump))
    AND ST_NumPoints(ST_MakeValid(geom_dump)) >= 2; -- Vérifier que les géométries sont valides et ont au moins 2 points

-- Supprimer la table temporaire
DROP TABLE temp_troncon_de_route_clipped;

DROP TABLE raster_bounds;

DROP TABLE troncons_not_in_core_path;

-- Mettre à jour les identifiants dans troncon_de_route_clipped
WITH numbered_troncons AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS rn -- Numéro de ligne pour les tronçons
    FROM 
        geotrek.troncon_de_route_clipped
)
UPDATE geotrek.troncon_de_route_clipped AS t
SET id = CASE 
            WHEN t.id = 'TRONROUT00001' THEN 'TRONROUT00001' -- Conserver l'identifiant existant
            ELSE CONCAT('TRONROUT', LPAD(rn::TEXT, 6, '0')) -- Générer un nouvel identifiant basé sur le numéro de ligne
         END
FROM numbered_troncons AS nt
WHERE t.id = nt.id;

CREATE TABLE geotrek.tmp_filtered_troncon_de_route AS 
SELECT  
    t.id AS comments,
    t.nom_ban_g AS nom_ban_g,
    t.nom_coll_g AS nom_coll_g,
    t.numero AS numero,
    t.geom AS geom 
FROM 
    geotrek.troncon_de_route_clipped AS t
WHERE ST_IsSimple(geom); -- Ajout de cette condition pour sélectionner les géométries simples

-- Étape 2: Insérer les données de la nouvelle table dans core_path
INSERT INTO core_path (date_insert, valid, structure_id, source_id, draft, name, comments, geom) 
SELECT  
    CURRENT_TIMESTAMP AS date_insert, 
    ST_IsValid(geom) AS valid, 
    1 AS structure_id, 
    1 AS source_id, 
    'false' AS draft, 
    CASE  
        WHEN nom_ban_g IS NOT NULL THEN nom_ban_g 
        WHEN nom_coll_g IS NULL AND numero IS NOT NULL THEN numero 
        ELSE NULL 
    END AS name, 
    comments, 
    geom
FROM 
    geotrek.tmp_filtered_troncon_de_route;

-- Supprimer la nouvelle table temporaire
DROP TABLE IF EXISTS geotrek.tmp_filtered_troncon_de_route;



*/





/*


-- Créer un polygone représentant les limites du raster
WITH raster_bounds AS (
    SELECT ST_Envelope(rast) AS raster_polygon
    FROM public.altimetry_dem
)
INSERT INTO geotrek.troncon_de_route_clipped (id,nom_ban_g,nom_coll_g,numero, geom)
SELECT t.id,
t.nom_ban_g AS nom_ban_g,
t.nom_coll_g AS nom_coll_g,
t.numero AS numero,
ST_ClipByBox2D(t.geom, raster_bounds.raster_polygon) AS geom
FROM geotrek.troncon_de_route_clean AS t, raster_bounds
WHERE ST_Intersects(t.geom, raster_bounds.raster_polygon);


ici c'est pour récupérer seulement les pixels du raster qui ont des valeurs et non pas en dessous  de 0
DROP TABLE IF EXISTS geotrek.table_raster;
CREATE TABLE geotrek.table_raster AS
SELECT
    ST_Value(rast, 1, 1) AS alit,
    (ST_DumpAsPolygons(rast)).*
FROM
    altimetry_dem
WHERE
    ST_Value(rast, 1, 1) >= 0
LIMIT 1000000

	union seulement ce que je veux
*/


/*
--script proposé en premieer par Gabriel
DROP TABLE IF EXISTS geotrek.tmp_raster_bounds_2;
CREATE TABLE geotrek.tmp_raster_bounds_2 AS 
SELECT   ST_SetSRID(ST_Extent(rast::geometry), 2154) AS polygon_geom
FROM altimetry_dem
WHERE ST_Width(rast) > 0 AND ST_Height(rast) > 0;

DROP TABLE IF EXISTS geotrek.tmp_raster_bounds;
CREATE TABLE geotrek.tmp_raster_bounds AS 
SELECT ST_SetSRID(ST_Extent(rast::geometry), 2154) as geom 
FROM public.altimetry_dem;

UPDATE geotrek.tmp_raster_bounds SET geom = ST_BUFFER(geom,0);

WITH a AS
(SELECT 
a.id,   
  CASE  
        WHEN nom_ban_g IS NOT NULL THEN nom_ban_g 
        WHEN nom_coll_g IS NULL AND numero IS NOT NULL THEN numero 
        ELSE NULL 
    END AS name, 
a.geom
FROM
geotrek.troncon_de_route_clean a
LEFT JOIN core_path b ON a.id = b.comments
LEFT JOIN geotrek.tmp_raster_bounds c ON ST_WITHIN (a.geom, c.geom)
WHERE b.id IS NULL)

INSERT INTO core_path (date_insert, valid, structure_id, source_id, draft, name, comments, geom) 
SELECT  
    CURRENT_TIMESTAMP AS date_insert, 
    ST_IsValid(geom) AS valid, 
    1 AS structure_id, 
    1 AS source_id, 
    'false' AS draft, 
   name ,
    id as comments, 
    geom
FROM 
 a
*/
--le probleme qui est rencontré est que le raster est carré est ne peut pas épouser le long du départmeent 
--sauf en faisant de spolygones de valeur du raster et de faire un where des valeurs au dessus de 0 dans notre cas il est impossible de mettre en polygone, trop long
-- sinon par la ensuite découper les troncons dès qu'il touche les bords du polygone lié au raster pour être le plus efficace possible
--si encore souci de troncon en dehors , juste supprimer les troncons de -99999
--ainsi que les troncons doublons donc même geom.

/*
--ce script a marché en 21minutes, impossible d ele verifier sur qgis trop lourd
DROP TABLE IF EXISTS geotrek.tmp_raster_polygons;

CREATE TABLE geotrek.tmp_raster_polygons AS
WITH pixel_polygons AS (
    SELECT ST_PixelAsPolygons(rast) AS pixel_polygon
    FROM altimetry_dem
    WHERE ST_Width(rast) > 0 AND ST_Height(rast) > 0
)
SELECT ST_SetSRID(pixel_polygon, 2154) AS polygon_geom
FROM pixel_polygons;


--script dure 55minutes, où je voulais faire une union partie par partie car trop long sinon ou erreur mais a la fin cela n'a pas marché mais l'idée de la structure est a gardé
DO $$
DECLARE
    chunk_size INTEGER := 10000;
    num_rows INTEGER;
    rec RECORD;
    aggregated_geom geometry := NULL;
    cur CURSOR FOR
        SELECT polygon_geom
        FROM geotrek.tmp_raster_polygons
        ORDER BY polygon_geom;
BEGIN
    -- Créer la table pour stocker les résultats intermédiaires
    DROP TABLE IF EXISTS geotrek.tmp_raster_bounds_intermediate;
    CREATE TABLE geotrek.tmp_raster_bounds_intermediate (polygon_geom geometry);

    -- Ouvrir le curseur
    OPEN cur;

    LOOP
        -- Réinitialiser l'agrégation pour le nouveau lot
        aggregated_geom := NULL;

        -- Boucle pour récupérer les lignes par morceaux
        FOR i IN 1..chunk_size LOOP
            FETCH cur INTO rec;
            EXIT WHEN NOT FOUND;

            -- Agréger les géométries
            IF aggregated_geom IS NULL THEN
                aggregated_geom := rec.polygon_geom;
            ELSE
                aggregated_geom := ST_Union(aggregated_geom, rec.polygon_geom);
            END IF;
        END LOOP;

        -- Insérer l'agrégation intermédiaire dans la table
        IF aggregated_geom IS NOT NULL THEN
            INSERT INTO geotrek.tmp_raster_bounds_intermediate (polygon_geom)
            VALUES (aggregated_geom);
        END IF;

        -- Vérifier si aucune ligne n'a été récupérée
        GET DIAGNOSTICS num_rows = ROW_COUNT;
        IF num_rows < chunk_size THEN
            EXIT;
        END IF;
    END LOOP;

    -- Fermer le curseur
    CLOSE cur;

    -- Agrégation finale des résultats intermédiaires
    DROP TABLE IF EXISTS geotrek.tmp_raster_bounds_2;
    CREATE TABLE geotrek.tmp_raster_bounds_2 AS
    SELECT ST_SetSRID(ST_Union(polygon_geom), 2154) AS polygon_geom
    FROM geotrek.tmp_raster_bounds_intermediate;

    -- Nettoyage de la table intermédiaire (optionnel)
    DROP TABLE IF EXISTS geotrek.tmp_raster_bounds_intermediate;
END $$;



--script du raster en carré prenant en compte aussi les valeur null
DROP TABLE IF EXISTS geotrek.tmp_raster_bounds;
CREATE TABLE geotrek.tmp_raster_bounds AS 
SELECT ST_SetSRID(ST_Extent(rast::geometry), 2154) as geom 
FROM public.altimetry_dem;


*/


/*
--ce script est pour enlever les troncons pas utiles dans core_path selon la date
DELETE FROM public.core_path
WHERE date_insert = '2024-05-15 09:02:49.561362+00';
*/
