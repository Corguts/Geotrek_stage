--en complément : 

-- ajout de tronçons en plus, selon des communes en particulier 
UPDATE core_path 
SET visible = 'true' 
FROM zoning_city AS a
WHERE ST_Within(core_path.geom, a.geom)
AND LOWER(a.name) LIKE 'lendou-en-quercy'; -- () mettre le nom de la commune du village ou de la ville entre les simples guillemets, bien mettre en minuscule
-- d'autres exemples de la façon d'écrire: anglars-juillac, castelnau montratier-sainte alauzie, limogne-en-quercy, etc...


-- ajout de tronçons en plus, selon des CC en particulier 
UPDATE core_path 
SET visible = 'true' 
FROM zoning_district AS a
WHERE ST_Within(core_path.geom, a.geom)
AND a.name = 'CC Causses et Vallée de la Dordogne';
/*Voici les différents CC pouvant être recherchés:
CA du Grand Cahors
CC Cazals-Salviac
CC Ouest Aveyron Communauté
CC du Causse de Labastide-Murat
CC Grand-Figeac
CC Causses et Vallée de la Dordogne
CC de la Vallée du Lot et du Vignoble
CC du Pays de Lalbenque-Limogne
CC Quercy - Bouriane
CC du Quercy Blanc
Cahors - Vallée du Lot
Causse Bouriane
Figeac - Vallée du Lot et du Célé
Vallée de la Dordogne
PNR des Causses du Quercy
*/






/*
UPDATE core_path 
SET visible = 'true' 
FROM zoning_city AS a
WHERE core_path.comments = CAST(a.id AS TEXT)
AND a.name = 'Albas'; 
*/