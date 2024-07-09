-- VISUALISER LES TRONCONS EN LIEN AVEC CHAQUE TYPE DE TRACES

-- () veut dire besoin ou pas necessairement de changer certaines choses sur la ligne

--visualiser l'ensemble des itinéraires sur Géotrek

--A chaque nouveau changement de visualisation des tronçons, remettre en invisible l'ensemble des tronçons pour éviter d'avoir d'autres tronçons restant
UPDATE core_path SET visible = 'false'; 

-- création d'un buffer de 50m autour des itinéraires, pourquoi? Car les tracés ne sont superposés à la BD topo donc il faut récupérer tout autour
CREATE TEMP TABLE tmp_buffer_iti AS 
SELECT ST_BUFFER(geom, 1) AS geom -- () si besoin de récupérer plus de tronçons aux alentours, changer seulement la distance sinon laisser
FROM core_topology
WHERE kind = 'TREK' --() à changer selon le module souhaité, "TREK" est pour itinéraire, "sentier" en mettant entre les simples guillemets TRAIL,autres: LANDEDGE statut foncier où il y a le PDIPR, PHYSICALEDGE pour le type de voie, etc...
AND deleted = FALSE 

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





