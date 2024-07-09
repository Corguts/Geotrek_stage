--script importation de thumbnail pour les images sources
INSERT INTO public.easy_thumbnails_source (name, modified, storage_hash)
SELECT chemin as name, NOW(), 'f9bde26a1556cd667f742bd34ec7c55e'
FROM geotrek.image_collector
WHERE NOT (chemin LIKE '%/150x150_%');


--importation des identifiants des images sources dans la table temporaire pour ensuite faire le lien avec les vignettes pour l'étape d'après 

UPDATE geotrek.image_collector AS ic
SET source_id = ets.id
FROM easy_thumbnails_source AS ets
WHERE REPLACE(ic.chemin, '/150x150_', '/') = ets.name;


-- insertion des chemins des vignettes des images dans easy_thumbnails_thumbnail
INSERT INTO public.easy_thumbnails_thumbnail (modified, source_id, storage_hash, name)
SELECT 
    NOW() AS modified,
    source_id,
    'd26becbf46ac48eda79c7a39a13a02dd' AS storage_hash,
    chemin AS name
FROM 
    geotrek.image_collector
WHERE 
    chemin LIKE '%/150x150_%';




/*

--importation du chemin sur easy_thumbnails_source test
INSERT INTO easy_thumbnails_source (name,storage_hash,modified)
VALUES ('paperclip/signage_signage/tmp_img_signa/img_signa_gr652/230803_photo620.jpg','f9bde26a1556cd667f742bd34ec7c55e',NOW());
*/