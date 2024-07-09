
--script pour tous les pictos , réussi 

INSERT INTO public.signage_line_pictograms (line_id, linepictogram_id)
SELECT line_id, linepictogram_id
FROM geotrek.lignes
WHERE linepictogram_id IS NOT NULL;



/*
--2eme cas avec les textes des lignes mais qui est erroné du coup

WITH LinePictogramIDs AS (
    SELECT
        ln.id AS line_id,
        CASE
            WHEN LOWER(ln.text) ~ '(?<![a-zA-Z])abri' OR LOWER(ln.text) ~ '.*?cayrou.*?' THEN 3
            WHEN LOWER(ln.text) ~ '\((eau)' OR LOWER(ln.text) ~ 'point\sd\Seau' THEN 4
            WHEN LOWER(ln.text) ~ 'randoetape' OR LOWER(ln.text) ~ 'rando\s*?etape' OR LOWER(ln.text) ~ 'rando\s*?é\s*tape' THEN 6
            WHEN LOWER(ln.text) ~ 'tour\s*?du\s*?lot' THEN 16
            --WHEN LOWER(sl.text) ~ 'piste\sequestre' OR LOWER(sl.text) ~ '%équestre%' OR LOWER(sl.text) ~ 'piste\séquestre' THEN 5
            WHEN LOWER(ln.text) ~ 'gr\d*' THEN
                CASE
                    WHEN LOWER(ln.text) ~ 'gr652-64'  OR LOWER(ln.text) ~ 'gr\s*?652-' OR LOWER(ln.text) ~ 'gr.*?652.*?gr' OR LOWER(ln.text) ~'gr\s652.*?64' OR LOWER(ln.text) ~'gr652.*?64' THEN 15
                    WHEN LOWER(ln.text) ~ '652.*?46' OR LOWER(ln.text) ~ '46.*?652' THEN 10
                    WHEN LOWER(ln.text) ~ 'gr36.*?46' OR LOWER(ln.text) ~ 'gr46.*?36' OR LOWER(ln.text) ~ 'gr\s36\S46' THEN 8
                    WHEN LOWER(ln.text) ~ 'gr6(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ '(?<!\d\s|\S\s)gr\s6(?![0-9])' OR LOWER(ln.text) ~ 'gr\s6\s\d\S' OR LOWER(ln.text) ~ 'gr6\s\d\S' THEN 7
                    WHEN LOWER(ln.text) ~ 'gr46(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ '(?<!\d\s|\S\s)gr\s46(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ 'gr\s46\s\d\S' OR LOWER(ln.text) ~ 'gr46\s\d\S' THEN 9
                    WHEN LOWER(ln.text) ~ 'gr36(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ '(?<!\d\s|\S\s)gr\s36(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ 'gr\s36\s\d\S' OR LOWER(ln.text) ~ 'gr36\s\d\S' THEN 11
                    WHEN LOWER(ln.text) ~ 'gr64(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ '(?<!\d\s|\S\s)gr\s64(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ 'gr\s64\s\d\S' OR LOWER(ln.text) ~ 'gr64\s\d\S' THEN 12
                    WHEN LOWER(ln.text) ~ 'gr651(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ '(?<!\d\s|\S\s)gr\s651(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ 'gr\s651\s\d\S' OR LOWER(ln.text) ~ 'gr651\s\d\S' OR LOWER(ln.text) ~'gr\s651\s\S' THEN 13
                    WHEN LOWER(ln.text) ~ 'gr652(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ '(?<!\d\s|\S\s)gr\s652(?![0-9]|\s[0-9])' OR LOWER(ln.text) ~ 'gr\s652\s\d\S' OR LOWER(ln.text) ~ 'gr652\s\d\S' OR LOWER(ln.text) ~'gr\s652\s\S' THEN 14    
                END
            ELSE NULL
        END AS linepictogram_id
    FROM
        geotrek.lignes AS ln
)
INSERT INTO public.signage_line_pictograms (line_id, linepictogram_id)
SELECT
    line_id,
    linepictogram_id
FROM
    LinePictogramIDs
WHERE
    linepictogram_id IS NOT NULL; -- Ajoutez cette clause pour exclure les lignes avec des valeurs nulles

*/


/*
--selection en cours pour chaque condition puis réussir a créer de nouvelle ligne pour chaque lame pour les pictos
		ln.description,
		ln.blade_id,
        CASE
            WHEN LOWER(ln.description) ~ '(?<![a-zA-Z])abri' OR LOWER(ln.description) ~ '.*?cayrou.*?' THEN 3
            WHEN LOWER(ln.description) ~ '\((eau)' OR LOWER(ln.description) ~ 'point\sd\Seau' THEN 4
            WHEN LOWER(ln.description) ~ 'randoetape' OR LOWER(ln.description) ~ 'rando\s*?etape' OR LOWER(ln.description) ~ 'rando\s*?é\s*tape' THEN 6
            WHEN LOWER(ln.description) ~ 'tour\s*?du\s*?lot' THEN 16
            WHEN (ln.description) ~ 'PE,' OR (ln.description) ~ 'PE\s\S' THEN 5
            WHEN LOWER(ln.description) ~ 'gr\d*' THEN
                CASE
                    WHEN (ln.description) ~ 'GR\s6\s(/|$)\sGR\s652\s(/|$)\sGR'  OR (ln.description) ~ 'GR\s6\s-\sGR\s652\s-\sGR' THEN 15
                    WHEN (ln.description) ~ 'GR\s46\s(/|$)\sGR\s652,' THEN 10
                    WHEN (ln.description) ~ 'GR\s36\s(/|$)\sGR\s46,' OR (ln.description) ~ 'GR\s36\s(/|$)\sGR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s36\s-\s46'THEN 8
                    WHEN (ln.description) ~ 'GR\s6\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s6,' THEN 7
                    WHEN (ln.description) ~ 'GR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s46,' THEN 9
                    WHEN (ln.description) ~ 'GR\s36\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s36,' THEN 11
                    WHEN (ln.description) ~ 'GR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s64,' THEN 12
                    WHEN (ln.description) ~ 'GR\s651\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s651,' OR (ln.description) ~ '(?<!GR.*?)GR651,' THEN 13
                    WHEN (ln.description) ~ 'GR\s652\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s652,' OR (ln.description) ~ '(?<!GR.*?)GR652,' THEN 14
                    WHEN (ln.description) ~ 'GR\s65\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s65,'  THEN 17
                    WHEN (ln.description) ~ 'GR\s65\s(/|$)\sGR\s6,' OR (ln.description) ~ 'GR\s65\s(/|$)\sGR\s6\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s65\s-\s6' THEN 18
                    WHEN (ln.description) ~ 'GR\s652\s(/|$)\sGR\s64,' OR (ln.description) ~ 'GR\s652\s(/|$)\sGR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s652\s-\s64'OR (ln.description) ~ 'GR\s64\s(/|$)\sGR\s652,'THEN 19
                    
                END
            ELSE NULL
        END AS linepictogram_id
    FROM
        geotrek.lignes AS ln
ORDER BY linepictogram_id;

*/

--script de dupplication de chaque when puis faire select distinct pour eviter d'avoir plusieurs fois le meme id de ligne pour un pictogramme
/*
SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'PE,' OR (ln.description) ~ 'PE\s\S' THEN 5
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'PE,' OR (ln.description) ~ 'PE\s\S')

UNION ALL

SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'GR\s36\s(/|$)\sGR\s46,' OR (ln.description) ~ 'GR\s36\s(/|$)\sGR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s36\s-\s46' THEN 8
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'GR\s36\s(/|$)\sGR\s46,' OR (ln.description) ~ 'GR\s36\s(/|$)\sGR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s36\s-\s46')

UNION ALL

SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'GR\s6\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s6,' THEN 7
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'GR\s6\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s6,')

UNION ALL

SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'GR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s46,' THEN 9
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'GR\s46\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s46,')

UNION ALL

SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'GR\s36\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s36,' THEN 11
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'GR\s36\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s36,')

UNION ALL

SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'GR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s64,' THEN 12
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'GR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s64,')


UNION ALL

SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'GR\s652\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s652,' OR (ln.description) ~ '(?<!GR.*?)GR652,' THEN 14
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'GR\s652\s(/|$)\s(?!GR)' OR (ln.description) ~ '(?<!GR.*?)GR\s652,' OR (ln.description) ~ '(?<!GR.*?)GR652,')

UNION ALL

SELECT 
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
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
	ln.id,
    ln.description,
    ln.blade_id,
    CASE
        WHEN (ln.description) ~ 'GR\s652\s(/|$)\sGR\s64,' OR (ln.description) ~ 'GR\s652\s(/|$)\sGR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s652\s-\s64'OR (ln.description) ~ 'GR\s64\s(/|$)\sGR\s652,'THEN 19
        ELSE NULL
    END AS linepictogram_id
FROM
    geotrek.lignes AS ln
WHERE 
    ((ln.description) ~ 'GR\s652\s(/|$)\sGR\s64,' OR (ln.description) ~ 'GR\s652\s(/|$)\sGR\s64\s(/|$)\s(?<!GR)' OR (ln.description) ~ 'GR\s652\s-\s64'OR (ln.description) ~ 'GR\s64\s(/|$)\sGR\s652,')

ORDER BY linepictogram_id;
*/
/*
--script selection pour visualiser le lien picto et lignes
SELECT
    text,
    sl.id AS line_id,
    CASE
        WHEN LOWER(sl.text) ~ '(?<![a-zA-Z])abri' OR LOWER(sl.text) ~ '.*?cayrou.*?' THEN 3
        WHEN LOWER(sl.text) ~ '\((eau)' OR LOWER(sl.text) ~ 'point\sd\Seau'THEN 4
        WHEN LOWER(sl.text) ~ 'randoetape' OR LOWER(sl.text) ~ 'rando\s*?etape'OR LOWER(sl.text) ~ 'rando\s*?é\s*tape' THEN 6
		WHEN LOWER(sl.text) ~ 'tour\s*?du\s*?lot' THEN 16
        WHEN LOWER(sl.text) ~ 'gr\d*' THEN
            CASE
                WHEN LOWER(sl.text) ~ 'gr652-64'  OR LOWER(sl.text) ~ 'gr\s*?652-'OR LOWER(sl.text) ~ 'gr.*?652.*?gr'OR LOWER(sl.text) ~'gr\s652.*?64' OR LOWER(sl.text) ~'gr652.*?64'THEN 15
				WHEN LOWER(sl.text) ~ '652.*?46' OR LOWER(sl.text) ~ '46.*?652'THEN 10
				WHEN LOWER(sl.text) ~ 'gr36.*?46' OR LOWER(sl.text) ~ 'gr46.*?36' OR LOWER(sl.text) ~ 'gr\s36\S46'  THEN 8
				WHEN LOWER(sl.text) ~ 'gr6(?![0-9]|\s[0-9])' OR LOWER(sl.text) ~ '(?<!\d\s|\S\s)gr\s6(?![0-9])' OR LOWER(sl.text) ~ 'gr\s6\s\d\S' OR LOWER(sl.text) ~ 'gr6\s\d\S'THEN 7
				WHEN LOWER(sl.text) ~ 'gr46(?![0-9]|\s[0-9])' OR LOWER(sl.text) ~ '(?<!\d\s|\S\s)gr\s46(?![0-9]|\s[0-9])'OR LOWER(sl.text) ~ 'gr\s46\s\d\S'OR LOWER(sl.text) ~ 'gr46\s\d\S'THEN 9
				WHEN LOWER(sl.text) ~ 'gr36(?![0-9]|\s[0-9])' OR LOWER(sl.text) ~ '(?<!\d\s|\S\s)gr\s36(?![0-9]|\s[0-9])'OR LOWER(sl.text) ~ 'gr\s36\s\d\S'OR LOWER(sl.text) ~ 'gr36\s\d\S'THEN 11
				WHEN LOWER(sl.text) ~ 'gr64(?![0-9]|\s[0-9])' OR LOWER(sl.text) ~ '(?<!\d\s|\S\s)gr\s64(?![0-9]|\s[0-9])'OR LOWER(sl.text) ~ 'gr\s64\s\d\S'OR LOWER(sl.text) ~ 'gr64\s\d\S'THEN 12
				WHEN LOWER(sl.text) ~ 'gr651(?![0-9]|\s[0-9])' OR LOWER(sl.text) ~ '(?<!\d\s|\S\s)gr\s651(?![0-9]|\s[0-9])'OR LOWER(sl.text) ~ 'gr\s651\s\d\S'OR LOWER(sl.text) ~ 'gr651\s\d\S' OR LOWER(sl.text) ~'gr\s651\s\S'THEN 13
                WHEN LOWER(sl.text) ~ 'gr652(?![0-9]|\s[0-9])' OR LOWER(sl.text) ~ '(?<!\d\s|\S\s)gr\s652(?![0-9]|\s[0-9])'OR LOWER(sl.text) ~ 'gr\s652\s\d\S'OR LOWER(sl.text) ~ 'gr652\s\d\S' OR LOWER(sl.text) ~'gr\s652\s\S'THEN 14    
           END
        ELSE NULL
    END AS linepictogram_id
FROM
    public.signage_line AS sl
ORDER BY LINEPICTOGRAM_id;
*/








