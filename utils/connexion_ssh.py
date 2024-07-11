inimport os
import geopandas as gpd
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sshtunnel import SSHTunnelForwarder

# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/chemin du fichier environnement de geotrek.env")

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


                # Insérer les données dans la base de données PostgreSQL avec le schéma spécifié
                gdf.to_postgis(table_name, engine, schema='geotrek', if_exists='replace', index=False, dtype={'geometry': 'Geometry'})

                print(f"Le fichier {filename} a été importé dans la base de données PostgreSQL dans le schéma geotrek.")


# Chemin du dossier local contenant les fichiers Shapefile
root_folder = "C:/Users/chemin du dossier data où sont les fichiers des jeux de données"

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

# Appel de la fonction pour importer les fichiers Shapefile
import_shapefiles(root_folder, engine)

# Arrêter le tunnel SSH
server.stop()


