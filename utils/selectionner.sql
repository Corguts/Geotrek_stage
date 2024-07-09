--selection les valeurs avec les memes valeurs dans une colonne
SELECT *
FROM geotrek.signaletique_collector
WHERE geom IN (
    SELECT geom
    FROM geotrek.signaletique_collector
    GROUP BY geom
    HAVING COUNT(*) > 1
);
