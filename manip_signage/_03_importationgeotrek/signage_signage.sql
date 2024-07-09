--insertion de topology sur signaletique
INSERT INTO public.signage_signage (topo_object_id, name,structure_id,type_id,published_fr,published,name_fr,name_en,manager_id,printed_elevation,publication_date)
SELECT id, CONCAT('import_initial', 
ROW_NUMBER() OVER (ORDER BY id)) AS name, 
1 AS structure_id, 2 AS type_id, 
TRUE AS published_fr, 
TRUE AS published,
CONCAT('import_initial', ROW_NUMBER() OVER (ORDER BY id)) AS name_fr,
CONCAT('initial_import', ROW_NUMBER() OVER (ORDER BY id)) AS name_en,
1 AS manager_id,max_elevation,
CURRENT_TIMESTAMP AS publication_date
FROM public.core_topology
WHERE id > 48;


/*ce qui se passe ici, je veux les mettres les infos de topology dans signage en récuprant les id avec topo_object_id,mettre dans name un nom,
ici c'est du test donc il met test_importet le chiffre qui suit,structure id le chiffre 1 donc l'ADTmettre TRUE dans les 2 published on pourra plus tard le mettre aussi en anglais
,le chiffre 1 pour manager_id qui correspond à l'organisme A qu'on ne sait pas encore qui sait,mettre l'élévation du point pour l'afficher et la date de publication, quand je l'importe.*/

/*prochaine étape sera de compléter les informations manquantes pour cela il faudra faire un lien en récupérant les id générés par topology 
et l'envoyer sur signage_300m(changera pour 20m plus tard) pour ainsi envoyer les infs sur signage_signage*/

UPDATE geotrek.signage_intersection AS s
SET topo_object_id = t.id
FROM public.core_topology AS t
WHERE s.geom_topo = t.geom;

SELECT *
FROM geotrek.signage_intersection
ORDER BY topo_object_id;
--ici je fais le lien avec le geom de topology qui est le meme que le geom_path de signage_300m pour ainsi récupérer les id correspondant,pour ça qu'il faut pas de doublon de geom

--ici rajouter les distances entre les signalétiques et l'emplacement le plus proche du point sur les troncons dans description et on ajoute la date d'implantation de date_clean
--ajout des object_id de topology dans signage300m pour le lien avec signage_signage

UPDATE public.signage_signage AS s
SET description = t.distance_topo,
    implantation_year = t.date_clean,
    code = t."n_poteau",
    description_fr = t.description
FROM geotrek.signage_intersection AS t
WHERE s.topo_object_id = t.topo_object_id;
--AND s.topo_object_id BETWEEN 37 AND 41;

UPDATE public.signage_signage AS t
SET 
    name = 'import_initial ' || si."n_poteau",
    name_fr = 'import_initial ' || si."n_poteau",
    name_en = 'import_initial ' || si."n_poteau"
FROM geotrek.signage_intersection AS si
WHERE si."n_poteau"::TEXT = t.code;

/*
--si souci remettre a null du fait du souci de plusieurs points sont sur le meme id  signaletique
UPDATE geotrek.signage_intersection
SET topo_object_id = NULL;





--si besoin d'ajouter des choses en plus utiliser update-set
UPDATE public.signage_signage
SET publication_date = CURRENT_TIMESTAMP
WHERE topo_object_id in (29,30,31);

*/

/* si besoin de updater dans le name,name_fr et name_en
dans mon cas j'enleve import initial du début trop redondant
UPDATE signage_signage
SET name_fr = REGEXP_REPLACE(name_fr, '^import_initial\s*', '')
WHERE name_fr LIKE 'import_initial%';
*/