import fiona

# Chemin vers le dossier contenant les fichiers Shapefile
dossier_shapefile = "C:/Users/coren/Desktop/signaletique_geotrek/data"

# Liste pour stocker les encodages de chaque fichier SHP
encodages = {}

# Parcours des fichiers Shapefile dans le dossier
for dossier, sous_dossiers, fichiers in os.walk(dossier_shapefile):
    for fichier in fichiers:
        if fichier.endswith(".shp"):
            # Chemin complet du fichier Shapefile
            chemin_shapefile = os.path.join(dossier, fichier)
            
            # Lecture des métadonnées du fichier Shapefile pour obtenir l'encodage
            with fiona.open(chemin_shapefile, encoding='latin1') as shp:
                encodages[chemin_shapefile] = shp.encoding

# Affichage des encodages des fichiers Shapefile
for fichier, encodage in encodages.items():
    print(f"Le fichier {fichier} a l'encodage : {encodage}")
