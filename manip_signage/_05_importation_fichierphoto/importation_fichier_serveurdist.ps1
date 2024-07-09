#en bash
# Chemin vers votre clé privée
$CHEMIN_CLE_PRIVEE = "C:\Users\chemin du fichier de la clé privé"

# Utilisateur et adresse du serveur distant
$UTILISATEUR_SERVEUR="nom d'utilisateur"
$ADRESSE_SERVEUR="adresse IP"

# Chemin vers le dossier sur votre machine locale
$CHEMIN_LOCAL = "C:\Users\chemin du dossier des photos"

# Chemin vers le répertoire cible sur le serveur distant
$CHEMIN_SERVEUR = "/opt/chemin du dossier des photos de la signalétique au serveur à distance/"


# Chemin vers le répertoire cible sur le serveur distant
$CHEMIN_SERVEUR_TMP = "/tmp/"

# Connexion SSH au serveur distant et déplacement du dossier depuis la machine locale vers /tmp/
scp.exe -i $CHEMIN_CLE_PRIVEE -r $CHEMIN_LOCAL "$UTILISATEUR_SERVEUR@$ADRESSE_SERVEUR`:/tmp/"


ssh.exe -i $CHEMIN_CLE_PRIVEE "$UTILISATEUR_SERVEUR@$ADRESSE_SERVEUR" "sudo rm -r $CHEMIN_SERVEUR/data_sign_photo"

# Suppression du dossier data_sign_photo sur le serveur distant
# Connexion SSH au serveur distant et exécution de la commande sudo mv pour déplacer le dossier*

ssh.exe -i $CHEMIN_CLE_PRIVEE "$UTILISATEUR_SERVEUR@$ADRESSE_SERVEUR" "sudo mv /tmp/data_sign_photo $CHEMIN_SERVEUR"    


<#
#on peut aussi supprimer à ce moment là en rajoutant un point virgule a la suite  ; sudo rm -r ($)CHEMIN_SERVEUR/tmp_img_signa"

# le comment de cette facon permet de pas prendre en compte sur du bash



#ou alors la méthode ou je créée les varaible de de fonction
# Commandes pour supprimer le dossier existant et déplacer votre dossier
COMMANDE_SUPPRESSION="sudo rm -r /chemin du dossier a supprimer"
COMMANDE_DEPLACEMENT="sudo mv /chemin de l'emplacement pour déplacer le dossier/"

# Connexion SSH et exécution des commandes sur le serveur distant
ssh -i "$CHEMIN_CLE_PRIVEE" "$UTILISATEUR_SERVEUR@$ADRESSE_SERVEUR" "$COMMANDE_SUPPRESSION && $COMMANDE_DEPLACEMENT"

#essaie de connection juste au serveur à distance
ssh.exe -i $CHEMIN_CLE_PRIVEE "$UTILISATEUR_SERVEUR@$ADRESSE_SERVEUR"



#pour l'importation des dossiers sur le serveur a distance, créer un nouveau dossier sur home du serveur a distance puis importer le dossier dedans
#utiliser sudo mv pour déplacer le dossier dans la racine donc là où on veut,le sudo veut dire super_utilisateur*
#les espaces permettent de faire la coupure,il y a le screenshot de comment visualiser ensuite le dossier en script,objectifs de la prochaine fois supprimer le dossier existant,
#renommer les fichiers des photos dans le dossier pour eviter les soucis avec du python par exemple
sudo mv ~/chemin du dossier ajouté des photos
sudo mv /chemin du dossier photos de la signalétique
#pour supprimer un dossier, aller directement sur le dossier, on fait 
 sudo rm -r tmp_img_signa
# le -r permet de dire que ca se répercute sur tous les dossiers et fichiers à l'intérieur du dossier donné
#ce qu'il faut savoir cd seul va permettre de revenir à l'accueil(home) 
cd
#en rajoutant espace deux points on vient dans la racine,le faire deux fois
cd ..
#en utilisant ls on voit où on est et ce qu'il y a l'intérieur
ls 
#si on veut rejoindre un dossier 
cd geotrek-admin

#pour importer des images ou des dossier sur le serveur à distance ,passer sur filezila ou trouver un script pour créer un nouveau dossier 
#sur le home puis faire mv pour amener le dossier dans la racine
#voici comment est fait le serveur sur ubuntu,montrer les dossiers comme celui des images et où est le dossier des images de geotrek sur paperclip

#>

<# sur le powershell windows, clique droit sur utiliser en tant que administrateur
Set-ExecutionPolicy RemoteSigned    puis valider en mettant O  pour permettre d'executer les scripts powershell comme sur python
Set-ExecutionPolicy Restricted  celui ci va permettre de remettre la securité
#>