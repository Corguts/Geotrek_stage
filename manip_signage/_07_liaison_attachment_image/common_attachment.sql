
--script importation/liaison avec signage pour les photos(common_attachment),réussi

DELETE FROM public.common_attachment;
INSERT INTO public.common_attachment (is_image, filetype_id, creator_id, author, legend,license_id, content_type_id, attachment_file, object_id)
SELECT
    TRUE,
    11,
    6,
    'Pierre-Jerome Atger' AS author,
    'photo sur place' AS title,
    7,
    55,
    ic.chemin,
    ss.topo_object_id
FROM 
    geotrek.image_collector AS ic
JOIN 
    public.signage_signage AS ss ON ic.code_poteau::varchar = ss.code
WHERE 
    ic.chemin NOT LIKE '%/150x150%';

/* ceci est un exemple de comment doit se mettre le lien avec la photo et la signaletique
--importation du chemin relatif réussie, il faudra récupérer les valeurs obligatoires de fin
INSERT INTO common_attachment (attachment_file, object_id,content_type_id,creator_id,filetype_id,is_image)
VALUES ('paperclip/signage_signage/tmp_img_signa/img_signa_gr652/230803_photo620.jpg',31,55,6,11,TRUE);
*/






/*
WITH attachment_entry AS (
    -- Ajouter des entrées dans common_attachment avec les valeurs spécifiées
    INSERT INTO public.common_attachment (is_image, filetype_id, creator_id, content_type_id)
    VALUES (TRUE, 11, 6, 31)
    RETURNING id
)--RETURNING dans PostgreSQL permet de renvoyer des résultats après une opération d'insertion, de mise à jour ou de suppression pour ainsi voir les id bien importés
-- Mettre à jour la colonne attachment_file et object_id dans common_attachment
UPDATE public.common_attachment AS ca
SET 
    attachment_file = ic.chemin,
    object_id = ss.topo_object_id
FROM geotrek.image_collector AS ic
JOIN public.signage_signage AS ss ON ic.code_poteau::varchar  = ss.code
WHERE 
    ic.chemin NOT LIKE '%/150x150/%';
*/




/*a comprendre le is image prend true pour l'indiquer sur geotrek admin, le 11 de filetype_id correspond au type d'image qui est ici photographie,
creator_id avec 6 correspond à celui qui a créé/importer le fichier, ici Corentin. Le 55 de content_type_id indique que ces images sont en lien avec signage_signage(55)
lorsque je vais importer les chemins relatif des images de base, il me faut l'id de topology pour les rattacher au bon poteau, pour cela on va s'aider du code poteau de signage_signage
et code poteau de image_collector .*/

/*
--importation du chemin relatif pour test
INSERT INTO common_attachment (attachment_file, object_id,content_type_id,creator_id,filetype_id,is_image)
VALUES ('paperclip/signage_signage/tmp_img_signa/img_signa_gr652/230803_photo620.jpg',31,55,6,11,TRUE);
*/