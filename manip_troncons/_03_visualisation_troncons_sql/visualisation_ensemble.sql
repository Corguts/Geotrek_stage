--Visualisation des tronçons liés aux tracés de core_topology par les liens du core_pathaggregation

-- Mettre à jour tous les tronçons comme non visibles
UPDATE core_path SET visible = 'false';

CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id
FROM 
    public.core_path b
    JOIN public.core_pathaggregation t ON b.id = t.path_id
WHERE t.topo_object_id IN (
    SELECT id
    FROM core_topology
    WHERE deleted = FALSE
);

-- Mettre à jour les tronçons en lien avec core_topology pour les rendre visibles
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS a
WHERE core_path.id = a.id;

-- Suppression de la table temporaire
DROP TABLE IF EXISTS geotrek.id_visible;






/*
--Avertissement ce script est juste pour la visalisation dans l'accueil, 
--ne pas l'utiliser lors de création ou de modification de tracés quelque soit la raison au risque de faire figer et faire ramer Géotrek 
--mais aussi, la couche reliée n'est pas complète comparé aux couches plus précises de chaque type d'itinéraire mais elle permet de visualiser l'ensemble

--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 

--prise du buffer autour des itinéraires souhaités
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geom, 10) AS geom --trop de tronçons donc mettre moins de distance de buffer ou un peu plus au risque de latence d'afichage
FROM geotrek.itineraires_apn_2023;


CREATE TABLE geotrek.id_visible_iti AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 

--Suppression de la table temporaire buffer 
DROP TABLE tmp_buffer_iti ; 


-- visualisation des troncons en lien aux itinéraires
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible_iti AS iti
WHERE core_path.id = iti.id;

DROP TABLE IF EXISTS geotrek.id_visible_iti;

*/
/*
-- Mise à jour initiale pour rendre tous les tronçons invisibles
UPDATE core_path SET visible = 'false'; 

-- Sélection des tronçons utilisés dans la table core_topology
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM 
    public.core_path b
    JOIN public.core_topology t ON ST_Intersects(b.geom, t.geom);

-- Visualisation des tronçons en lien aux itinéraires
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS a
WHERE core_path.id = a.id;

-- Suppression de la table temporaire
DROP TABLE IF EXISTS geotrek.id_visible;

*/