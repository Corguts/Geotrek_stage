
-- () veut dire besoin ou pas necessairement de changer certaines choses sur la ligne

--VISUALISER L'ENSEMBLE DES ITINERAIRES VELOS
--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 


CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_Buffer(ct.geom, 1) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM core_topology ct
JOIN trekking_trek tt ON ct.id = tt.topo_object_id
WHERE ct.kind = 'TREK' 
  AND tt.name LIKE 'VTT %' -- () si besoin de spécifier un VTT en particulier mettre un espace est le numéro ou nom correspondant 
--  AND tt.name LIKE 'CYCLO %' -- () si seulement vtt ou cyclo, mettre deux tirets au début de la ligne inutile pour ne pas être fonctionnel
--à la place du pourcentage entre les simples guillemets, attention aux espaces. Il reconnaitra même si c'est du maj ou du min.
  AND ct.deleted = FALSE
  AND ct.id IS NOT NULL;

--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT ct.id 
FROM core_path ct
JOIN tmp_buffer_iti b ON ST_Contains(b.geom, ct.geom); -- () si besoin des tronçons exactes du ou des tracés sinon mettez deux tirets sur la ligne inutile
--JOIN tmp_buffer_iti b ON ST_INTERSECTS(b.geom, ct.geom); -- () si besoin de travailler autour en récupérant d'autres tronçons aux alentours bien changer la distance du buffer avant, enlever les deux tirets
DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec les GR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;





























/*

--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 

--prise du buffer autour des itinéraires souhaités
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geom, 50) AS geom -- () trop de tronçons donc mettre moins de distance de buffer ou un peu plus au risque de latence d'afichage
FROM geotrek.itineraires_apn_2023
WHERE cat = 'Cyclo' --récupère l'ensemble des itinéraires vélos

CREATE TABLE geotrek.id_visible_iti AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 

--Suppression de la table temporaire buffer 
DROP TABLE tmp_buffer_iti ; 


-- visualisation seulement des identifiants des tronçons en lien avec le GR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible_iti AS iti
WHERE core_path.id = iti.id;

DROP TABLE IF EXISTS geotrek.id_visible_iti;



--VISUALISER L'ENSEMBLE DES ITINERAIRES BOUCLES VTT

--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 

--prise du buffer autour des itinéraires souhaités
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geom, 50) AS geom -- () trop de tronçons donc mettre moins de distance de buffer ou un peu plus au risque de latence d'afichage
FROM geotrek.itineraires_apn_2023
WHERE type = 'Boucle VTT'; -- () ici il faut choisir qu'est ce qu'on a besoin, il faut mettre deux tirets avant les deux autres 'where' qu'on ne veut pas
--WHERE type = 'Véloroute';
--WHERE type = 'Boucle Cyclo Famille';

CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 

--Suppression de la table temporaire buffer 
DROP TABLE tmp_buffer_iti ; 


-- visualisation seulement des identifiants des tronçons en lien avec le GR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;
*/