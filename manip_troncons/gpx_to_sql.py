import os
import geopandas as gpd
import unicodedata
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sshtunnel import SSHTunnelForwarder

# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/coren/Desktop/stage_geotrek/signaletique_geotrek/environnement/geotrek.env")

# Accéder aux variables d'environnement
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT"))
DB_NAME = os.getenv("DB_NAME")
SSH_HOST = os.getenv("SSH_HOST")
SSH_PORT = int(os.getenv("SSH_PORT"))
SSH_USER = os.getenv("SSH_USER")
SSH_KEY_PATH = os.getenv("SSH_KEY_PATH")

def convert_to_lowercase(s):
    """
    Convertit une chaîne en minuscules et remplace les chiffres au début par un underscore.
    """
    if s[0].isdigit():
        s = '_' + s
    return s.lower()

def clean_column_name(col):
    """
    Nettoie le nom d'une colonne en remplaçant les caractères spéciaux par des caractères non accentués ou des underscores.
    """
    # Supprimer les accents et caractères spéciaux
    cleaned_col = ''.join(c for c in unicodedata.normalize('NFD', col) if unicodedata.category(c) != 'Mn')
    # Remplacer les autres caractères spéciaux par des underscores
    cleaned_col = ''.join(c if c.isalnum() else '_' for c in cleaned_col)
    return cleaned_col.lower()

def import_gpx_files(folder, engine):
    """
    Parcourt récursivement les dossiers à partir du dossier spécifié et importe les fichiers GPX
    dans une base de données PostgreSQL.

    Args:
    - folder: Le chemin du dossier racine à partir duquel parcourir les sous-dossiers pour les fichiers GPX.
    - engine: Le moteur SQLAlchemy pour la connexion à la base de données.
    """
    
    for root, dirs, files in os.walk(folder):
        for filename in files:
            if filename.endswith(".gpx"):
                # Chemin complet du fichier GPX
                gpx_file_path = os.path.join(root, filename)

                # Nom de la table PostgreSQL à partir du nom du fichier sans extension
                table_name = os.path.splitext(filename)[0]

                table_name = convert_to_lowercase(table_name)  # Convertir en minuscules et ajuster si nécessaire

                # Charger les données dans le GeoDataFrame
                gdf = gpd.read_file(gpx_file_path, layer='tracks')  # Lisez la couche 'tracks' du fichier GPX

                # Convertir les noms de colonnes en minuscules et nettoyer les caractères spéciaux
                gdf.columns = [clean_column_name(col) for col in gdf.columns]

                # Convertir les noms de colonnes en minuscules
                gdf.rename(columns=str.lower, inplace=True)

                # Insérer les données dans la base de données PostgreSQL avec le schéma spécifié
                gdf.to_postgis(table_name, engine, schema='geotrek', if_exists='replace', index=False, dtype={'geometry': 'Geometry'})

                print(f"Le fichier {filename} a été importé dans la base de données PostgreSQL dans le schéma geotrek.")

# Chemin du dossier local contenant les fichiers GPX
root_folder = "C:/Users/coren/Desktop/stage_geotrek/signaletique_geotrek/data/GPX_GR"

# Configuration du tunnel SSH
server = SSHTunnelForwarder(
    (SSH_HOST, SSH_PORT),
    ssh_username=SSH_USER,
    ssh_pkey=SSH_KEY_PATH,
    remote_bind_address=(DB_HOST, DB_PORT)
)

# Démarrer le tunnel SSH
server.start()

# Créer le moteur SQLAlchemy pour la connexion à la base de données distante via le tunnel SSH
engine = create_engine(f"postgresql://{DB_USER}:{DB_PASSWORD}@localhost:{server.local_bind_port}/{DB_NAME}")

# Appel de la fonction pour importer les fichiers GPX
import_gpx_files(root_folder, engine)

# Arrêter le tunnel SSH
server.stop()



