--création d'une table lame pour la préparation à l'importation, je demande à quelle fleche elle provient pour l'odre des lames
DROP TABLE IF EXISTS geotrek.lame;
CREATE TABLE geotrek.lame (
    id SERIAL PRIMARY KEY,
    n_poteau INTEGER,
    fleche TEXT,
    ordre_lame INTEGER,
    number_lame TEXT
);

--l'idée ici est de mettre toutes les cellules des 5 colonnes flèches chacunes sur une ligne distincte avec les infos
WITH cte AS (
    SELECT
        sc."n_poteau",
        "fleche_1" AS fleche,
        1 AS ordre_lame
    FROM
        geotrek.signaletique_collector sc
    WHERE
        "fleche_1" IS NOT NULL

    UNION ALL

    SELECT
        sc."n_poteau",
        "Ffleche_2" AS fleche,
        2 AS ordre_lame
    FROM
        geotrek.signaletique_collector sc
    WHERE
        "fleche_2" IS NOT NULL

    UNION ALL

    SELECT
        sc."n_poteau",
        "fleche_3" AS fleche,
        3 AS ordre_lame
    FROM
        geotrek.signaletique_collector sc
    WHERE
        "fleche_3" IS NOT NULL

    UNION ALL

    SELECT
        sc."n_poteau",
        "fleche_4" AS fleche,
        4 AS ordre_lame
    FROM
        geotrek.signaletique_collector sc
    WHERE
        "fleche_4" IS NOT NULL

    UNION ALL

    SELECT
        sc."n_poteau",
        "fleche_5" AS fleche,
        5 AS ordre_lame
    FROM
        geotrek.signaletique_collector sc
    WHERE
        "fleche_5" IS NOT NULL
)
INSERT INTO geotrek.lame (n_poteau, fleche, ordre_lame)
SELECT * FROM cte
ORDER BY
    "n_poteau", ordre_lame;


--on rajoute la colonne de direction de chaque lame selon la lettre dans le texte
ALTER TABLE geotrek.lame
ADD COLUMN direction VARCHAR;

UPDATE geotrek.lame
SET direction =
    CASE
		WHEN fleche LIKE '% D %' THEN 'Droite'
        WHEN fleche LIKE '% G %' THEN 'Gauche'
		WHEN TRIM(SUBSTRING(fleche FROM '[^ ]+')) = 'D' THEN 'Droite'
        WHEN TRIM(SUBSTRING(fleche FROM '[^ ]+')) = 'G' THEN 'Gauche'
		WHEN fleche LIKE '%D:%' THEN 'Droite'
        WHEN fleche LIKE '%D;%' THEN 'Droite'
        WHEN fleche LIKE '%D,%' THEN 'Droite'
		WHEN fleche LIKE '%G:%' THEN 'Gauche'
        WHEN fleche LIKE '%G;%' THEN 'Gauche'
        WHEN fleche LIKE '%G,%' THEN 'Gauche'
        ELSE 'a_verifier'
    END;

-- Ajout de la colonne id_direction et blade_id pour récuperer l'id générer des lames
ALTER TABLE geotrek.lame
ADD COLUMN id_direction INTEGER,
ADD COLUMN blade_id INTEGER;

-- Mettre à jour la colonne id_direction
UPDATE geotrek.lame
SET id_direction =
    CASE direction
        WHEN 'Droite' THEN 2
        WHEN 'a_verifier' THEN 1
        WHEN 'Gauche' THEN 3
        ELSE NULL
    END;


--vérification des différentes lames
SELECT *
FROM geotrek.lame
ORDER BY direction;

--a prendre en compte qu'il faudra récupérer aussi grace a la colonne sans_direct avec le 1 de signaletique collector pour ainsi mettre en sans direction 
--dans la colonne direction sinon le reste devient a_verifier ert ainsi les checker
-- par la suite, on fera un update de id_direction pour les changer selon direction


UPDATE geotrek.lame AS lame
SET 
    number_lame = CONCAT(lame.n_poteau, LPAD(lame.ordre_lame::text, 3, '0'))
FROM geotrek.lame AS B;