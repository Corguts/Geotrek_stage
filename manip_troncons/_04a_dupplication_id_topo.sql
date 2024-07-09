-- () veut dire besoin ou pas necessairement de changer certaines choses sur la ligne

--DUPPLICATION D'ITINERAIRE A SENTIER


INSERT INTO core_trail (name,topo_object_id,structure_id,category_id)
SELECT 
sb.name, --prendra le nom
sb.topo_object_id, --prendra la géométrie 
sb.structure_id, --prendra à qui appartient cette donnée
3 -- () type d'itinéraire, ici c'est GR de core_trailcategory
FROM trekking_trek sb
WHERE name = 'floirac_daron2'; -- () renseigner le nom exacte de l'itinéraire voulu à la majuscule près entre les simples guillemets

/* il y a besoin de mettre l'identifiant de la catégorie dans sentier
les choix sont les suivants: (ce sont les choix lors de l'écriture du script,il est possible d'en rajouter ou d'en supprimer sur geotrekadmin)
1 Labellisation
2 Entretien régulier
3 GR
4 PR
5 PE
6 VTT

*/



--DUPPLICATION DE SENTIER A ITINERAIRE


INSERT INTO trekking_trek (published,published_fr,published_en,name,name_fr,topo_object_id,structure_id,difficulty_id,practice_id,route_id,accessibility_level_id,reservation_system_id)
SELECT 
FALSE, --si on veut le rendre visible sur geotrek rando, on voit une étoile sur Géotrek qui indique s'il est, si besoin de publié, écrire 'TRUE'
FALSE, --si on veut le rendre visible sur geotrek rando pour la version française
FALSE, --si on veut le rendre visible sur geotrek rando pour la version anglaise
a.name, -- prendra le nom
a.name, --prendra le nom pour la version française
a.topo_object_id, --prendra la géométrie
a.structure_id, --prendra à qui appartient cette donnée
3 as difficulty_id, -- () différents choix de difficulté: 1 très facile    2 facile    3 intermédiaire     4 difficile     5 très difficile
4 as practice_id, -- () différents choix de pratique: 1 VTT    2 Vélo     3 Cheval     4 Pédestre      5 Alpinisme     6 Trail     7 VTTAE
3 as route_id, -- () différents choix de type d'itinéraire: 1 Boucle       2 Aller-retour      3 Traversée 
1 as accessibility_level_id, -- () différents choix de niveau d'accessibilité: 1 débutant     2 expérimenté
1 as reservation_system_id-- () le systeme de réservation qu'un seul pour le moment 1 OpenSystem  qui lui est dans la table common_reservationsystem
FROM core_trail a
WHERE name = 'rixou 1'; -- () renseigner le nom exacte de l'itinéraire voulu à la majuscule près entre les simples guillemets

