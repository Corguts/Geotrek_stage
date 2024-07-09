-- 1. Création schéma de travail dans geotrek 

CREATE SCHEMA IF NOT EXISTS geotrek; 

-- Création d'une table nettoyée à partir de "troncon_de_route"  

CREATE TABLE geotrek.troncon_de_route_clean AS 

SELECT gid, id, nature, nom_coll_g, nom_coll_d, importance, fictif, pos_sol, etat, date_creat, date_maj, date_app, date_conf, source, id_source, acqu_plani, prec_plani, acqu_alti, prec_alti, nb_voies, largeur, it_vert, prive, sens, bus, urbain, vit_moy_vl, acces_vl, acces_ped, fermeture, nat_restr, restr_h, restr_p, restr_ppe, restr_lar, restr_lon, restr_mat, bornedeb_g, bornedeb_d, bornefin_g, bornefin_d, inseecom_g, inseecom_d, alias_g, alias_d, date_serv, id_voie_g, id_voie_d, id_rn, id_iti, numero, num_europ, cl_admin, gestion, toponyme, iti_cycl, voie_verte, nature_iti, nom_iti, delestage, src_ban_g, src_ban_d, nom_ban_g, nom_ban_d, ld_ban_g, ld_ban_d, id_ban_g, id_ban_d, sens_cyc_g, sens_cyc_d, cyclable_g, cyclable_d, retourdfci, gab_dfci, impas_dfci, ndet_dfci, oalim_dfci, ptmax_dfci, piste_dfci, dfci_debro, dfci_fosse, sens_dfci, terr_dfci, vit_dfci, crois_dfci,  

ST_LINEMERGE(ST_Force2D(geom)) as geom 

FROM geotrek.troncon_de_route; 

-- Déplacement des points proches 

UPDATE  geotrek.troncon_de_route_clean  SET geom = ST_SnapToGrid(geom, 2); 

-- Suppression des doublons  (non executé) 

DELETE FROM  geotrek.troncon_de_route_clean  a 

WHERE a.id <> (SELECT min(b.id) FROM  geotrek.troncon_de_route_clean  b WHERE ST_Equals(a.geom, b.geom)); 

-- Réduction des géométries 2 mètres 

UPDATE geotrek.troncon_de_route_clean SET geom = ST_SimplifyPreserveTopology(geom, 2); 

-- Suppression des géométries vides 

DELETE FROM geotrek.troncon_de_route_clean WHERE ST_IsEmpty(geom); 


--insertion dans la table core.path de géotrek

INSERT INTO core_path (date_insert, valid, structure_id, source_id, draft,name, comments, geom) 

     

SELECT  

CURRENT_TIMESTAMP as date_insert, 

ST_ISVALID(geom) as valid, 

1 as structure_id, 

1 as source_id, 

'false' as draft, 

CASE  

WHEN nom_ban_g IS NOT NULL THEN  nom_ban_g 

WHEN nom_coll_g IS  NULL AND numero IS NOT NULL THEN numero 

ELSE NULL END as name, 

id as comments, 

geom as geom 

FROM 

geotrek.troncon_de_route_clean 




