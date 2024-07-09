--script réussi

INSERT INTO public.signage_line (text, blade_id, number, direction_id,distance) --insertion du texte, de l'identifiant de la lame qui va avec, le chiffre unique à la ligne, et la direction en lien avec la lame
SELECT partie_fleche,
sb.id AS blade_id,
number_ligne::INTEGER AS number, 
sb.direction_id, 
distance
FROM geotrek.lignes l
JOIN public.signage_blade sb ON l.blade_id = sb.id; --lien entre la clé étrangere blade_id et id de la table blade

UPDATE geotrek.lignes AS ln
SET line_id = (
    SELECT sl.id
    FROM public.signage_line AS sl
    WHERE 
            sl.number::TEXT = ln.number_ligne
    );


SELECT * FROM geotrek.lignes
ORDER BY n_poteau;
