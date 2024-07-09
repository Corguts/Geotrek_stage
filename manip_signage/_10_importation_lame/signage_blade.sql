-- Importation dans signage_blade
INSERT INTO public.signage_blade (number, date_insert, date_update, deleted, direction_id, type_id, color_id, topology_id, signage_id)
SELECT
    number_lame AS number,
    CURRENT_DATE AS date_insert,
    CURRENT_DATE AS date_update,
    FALSE AS deleted,
    lame.id_direction AS direction_id,
    2 AS type_id, -- 2 correspond à la lame directionnelle
    3 AS color_id, -- 3 correspond à la matière qui est du bois
    s.topo_object_id AS topology_id, -- l'id du poteau de signalétique
    s.topo_object_id AS signage_id-- l'id pareil du poteau
FROM
    public.signage_signage s
JOIN
    geotrek.lame lame
ON
    s.code = lame.n_poteau::varchar;

UPDATE geotrek.lame
SET blade_id = sb.id
FROM public.signage_blade sb
WHERE lame.number_lame = sb.number;