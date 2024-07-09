#structuration des photos selon les poteaux liés
import os
import re
import shutil

# Chemin du dossier contenant les photos
dossier_source = "C:\\Users\\chemin du dossier photo"

# Chemin du nouveau dossier où vous voulez copier les photos
dossier_destination = "C:\\Users\\chemin du deuxieme dossier photo qui sera importer"


# Chemin du dossier principal contenant les fichiers d'images
dossier_principal = r"C:\Users\dossier où se trouve tous les fichiers de données"

# Supprimer le dossier "data_sign_photo" s'il existe
dossier_sign_photo = os.path.join(dossier_principal, "data_sign_photo")
if os.path.exists(dossier_sign_photo):
    try:
        os.rmdir(dossier_sign_photo)
        print("Le dossier 'data_sign_photo' a été supprimé avec succès.")
    except Exception as e:
        print(f"Erreur lors de la suppression du dossier 'data_sign_photo': {str(e)}")

# Créer un nouveau dossier "data_sign_photo"
nouveau_dossier_sign_photo = os.path.join(dossier_principal, "data_sign_photo")
try:
    os.makedirs(nouveau_dossier_sign_photo)
    print("Le nouveau dossier 'data_sign_photo' a été créé avec succès.")
except Exception as e:
    print(f"Erreur lors de la création du nouveau dossier 'data_sign_photo': {str(e)}")


# Parcourir les fichiers dans le dossier source
for dossier_parent, sous_dossiers, fichiers in os.walk(dossier_source):
    for fichier in fichiers:
        chemin_absolu = os.path.join(dossier_parent, fichier)
        relative_path = os.path.relpath(chemin_absolu, dossier_source)

        # Extraire le numéro de poteau du nom du fichier
        match = re.search(r'(\d{1,3})[^0-9]*$', fichier)
        if match:
            code_poteau = int(match.group(1))

            # Créer le dossier correspondant au numéro de poteau s'il n'existe pas déjà
            nouveau_dossier = os.path.join(dossier_destination, str(code_poteau))
            if not os.path.exists(nouveau_dossier):
                os.makedirs(nouveau_dossier)

            # Copier le fichier dans le dossier correspondant
            shutil.copy(chemin_absolu, nouveau_dossier)
            print(f"Le fichier {fichier} a été copié dans {nouveau_dossier}.")