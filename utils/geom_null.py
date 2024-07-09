 #script permettant de verifier si des geom null
import os
import geopandas as gpd

def check_null_geometries(folder):
    """
    Parcourt récursivement les dossiers à partir du dossier spécifié et vérifie s'il y a des géométries nulles
              dans les fichiers Shapefile (.shp).

    Args:
    - folder: Le chemin du dossier racine à partir duquel parcourir les sous-dossiers pour les fichiers Shapefile.

    Returns:
    Aucun.
    """
    allowed_names = ["GR2023", "PE2023", "PR2024", "signaletique_collector"]
    for root, dirs, files in os.walk(folder):
        for filename in files:
            if filename.endswith(".shp") and any(name in filename for name in allowed_names):
                # Chemin complet du fichier Shapefile
                                shapefile_path = os.path.join(root, filename)

                # Charger les données dans le GeoDataFrame
                                gdf = gpd.read_file(shapefile_path)

               # Vérifier s'il y a des géométries nulles
            null_geometries = gdf[gdf['geometry'].isnull()]
            
                # Afficher les fichiers avec des géométries nulles
            if not null_geometries.empty:
                    print(f"Il y a des géométries nulles dans le fichier {filename}.")
            else:
                    print(f"Aucune géométrie nulle dans le fichier {filename}.")

# Chemin du dossier local contenant les fichiers Shapefile
root_folder = "C:/Users/coren/Desktop/signaletique_geotrek/data"

# Appel de la fonction pour vérifier les géométries nulles
check_null_geometries(root_folder)