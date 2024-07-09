DROP TABLE IF EXISTS geotrek.lignes;

-- Créer la table geotrek.lignes
CREATE TABLE geotrek.lignes (
    id SERIAL PRIMARY KEY,
    blade_id INTEGER,
    number_lame TEXT,
    number_ligne TEXT,
    partie_fleche TEXT,
    ordre_ligne INTEGER,
    n_poteau INTEGER,
    description TEXT,
    line_id INTEGER,
    linepictogram_id INTEGER
);

-- Insérer les parties de la colonne fleche de signage_blade dans la table lignes
INSERT INTO geotrek.lignes (blade_id, partie_fleche, ordre_ligne,number_lame, n_poteau)
SELECT
    s.blade_id AS blade_id,
    trim(partie) AS partie_fleche,
    row_number() OVER (PARTITION BY s.id ORDER BY ordre) AS ordre_ligne, --génére des chiffres dans l'ordre lorsqu'il y a séparation pour chaque lame
    s.number_lame AS number_lame,
    s.n_poteau AS n_poteau
FROM
    geotrek.lame AS s
CROSS JOIN LATERAL regexp_split_to_table(s.fleche, E'\\d,\\s|;') WITH ORDINALITY t(partie, ordre)-- on a ici le \\d pour numérique et \\s pour espace, ce symbole | pour dire "ou" le point-virgule
WHERE
    partie <> ''; -- Sélectionne les parties non vides, car il y a 15 lignes sans rien dedans, donc on ne les prend pas
/*
-- Afficher les résultats
SELECT * FROM geotrek.lignes
ORDER BY partie_fleche;
*/
/*
-- Ajouter une nouvelle colonne longueur pour la longueur de caractères à la table lignes
ALTER TABLE geotrek.lignes ADD COLUMN longueur INTEGER;

-- Mettre à jour la colonne longueur avec la longueur de chaque partie de la colonne partie_fleche
UPDATE geotrek.lignes
SET longueur = length(partie_fleche);

-- Afficher les résultats
SELECT * FROM geotrek.lignes
ORDER BY longueur;
*/
/*
UPDATE geotrek.lignes AS l
SET description = si.description_fr
FROM public.signage_signage AS si
WHERE l.n_poteau::text = si.code;
*/

UPDATE geotrek.lignes AS l
SET description = si.description_fr
FROM (
    SELECT DISTINCT ON (code) code, description_fr
    FROM public.signage_signage
) AS si
WHERE l.n_poteau::text = si.code
AND NOT EXISTS (
    SELECT 1
    FROM geotrek.lignes AS l2
    WHERE l2.n_poteau = l.n_poteau
    AND l2.id < l.id
);


--partie ajout de la distance en récupérant du text  c'est celui qui permet de récupérer le plus met dans en rester a peu prés 100 a régler et en tout j'en aurai 281 lignes sans chiffres

-- Ajouter une nouvelle colonne distance à la table lignes
ALTER TABLE geotrek.lignes ADD COLUMN distance DECIMAL;

UPDATE geotrek.lignes
SET distance = 
    CASE
        -- Cas où la partie_fleche suit le modèle de kilométrage
        WHEN partie_fleche ~ '(\d{1,2})\s?km(\s\d+(\.\d+)?)?' THEN 
            CAST(REGEXP_REPLACE(partie_fleche, '^.*?(\d+(\.\d+)?)\s?km.*$', E'\\1') AS DECIMAL)
        -- Cas où la partie_fleche contient une distance avec virgule ou point décimal
        WHEN partie_fleche ~ '\s?[Gg][Rr]\s?\d+\s?(,|\.)?\d+' THEN
            CASE
                -- Si la partie_fleche contient GR suivi de chiffres mais sans décimal, mettre NULL
                WHEN partie_fleche ~ '\s?[Gg][Rr]\s?\d+\s?(,|\.)\d+' THEN 
                    CAST(REGEXP_REPLACE(partie_fleche, '.*\s?[Gg][Rr]\s?\d+\s?(,|\.)?(\d+).*', E'\\2') AS DECIMAL)
                -- Si la partie_fleche contient GR suivi de chiffres mais sans décimal, mettre NULL
                ELSE NULL
            END
        -- Cas où la partie_fleche contient un chiffre décimal sans GR
        WHEN partie_fleche ~ '\d+(\.|,)\d+' THEN 
            CASE
                -- Si la partie_fleche contient plusieurs points ou virgules, mettre 9999
                WHEN (SELECT COUNT(*) FROM regexp_matches(partie_fleche, '[.,]', 'g')) > 1 THEN 9999
                -- Sinon extraire la distance en remplaçant les virgules par des points
                ELSE CAST(REPLACE(REGEXP_REPLACE(partie_fleche, '[^\d.,]', '', 'g'), ',', '.') AS DECIMAL)
            END
        -- Cas où la partie_fleche contient un nombre à la fin de la chaîne ou un nombre décimal avec un point ou une virgule à la fin de la chaîne
        WHEN partie_fleche ~ '(\d+(\.|,)?\d*)$' THEN 
            CAST(REGEXP_REPLACE(partie_fleche, '^.*(\d+(\.|,)?\d*)$', E'\\1') AS DECIMAL)
        ELSE NULL -- Autres cas, mettre NULL
    END;

-- Afficher les résultats
SELECT * FROM geotrek.lignes
ORDER BY n_poteau;


--script en cours pour l'importation de nouvelles lignes pour pictogramme
INSERT INTO geotrek.lignes (description,n_poteau,number_lame, blade_id, number_ligne, linepictogram_id)
SELECT * FROM (
	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN LOWER(ln.description) ~ '(?<![a-zA-Z])abri' OR LOWER(ln.description) ~ '.*?cayrou.*?' THEN 3
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    (LOWER(ln.description) ~ '(?<![a-zA-Z])abri' OR LOWER(ln.description) ~ '.*?cayrou.*?')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN LOWER(ln.description) ~ '\((eau)' OR LOWER(ln.description) ~ 'point\sd\Seau' THEN 4
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    (LOWER(ln.description) ~ '\((eau)' OR LOWER(ln.description) ~ 'point\sd\Seau')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
		ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN LOWER(ln.description) ~ 'randoetape' OR LOWER(ln.description) ~ 'rando\s*?etape' OR LOWER(ln.description) ~ 'rando\s*?é\s*tape' THEN 6
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    (LOWER(ln.description) ~ 'randoetape' OR LOWER(ln.description) ~ 'rando\s*?etape' OR LOWER(ln.description) ~ 'rando\s*?é\s*tape')

	UNION ALL

	SELECT 
	    ln.description,		
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN LOWER(ln.description) ~ 'tour\s*?du\s*?lot' THEN 16
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    (LOWER(ln.description) ~ 'tour\s*?du\s*?lot')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
		ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ 'PE,' OR (ln.description) ~ 'PE\s\S' OR (ln.description) ~ 'PE\s-'THEN 5
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ 'PE,' OR (ln.description) ~ 'PE\s\S')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN LOWER(ln.description) ~ 'gr\d*' THEN
	            CASE
	                WHEN (ln.description) ~ 'GR\s6\s(/|$)\sGR\s652\s(/|$)\sGR'  OR (ln.description) ~ 'GR\s6\s-\sGR\s652\s-\sGR' THEN 15
	                ELSE NULL
	            END
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ 'GR\s6\s(/|$)\sGR\s652\s(/|$)\sGR'  OR (ln.description) ~ 'GR\s6\s-\sGR\s652\s-\sGR')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
 	       WHEN (ln.description) ~ 'GR\s46\s(/|$)\sGR\s652,' THEN 10
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ 'GR\s46\s(/|$)\sGR\s652,')

	UNION ALL

	SELECT
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
 	       WHEN (ln.description) ~ '(?<!GR.*?)GR\s36\s(/|$)\sGR\s46,' OR (ln.description) ~ 'GR\s36\s(/|$)\sGR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s36\s-\s46' THEN 8
 	       ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ '(?<!GR.*?)GR\s36\s(/|$)\sGR\s46,' OR (ln.description) ~ 'GR\s36\s(/|$)\sGR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s36\s-\s46')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ '(?<!GR.*?)GR\s6\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s6,' THEN 7
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ '(?<!GR.*?)GR\s6\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s6,')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ '(?<!GR.*?)GR\s46\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s46,' THEN 9
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ '(?<!GR.*?)GR\s46\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s46,')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ '(?<!GR.*?)GR\s36\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s36,' THEN 11
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ '(?<!GR.*?)GR\s36\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s36,')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ '(?<!GR.*?)GR\s64\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s64,' THEN 12
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ '(?<!GR.*?)GR\s64\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s64,')


	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ 'GR\s651\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s651,' OR (ln.description) ~ '(?<!GR.*?)GR651,' THEN 13
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ 'GR\s651\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s651,' OR (ln.description) ~ '(?<!GR.*?)GR651,')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ '(?<!GR.*?)GR\s652\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s652,' OR (ln.description) ~ '(?<!GR.*?)GR652,' THEN 14
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ '(?<!GR.*?)GR\s652\s(/|$)\s(?!.*GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s652,' OR (ln.description) ~ '(?<!GR.*?)GR652,')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ 'GR\s65\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s65,'  THEN 17
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ 'GR\s65\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s65,')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ 'GR\s65\s(/|$)\sGR\s6,' OR (ln.description) ~ 'GR\s65\s(/|$)\sGR\s6\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s65\s-\s6' THEN 18
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ 'GR\s65\s(/|$)\sGR\s6,' OR (ln.description) ~ 'GR\s65\s(/|$)\sGR\s6\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s65\s-\s6')

	UNION ALL

	SELECT 
	    ln.description,
		ln.n_poteau,
		ln.number_lame,
	    ln.blade_id,
		ln.number_ligne,
	    CASE
	        WHEN (ln.description) ~ '(?<!GR.*?)GR\s652\s(/|$)\sGR\s64,' OR (ln.description) ~ 'GR\s652\s(/|$)\sGR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s652\s-\s64'OR (ln.description) ~ 'GR\s64\s(/|$)\sGR\s652,'THEN 19
	        ELSE NULL
	    END AS linepictogram_id
	FROM
	    geotrek.lignes AS ln
	WHERE 
	    ((ln.description) ~ '(?<!GR.*?)GR\s652\s(/|$)\sGR\s64,' OR (ln.description) ~ 'GR\s652\s(/|$)\sGR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s652\s-\s64'OR (ln.description) ~ 'GR\s64\s(/|$)\sGR\s652,')
	
) AS querty;

-- Afficher les résultats
SELECT * FROM geotrek.lignes
ORDER BY n_poteau;




DELETE FROM public.signage_line_pictograms;
DELETE FROM public.signage_line







WITH null_ordre_ligne AS (
    SELECT 
        id,
        n_poteau,
        ROW_NUMBER() OVER (PARTITION BY n_poteau ORDER BY id) + 5 AS new_order
    FROM 
        geotrek.lignes
    WHERE 
        ordre_ligne IS NULL
)
UPDATE 
    geotrek.lignes AS ligne
SET 
    ordre_ligne = null_ordre_ligne.new_order
FROM 
    null_ordre_ligne
WHERE 
    ligne.id = null_ordre_ligne.id;


SELECT * FROM geotrek.lignes
ORDER BY n_poteau;


UPDATE geotrek.lignes AS ligne
SET 
    number_ligne = CONCAT(ligne.number_lame, LPAD(ligne.ordre_ligne::text, 3, '0'))
FROM geotrek.lignes AS B;


UPDATE geotrek.lignes
SET partie_fleche = 'pictogramme'
WHERE partie_fleche IS NULL;



INSERT INTO public.signage_line (text, blade_id, number, direction_id,distance) --insertion du texte, de l'identifiant de la lame qui va avec, le chiffre unique à la ligne, et la direction en lien avec la lame
SELECT partie_fleche,
sb.id AS blade_id,
number_ligne::INTEGER AS number, 
sb.direction_id, 
distance
FROM geotrek.lignes l
JOIN public.signage_blade sb ON l.blade_id = sb.id; --lien entre la clé étrangere blade_id et id de la table blade


SELECT * FROM public.signage_line
ORDER BY number;


UPDATE geotrek.lignes AS ln
SET line_id = (
    SELECT sl.id
    FROM public.signage_line AS sl
    WHERE 
            sl.number::TEXT = ln.number_ligne
    );

INSERT INTO public.signage_line_pictograms (line_id, linepictogram_id)
SELECT line_id, linepictogram_id
FROM geotrek.lignes
WHERE linepictogram_id IS NOT NULL;
