-- Assurez vous d'utiliser ce script si vous avez déjà fait l'import du GPX sur le schéma geotrek avec le script gpx_to_sql
--ce script est pour voir les tronçons en lien ou proches des traces GPX
--remmetre invisible l'ensemble pour n'avoir par la suite seuelement les tronçons concernés
UPDATE core_path SET visible = 'false'; 


-- Créer une table temporaire pour stocker la géométrie fusionnée, transformée et bufferisée
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT 
    ST_Buffer(
        ST_Transform(
            (SELECT ST_Union(geometry) FROM geotrek.gr652), -- () ici sera inscrit le nom du gpx dans le schéma geotrek juste après le point et bien à l'intérieur de la parenthèse
            2154 -- Transformer la géométrie fusionnée en EPSG:2154
        ), 
        50 -- Appliquer un buffer de 50 unités en EPSG:2154 --() vous pouvez de choisir de prendre plus large pour récupérer plus de tronçons autour des traces GPX.
    ) AS geom;

--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 


DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec le GPX
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;


/*select *
FROM core_topology
where max_elevation = 0
AND kind = 'LANDEDGE';
*/