--script permettant de mettre les données d'autres colonnes dans une meme colonne

WITH a AS

(SELECT --"Date_crati", "Type_iti", "FLECHE_1", "FLECHE_2", "FLECHE_3", "FLECHE_4", "Proprietai", "FLECHE_pb", "Type_herbe", "FLECHE_5", "F_hebergem", nb_fleche_, "Tour_du_Lo", "N_Poteau", "DateTerrai", "F1_km_SIG", "F2_km_SIG", "F3_km_SIG", "F4_km_SIG", "F5_km_SIG", "F1_a_Rempl", "F2_a_Rempl", "F3_a_Rempl", "F4_a_Rempl", "F5_a_Rempl", "Nb_F_a_Rem", "Date_terra", "GlobalID", "CreationDa", "Creator", "EditDate", "Editor", "Jalon_chan", "Remplaceme", "Remplace_1", photo, statut, toilette, abri, eau, iti_sup, "sans direc", signagedeb, geometry, date_clean
	"FLECHE_1",toilette,  abri, eau,
 	concat_ws ( '///',COALESCE("FLECHE_1", ''), COALESCE(toilette,''), COALESCE(abri,''), COALESCE( eau,'')) as ex
	FROM geotrek.signaletique_collector
WHERE abri IS NOT NULL)
	
	SELECT
	ex,
	SPLIT_PART(ex, '///', 1) as text,
	SPLIT_PART(ex, '///', 2) as toilette,
		SPLIT_PART(ex, '///', 3) as abri,
			SPLIT_PART(ex, '///',4 ) as eau
	
	FROM
	a
	
