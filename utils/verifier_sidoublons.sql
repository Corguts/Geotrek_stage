SELECT "N_Poteau", COUNT(*) AS count
FROM geotrek.signaletique_collector
GROUP BY "N_Poteau"
HAVING COUNT(*) > 1
ORDER BY "N_Poteau" ASC;
