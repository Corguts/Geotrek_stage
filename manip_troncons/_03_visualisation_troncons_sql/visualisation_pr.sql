-- VISUALISER LES TRONCONS EN LIEN AVEC LES PR

-- () veut dire besoin ou pas necessairement de changer certaines choses sur la ligne

--visualiser l'ensemble des PR sur Géotrek

UPDATE core_path SET visible = 'false'; 


CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_Buffer(ct.geom, 1) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM core_topology ct
JOIN trekking_trek tt ON ct.id = tt.topo_object_id
WHERE ct.kind = 'TREK' 
  AND tt.name LIKE 'PR %' -- () si besoin de spécifier un PR en particulier mettre le numéro ou nom correspondant juste à la suite en remplaçant le pourcentage
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



































--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 

-- création d'un buffer de 50m autour des itinéraires, pourquoi? Car les tracés ne sont superposés à la BD topo donc il faut récupérer tout autour
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geometry, 50) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM geotrek.pr2024 ; 


--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 


DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec le PR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;



--visualiser les tronçons d'un PR en particulier

--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 

-- création d'un buffer de 50m autour des itinéraires, pourquoi? Car les tracés ne sont superposés à la BD topo donc il faut récupérer tout autour
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geometry, 50) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM geotrek.pr2024
WHERE code_pr = 'PB04'; --() mettre le nom du PR souhaité ici entre les simples guillemets


--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 


DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec le PR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;