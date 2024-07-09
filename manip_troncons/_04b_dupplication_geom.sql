--DUPPLICATION du geom sur core_topology pas le meme id topo mais meme geom
--pourquoi utiliser do$$ end$$, pour pouvoir faire appel aux fonctions
--l'appel d'une fonction s'écrit toujours :  SELECT * FROM ft_elevation_infos(original_geom, 1.0) INTO elevation; en changeant apres le from
--script réussi pour l'importation du meme geom d'un id de TREK donc d'itinéraire peut marcher en changeant juste les values en changeant TREK pour soit TRAIL ou LANDEDGE
DO $$
DECLARE
    original_geom geometry;
    new_id integer;
    elevation elevation_infos;
BEGIN
    -- Récupérer la géométrie de la ligne avec id 
    SELECT geom INTO original_geom FROM core_topology WHERE id = 28; --() changer le numéro d'id pour celui que l'on veut, il faudra donc une recherche pour celui souhaité sur core_topology

    -- Insérer une nouvelle ligne en dupliquant la géométrie de l'id 
    INSERT INTO core_topology (geom, kind)
    VALUES (original_geom, 'TREK') --() ici il faut changer selon où vous voulez le mettre dans geotrek: TREK (pour itinéraire) soit TRAIL(pour sentier) ou LANDEDGE(pour statut)
    RETURNING id INTO new_id;

    -- Appeler la fonction pour obtenir les informations d'élévation pour la nouvelle géométrie
    SELECT * FROM ft_elevation_infos(original_geom, 1.0) INTO elevation; -- ft_elevation_infos est la fonction sur Getrek qui permet de récupérer les infos du MNT

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
END $$;


--importation dans sentier:

INSERT INTO core_trail (name,topo_object_id,structure_id,category_id)
SELECT 
'test même geom sentier' AS name, --() mettre le nouveau nouveau au tracé duppliqué
sb.id AS topo_object_id, -- prendra la géométrie 
1 AS structure_id, --prendra à qui appartient cette donnée, c'est-à-dire l'ADT par son identifiant 1
3 -- () type d'itinéraire, ici c'est GR de core_trailcategory, autres choix possibles, bien mettre seulement le numéro:  1 labellisation   2 entretien régulier    3 GR    4 PR    5 PE    6 VTT
FROM core_topology sb
WHERE id = 17657; -- () aller récupérer l'identifiant généré sur core_topology lors de la dupplication de la géométrie en question


--importation dans itinéraire:
INSERT INTO trekking_trek (published,published_fr,published_en,name,name_fr,topo_object_id,structure_id,difficulty_id,practice_id,route_id,accessibility_level_id,reservation_system_id)
SELECT 
FALSE, --si on veut le rendre visible sur geotrek rando, on voit une étoile sur Géotrek qui indique s'il est, si besoin de publié, écrire 'TRUE'
FALSE, --si on veut le rendre visible sur geotrek rando pour la version française
FALSE, --si on veut le rendre visible sur geotrek rando pour la version anglaise
'test du même geom' AS name, -- () mettre le nom du nouvel itinéraire entre les guillemets simples
'test du même geom' AS name_fr, -- () mettre le même nom donné juste avant pour la mettre pour la version française
sa.id AS topo_object_id, --prendra l'id de la géométrie
1 AS structure_id, --prendra à qui appartient cette donnée ici l'ADT
3, -- () différents choix de difficulté: 1 très facile    2 facile    3 intermédiaire     4 difficile     5 très difficile
4, -- () différents choix de pratique: 1 VTT    2 Vélo     3 Cheval     4 Pédestre      5 Alpinisme     6 Trail     7 VTTAE
3, -- () différents choix de type d'itinéraire: 1 Boucle       2 Aller-retour      3 Traversée 
1, -- () différents choix de niveau d'accessibilité: 1 débutant     2 expérimenté
1 -- () le systeme de réservation qu'un seul pour le moment 1 OpenSystem  qui lui est dans la table common_reservationsystem
FROM core_topology sa
WHERE id = 17657; -- () aller récupérer l'identifiant généré sur core_topology lors de la dupplication de la géométrie en question


--importation dans core_pathaggregation pour faire le lien des tracés dupliqués et les tronçons ainsi que l'ensemble des tracés par dessus eux
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
        id = 38    -- () bien remettre l'identifiant généré sur core_topology pour le voir apparaître sur Géotrek
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