--suite du script pour la deuxieme table a faire selon la nouvelle table,réussi
DROP TABLE IF EXISTS geotrek.signage_topo10m;
CREATE TABLE geotrek.signage_topo10m AS
WITH a AS (
    SELECT
        sc.new_id AS id_signaletique,
        tr.id AS id_troncon,
        sc.geom_path,
        ST_ClosestPoint(tr.geom, sc.geom_path) AS geom_topo,
        ST_DISTANCE(sc.geom_path, ST_ClosestPoint(tr.geom, sc.geom_path)) AS distopo,
        sc."N_Poteau",
        sc."date_clean",
        ROW_NUMBER() OVER (PARTITION BY sc.new_id ORDER BY ST_DISTANCE(sc.geom_path, ST_ClosestPoint(tr.geom, sc.geom_path))) AS rank
    FROM
        geotrek.signage_iti21m sc
    INNER JOIN
        public.core_path tr ON ST_DWithin(sc.geom_path, tr.geom, 2000) -- Affiner la zone de recherche à 2000 mètres, car sinon prend trop de temps ssachant que le plus loin est a 1700m
)
SELECT 
    id_signaletique,
    id_troncon,
    geom_path,
    CASE
        WHEN distopo <= 10 THEN geom_topo
        ELSE geom_path -- Conserver la géométrie d'origine si la distance est supérieure à 10 mètres
    END AS geom_topo,
    CASE
        WHEN distopo <= 10 THEN distopo
        ELSE ST_DISTANCE(geom_path, geom_topo) -- Calculer la distance à partir de la géométrie d'origine
    END AS distopo
FROM
    a
WHERE
    rank = 1
ORDER BY
    distopo DESC;


--il faut ajouter  une nouvelle colonne qui servira a mettre les clés étrangères pour faire le lien entre signage300m et signage_signage
ALTER TABLE geotrek.signage_topo10m
ADD COLUMN topo_object_id integer;