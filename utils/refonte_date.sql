UPDATE geotrek.signaletique_collector
SET date_clean = 
    CASE 
        WHEN date_crati IS NULL THEN NULL
        ELSE 
            CASE 
                WHEN date_crati ~ '^[0-9]{4}$' THEN CAST(date_crati AS SMALLINT)
				WHEN date_crati ~ '^[0-9]{4}/[0-9]{4}$' THEN CAST(SUBSTRING(date_crati FROM 1 FOR 4) AS SMALLINT) 
                WHEN date_crati ~ '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN CAST(SUBSTRING(date_crati FROM 7 FOR 4) AS SMALLINT)
                WHEN date_crati ~ '^[0-9]{2}_[0-9]{4}$' THEN CAST(SUBSTRING(date_crati FROM 4 FOR 4) AS SMALLINT)
                ELSE NULL
            END
    END
