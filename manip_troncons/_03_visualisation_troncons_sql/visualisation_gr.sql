-- VISUALISER LES TRONCONS EN LIEN AVEC LES itinéraires

-- () veut dire besoin ou pas necessairement de changer certaines choses sur la ligne

--visualiser les GR sur Géotrek

--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 

-- création d'un buffer de 1m autour des itinéraires, pour n'avoir que les tracés des GR
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_Buffer(ct.geom, 1) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM core_topology ct
JOIN trekking_trek tt ON ct.id = tt.topo_object_id
WHERE ct.kind = 'TREK' 
  AND tt.name LIKE 'GR %' -- () si besoin de spécifier un GR en particulier mettre un espace est le numéro du GR à la place du pourcentage entre les simples guillemets
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
--visualiser les tronçons d'un GR en particulier


--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 


CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geometry, 50) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM geotrek.gr2023
WHERE nom_gr = '65' --() mettre le numéro du GR souhaité ici dans les trois lignes à la suite entre les simples guillemets
OR nom_gr_2 = '65' 
OR nom_gr_3 = '65';


--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 


DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec le GR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;
*/