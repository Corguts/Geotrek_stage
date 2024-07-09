#changement de nom de fichier,ici des images dans plusieurs dossiers d'un même dossier
#sur le terminal pour les extensions python afin de modifier les images
#pip install Pillow

#sur la seance python
import PIL

if 'PIL' in globals() or 'PIL' in locals():
    print("Pillow est installé.")
else:
    print("Pillow n'est pas installé.")

#script pour renommer correctement sans caractères spéciaux et espace en changeant en underscore et création des images dimensionner en 150*150 pour thumbnails 
#et une rotation pour etre à l'endroit
from PIL import Image
import os
import re
#utilisation d'os pour des changements sur mon système et re est utilisée pour effectuer des substitutions de chaînes en utilisant des expressions régulières
def rename_images(directory):
    errors = False
    error_files = []  # Liste pour stocker les chemins des fichiers ayant rencontré des erreurs
    # Parcourir récursivement tous les fichiers et dossiers dans le répertoire principal.os.walk(directory): Cette fonction permet de parcourir récursivement un répertoire et ses sous-répertoires.
    #Elle renvoie un générateur qui produit à chaque itération un tuple contenant le chemin du répertoire parent, une liste des sous-répertoires et une liste des fichiers dans ce répertoire.
    for root, dirs, files in os.walk(directory):
        for filename in files:
            # Vérifier si le fichier est une image (extension courante)
            if filename.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp')):
                # Construire le chemin complet du fichier(de la racine a mon dossier plus rapidement,pareil pour le new)
                old_filepath = os.path.join(root, filename)
                # Supprimer les espaces, les apostrophes, les caractères spéciaux et convertir les majuscules en minuscules dans le nom de fichier
                # le modèle r"[^\w.]" correspond à tout caractère qui n'est ni une lettre, ni un chiffre, ni un point. Nous remplaçons ces caractères par un "_". Cela nous permet de supprimer les caractères spéciaux du nom du fichier.
                #car ne rien mettre ne marche pas , le mieux est de mettre un underscore
                new_filename = re.sub(r"[^\w.]", "_", filename.lower())
                # Construire le nouveau chemin complet du fichier
                new_filepath = os.path.join(root, new_filename)
                try:
                    # Renommer le fichier
                    os.rename(old_filepath, new_filepath)
                    #ici je demande d'afficher le changement ou pas de nom avec une flèche pour indiquer la conversion old pour le début puis new pour le nouveau
                    print(f"Renommage : {old_filepath} -> {new_filepath}")
                # Redimensionner l'image en 150x150
                    with Image.open(new_filepath) as img:
                        img_resized = img.resize((150, 150))
                        new_filepath_resized = os.path.join(root, f"150x150_{new_filename}")
                        
                        # Faire pivoter l'image à droite (sens des aiguilles d'une montre)
                        img_rotated = img_resized.rotate(-90, expand=True)
                        
                        # Enregistrer l'image pivotée
                        img_rotated.save(new_filepath_resized)
                        print(f"Redimensionnement et rotation : {new_filepath} -> {new_filepath_resized}")
                except Exception as e:
                    print(f"Erreur lors du traitement de {old_filepath}: {str(e)}")
                    errors = True
                    error_files.append(old_filepath)

#j'ai demandé en plus de m'afficher les images qui n'ont pas réussi à changer 
    if errors:
        print("\nImages ayant rencontré des erreurs lors du renommage :")
        for file in error_files:
            print(file)

# Spécifier le chemin du dossier principal contenant les fichiers d'images
dossier_principal = r"C:\Users\chemin du dossier des images"

# Appeler la fonction pour renommer les images dans le dossier principal et ses sous-dossiers
rename_images(dossier_principal)




"""""
#autre methode de remplacement avec filename.remplace au lieu de re.sub
 # Remplacer les espaces et les apostrophes du nom de fichier par des underscores
new_filename = filename.replace("'","_").replace("''","_").replace(" ","_")
"""