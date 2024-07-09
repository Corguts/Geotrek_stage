--si besoin d'enlever des lignes bien faire attention a l'ordre pour supprimer sinon ca ne marche pas à cause des clés étrangères
--Dans l'ordre pour supprimer des images: thumbnail>thumbnails_source>common_attachment
DELETE FROM public.easy_thumbnails_thumbnaildimensions;
DELETE FROM public.easy_thumbnails_thumbnail;--WHERE id IN (1,2,3,4);
DELETE FROM public.easy_thumbnails_source;--WHERE id IN (1,2,3,4,7);
DELETE FROM public.common_attachment;--WHERE id IN (4,9);

--Dans l'odre: line>blade>signage>pathaggregation qui relie aux troncons puis on pourra supprimer dans topology
DELETE FROM public.signage_line_pictograms;
DELETE FROM public.signage_line;--WHERE id IN (1,2,3);
DELETE FROM public.signage_blade; --WHERE id IN (1,2);
DELETE FROM public.signage_signage; --WHERE topo_object_id IN (6,7,9,25,26,27);
DELETE FROM core_pathaggregation
WHERE start_position = end_position;--car les points sont ceux qui ont les valeurs égales
DELETE FROM core_topology
WHERE kind = 'SIGNAGE'; -- je supprime les points qui sont ici reperable par signage


--si supprimer toutes les lignes,juste enlever a partir du where