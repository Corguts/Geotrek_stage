--avertissement sur la quantité importante du pdipr qui peut impacter l'affichage sur Géotrek

--mettre tout invisible pour n'avoir que les tronçons souhaités
UPDATE core_path SET visible = 'false'; 

-- création d'un buffer de 1m autour des itinéraires, pour n'avoir que les tracés des GR
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_Buffer(ct.geom, 1) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM core_topology ct
JOIN land_landedge tt ON ct.id = tt.topo_object_id
WHERE ct.kind = 'LANDEDGE' -- où se trouve les PDIPR
--AND LOWER(tt.OWNER) LIKE '%grand cahors' -- () pouvant être changé pour la CC en question, bien mettre  en minuscule, entre les simples guillemets et après le pourcentage
  AND LOWER(tt.OWNER) LIKE '%calamane%' -- () pouvant être changé pour la commune en question, bien mettre en minuscule, entre les simples guillemets et entre les pourcentages
  AND ct.deleted = FALSE
;
-- ici mettre deux traits à la suite au début de la ligne du "AND" qui n'est pas utile pour ainsi ne pas fonctionner.


--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT ct.id
FROM core_path ct
JOIN tmp_buffer_iti b ON ST_Contains(b.geom, ct.geom); -- () si besoin des tronçons exactes du ou des tracés, sinon mettez deux tirets sur la ligne inutile
--JOIN tmp_buffer_iti b ON ST_INTERSECTS(b.geom, ct.geom); -- () si besoin de travailler autour en récupérant d'autres tronçons aux alentours bien changer la distance du buffer avant, enlever les deux tirets

DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec les GR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;

























-- création d'un buffer de 50m autour des itinéraires, pourquoi? Car les tracés ne sont superposés à la BD topo donc il faut récupérer tout autour
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geometry, 50) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser pas
FROM geotrek.pdipr;


--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 


DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec les GR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;


--VISUALISATION DU PDIPR SELON LES COMMUNAUTES DE COMMUNES 

UPDATE core_path SET visible = 'false'; 

-- création d'un buffer de 50m autour des itinéraires, pourquoi? Car les tracés ne sont superposés à la BD topo donc il faut récupérer tout autour
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geometry, 50) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser pas
FROM geotrek.pdipr
WHERE comcom = 'CAUVALDOR'; -- référencer en majuscule la communauté de commune souhaitée
--OR comcom = '' -- il est possible de rajouter plusieurs comcom en même temps, il faudra enlever les deux traits de début et de compléter entre les deux guillemets et le point-virgule sur la ligne au-dessus

--récupération des identifiants des tronçons sur Géotrek qui sont dans le buffer créé juste avant
CREATE TABLE geotrek.id_visible AS 
SELECT DISTINCT b.id 
FROM  
tmp_buffer_iti a 
LEFT JOIN public.core_path b ON ST_INTERSECTS (b.geom, a.geom); 


DROP TABLE IF EXISTS tmp_buffer_iti;

-- visualisation seulement des identifiants des tronçons en lien avec les GR
UPDATE core_path 
SET visible = 'true' 
FROM geotrek.id_visible AS c
WHERE core_path.id = c.id;

DROP TABLE IF EXISTS geotrek.id_visible;