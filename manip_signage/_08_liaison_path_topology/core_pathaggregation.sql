
/*La fonction ST_LineLocatePoint prend deux géométries en entrée : une géométrie de ligne (dans ce cas, p.geom de la table core_path) 
et une géométrie de point (dans ce cas, t.geom de la table core_topology). 
Elle renvoie la position du point sur la ligne sous forme de fraction, où 0 représente le début de la ligne et 1 représente la fin de la ligne.*/

--script d'importation localisation path_aggregation, réussi 

WITH intersecting_paths AS (
    SELECT 
        p.*,
        t.id AS topo_id
    FROM 
        public.core_path AS p
    JOIN 
        public.core_topology AS t ON ST_Intersects(p.geom, ST_Buffer(t.geom, 1))--je fais un buffer car les points ne sont pas reconnu,ne s'intersecte pas alors qu'ils sont bien dessus
    WHERE 
        t.id > 48
        AND ST_GeometryType(t.geom) = 'ST_Point'--j'ai besoin de spécifier seulement les points
        -- si c'est bon enlever le AND et les id et garder seulement st_geometrypoint
),
insert_data AS (
    INSERT INTO public.core_pathaggregation ("order", path_id, topo_object_id, start_position, end_position)
    SELECT 
        0 AS "order",--ici c'est l'odre ,comme c'est un point c'est 0 , si c'était unitinéraire alors ca aurait indiquer à tous les points l'ordre logique pour arriver au point d'arrivé
        p.id AS path_id,
        ip.topo_id AS topo_object_id,
        ST_LineLocatePoint(p.geom, t.geom) AS start_position,
        ST_LineLocatePoint(p.geom, t.geom) AS end_position
    FROM 
        intersecting_paths AS ip
        INNER JOIN core_path AS p ON ip.id = p.id
        INNER JOIN core_topology AS t ON ip.topo_id = t.id 
    RETURNING *
)
SELECT * FROM insert_data;


--start et end position vont permettre de savoir le chemin suivi avec la localisation des points avec  oui ou non un pourcentage sur un troncon

/*
--pour vérifier les types de géométrie de topology, car il n'y a pas que des points
SELECT 
    id,
    geom,
    ST_GeometryType(geom) AS geometry_type
FROM 
    public.core_topology;
*/


/*
--ici c'est une sélection pour visualiser les troncons trouvés et l'id du quel il est relié,réussi
WITH intersecting_paths AS (
    SELECT 
        p.*,
        t.id AS topo_id
    FROM 
        public.core_path AS p
    JOIN 
        public.core_topology AS t ON ST_Intersects(p.geom, ST_Buffer(t.geom, 1))
    WHERE 
        t.id IN (37, 38, 39, 40, 41)
        AND ST_GeometryType(t.geom) = 'ST_Point' -- Filtrer les géométries de type point uniquement, car il existe les linestring qui y sont aussi,
        -- si c'est bon enlever le AND et les id et garder seulement st_geometrypoint
),
insert_data AS (
    SELECT 
        0 AS "order",
        p.id AS path_id,
        ip.topo_id AS topo_object_id,
        ST_LineLocatePoint(p.geom, t.geom) AS start_position,
        ST_LineLocatePoint(p.geom, t.geom) AS end_position
    FROM 
        intersecting_paths AS ip
        INNER JOIN core_path AS p ON ip.id = p.id
        INNER JOIN core_topology AS t ON ip.topo_id = t.id -- Utiliser INNER JOIN pour ne considérer que les géométries de type point
)
SELECT * FROM insert_data;
*/