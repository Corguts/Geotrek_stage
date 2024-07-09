import os
import geopandas as gpd
from dotenv import load_dotenv
from sqlalchemy import create_engine

# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/coren/Desktop/signaletique_geotrek/environnement/local.env")

# Accéder aux variables d'environnement
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

# Etablir la connexion à la base de données
engine = create_engine(f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

def import_shapefiles(folder, engine):
    """
    Parcourt récursivement les dossiers à partir du dossier spécifié et importe les fichiers Shapefile (.shp)
    dans une base de données PostgreSQL.

    Args:
    - folder: Le chemin du dossier racine à partir duquel parcourir les sous-dossiers pour les fichiers Shapefile.
    - engine: Le moteur SQLAlchemy pour la connexion à la base de données.

    """
    allowed_names = ["GR2023", "PE2023", "PR2024", "signaletique_collector"]
    for root, dirs, files in os.walk(folder):
        for filename in files:
            if filename.endswith(".shp") and any(name in filename for name in allowed_names):
                # Chemin complet du fichier Shapefile
                shapefile_path = os.path.join(root, filename)

                # Nom de la table PostgreSQL à partir du nom du fichier sans extension
                table_name = os.path.splitext(filename)[0]

                # Charger les données dans le GeoDataFrame
                gdf = gpd.read_file(shapefile_path)

                # Insérer les données dans la base de données PostgreSQL
                gdf.to_postgis(table_name, engine, if_exists='replace', index=False, dtype={'geometry': 'Geometry'})

                print(f"Le fichier {filename} a été importé dans la base de données PostgreSQL.")

# Chemin du dossier local contenant les fichiers Shapefile
root_folder = "C:/Users/coren/Desktop/signaletique_geotrek/data"

# Appel de la fonction pour importer les fichiers Shapefile
import_shapefiles(root_folder, engine)
