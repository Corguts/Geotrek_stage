/*ce script permet de rapprocher les signalétiques sur les troncons, 
on créera une nouvelle table avec les id des troncons, les id signage,le geom de base des signaux
le geom du point le plus proche de chaque ligne pa rapport à chaque signalétique,ainsi que 
la distance entre le point de base et le nouveau. Pourquoi? car lors du buffer et st_within,
d'autres troncons sont sélectionnés donc d'autres nouveaux points aussi alors
 il faut prendre le plus court qui est déterminé selon le rank où dedans ce fait un classement
selon la distance dans l'ordre croissant que depuis les mêmes id de signalétique
le on st_intersect permet de mettre une distance maximale avec un buffer de 300,
 il y a 3 points sans geom et plusieurs à plus de 20m

*/
/*création du tableau de geom(2d), en mettant les points sur les troncons 
dans un rayon de 300m , en ajoutant la distance et un rang selon le plus près du point
 de base on pourra récupérer le 1 donc plus près */

 /*le select d'après va permettre de récupérer seulement les points pour chaque signalétique
 le plus près donc de rang 1 et evidemment avec un geom
*/
--voici le début pour la premiere table avec les itinéraires,réussi
DROP TABLE IF EXISTS geotrek.signage_iti21m;
CREATE TABLE geotrek.signage_iti21m AS
WITH merged_tr AS (
    SELECT geometry FROM (
        SELECT geometry FROM geotrek."GR2023"
        UNION
        SELECT geometry FROM geotrek."PE2023"  --fusion des 3 couches d'itinéraire pour pouvoir par la suite les points sur l'endroit le plus proche de lui
        UNION
        SELECT geometry FROM geotrek."PR2024"
    ) AS merged
),
merged_data AS (
    SELECT
        ROW_NUMBER() OVER () AS new_id,
        CASE --le case ici est pour changer ou non de geom selon la distance qu'on souhaite avec le closest point donc à moins ou égal , ici 10m tu changes le geom sinon tu mets celui de base
            WHEN ST_DISTANCE(sc.geometry, ST_ClosestPoint(mt.geometry, sc.geometry)) <= 21 THEN ST_ClosestPoint(mt.geometry, sc.geometry)
            ELSE sc.geometry
        END AS geom_path,
        ST_DISTANCE(sc.geometry, ST_ClosestPoint(mt.geometry, sc.geometry)) AS dist, --ici tu mets la distance du point de base et du point le plus proche depuis les itinéraires pour constater les distances qui les sépares 
        sc."N_Poteau",
        sc."date_clean",
        ROW_NUMBER () OVER (PARTITION BY sc.geometry ORDER BY ST_DISTANCE (sc.geometry,  ST_ClosestPoint(mt.geometry, sc.geometry))) as rank --le rank va permettre de récupérer la distance la plus proche car beaucoup de point vont se générer alors il faut le 1
    FROM
        geotrek.signaletique_collector sc
    CROSS JOIN
        merged_tr mt --on appelle le merge des couches  en les appelant mt
)
SELECT
    new_id,
    geom_path,
    dist,
    "N_Poteau",
    "date_clean",
    rank
FROM
    merged_data
WHERE
    rank = 1 AND geom_path IS NOT NULL
ORDER BY
    dist DESC;









--voici le script de départ de la meme facon que la bd topo.
DROP TABLE IF EXISTS geotrek.signage_300m;
CREATE TABLE geotrek.signage_300m AS

WITH a AS

(SELECT
    sc.id AS id_signaletique,
    tr.id AS id_troncon,
	sc.geom,
    ST_ClosestPoint(tr.geom, sc.geom) AS geom_path,
	ST_DISTANCE (sc.geom,  ST_ClosestPoint(tr.geom, sc.geom)) as dist,
    sc.n_poteau,
    sc.date_clean,
	ROW_NUMBER () OVER (PARTITION BY sc.id ORDER BY ST_DISTANCE (sc.geom,  ST_ClosestPoint(tr.geom, sc.geom)) ) as rank
FROM
    geotrek.signaletique_collector sc
LEFT JOIN
    public.core_path tr
ON ST_INTERSECTS (ST_BUFFER(sc.geom, 300), tr.geom))

SELECT *
FROM
a
WHERE 
rank = 1
AND geom IS NOT NULL
ORDER BY dist DESC


