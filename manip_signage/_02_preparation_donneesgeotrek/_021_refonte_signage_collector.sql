--préparation pour les dates d'implantation
/* Ajoutez une nouvelle colonne de type SMALLINT pour stocker les années extraites
les dates ne sont pas au bon format et des valeurs sont différentes donc les changer pour la colonne de geotrek
*/
ALTER TABLE geotrek.signaletique_collector
ADD COLUMN date_clean SMALLINT;

-- Mettez à jour la colonne date_clean avec les années extraites
/*explication: donc déjà [0-9] indique les chiffres à récuperer et le {}indique combien il y a, on met les caractrères spéciaux par la suite selon les formats qui existent 
sur le champs date_crati puis on refait la meme chose,ensuite le cast va servir de changer de type de format de varchar a smallint pour geotrek, 
le from...for du substring qui est une sous-chaine, permet de recuperer à quel moment les infos qu'on veut et combien. Après si aucun de ces 4 cas, tu mets NULL 
*/
--comme il faut garder la derniere date , je commence du 6eme caractere et j'en prends4
UPDATE geotrek.signaletique_collector
SET date_clean = 
    CASE 
        WHEN "Date_crati" IS NULL THEN NULL
        ELSE 
            CASE 
                WHEN "Date_crati" ~ '^[0-9]{4}$' THEN CAST("Date_crati" AS SMALLINT)
				WHEN "Date_crati" ~ '^[0-9]{4}/[0-9]{4}$' THEN CAST(SUBSTRING("Date_crati" FROM 6 FOR 4) AS SMALLINT) -- Utilisation de SUBSTRING pour extraire la deuxième année ou  THEN CAST(SPLIT_PART(date_crati, '/', 2) AS SMALLINT)
                WHEN "Date_crati" ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN CAST(SUBSTRING("Date_crati" FROM 7 FOR 4) AS SMALLINT)
                WHEN "Date_crati" ~ '^[0-9]{2}_[0-9]{4}$' THEN CAST(SUBSTRING("Date_crati" FROM 4 FOR 4) AS SMALLINT)
                ELSE NULL
            END
    END;


UPDATE geotrek.signaletique_collector
SET 
    "FLECHE_1" = REPLACE(REPLACE("FLECHE_1", '*', ''), '?', ''),
    "FLECHE_2" = REPLACE(REPLACE("FLECHE_2", '*', ''), '?', ''),
    "FLECHE_3" = REPLACE(REPLACE("FLECHE_3", '*', ''), '?', ''),
    "FLECHE_4" = REPLACE(REPLACE("FLECHE_4", '*', ''), '?', ''),
    "FLECHE_5" = REPLACE(REPLACE("FLECHE_5", '*', ''), '?', '');





