#importation de signaletique_collector soit par le logiciel  shp2pgpsql auquel

# soit sur qgis avec gestionnaire bd en allant sur postgis la base auquel on est relié puis cliquer sur import de couche/fichier
# on pourra choisir le schéma, et d'autres paramètres associés pour ainsi récupérer le geom

#importation automatiser avec du python avec la clé privé, tunnel ssh et l'équivalent de shp2psql
import os
import geopandas as gpd
import unicodedata
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sshtunnel import SSHTunnelForwarder

# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/mettre votre chemin de votre environnement.en")

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
#le os.getenv permet de faire appel à mes données d'envionnement  et le int permet d'avoir bien des numéros car important pour que ca marche
#on supprime les tables pouvant exister d'avant qui sont tous reliés du coup à la signaletique_collector donc important d'enlever tous
tables_to_drop = ["pdipr", "gr2023", "pe2023", "pr2024", "signaletique_collector"]

allowed_names = ["GR2023", "PE2023", "PR2024","PDIPR", "signaletique_collector"]  #ici j'indique que j'ai besoin que de 4 couches à exporter

def convert_to_lowercase(s):
    """
    Convertit une chaîne en minuscules et remplace les chiffres au début par un underscore.
    """
    if s[0].isdigit():
        s = '_' + s
    if s.upper() in allowed_names:  # Vérifier si le nom original en majuscules est autorisé
        s = s.lower()  # Convertir en minuscules uniquement si le nom est autorisé
    return s


def clean_column_name(col):
    """
    Nettoie le nom d'une colonne en remplaçant les caractères spéciaux par des caractères non accentués ou des underscores.
    """
    # Supprimer les accents et caractères spéciaux
    cleaned_col = ''.join(c for c in unicodedata.normalize('NFD', col) if unicodedata.category(c) != 'Mn')
    # Remplacer les autres caractères spéciaux par des underscores
    cleaned_col = ''.join(c if c.isalnum() else '_' for c in cleaned_col)
    return cleaned_col.lower()

def import_shapefiles(folder, engine):
    """ #utilisation des 3 guillemets pour plusieurs lignes de texte
    Parcourt récursivement les dossiers à partir du dossier spécifié et importe les fichiers Shapefile (.shp)
    dans une base de données PostgreSQL.

    Args:
    - folder: Le chemin du dossier racine à partir duquel parcourir les sous-dossiers pour les fichiers Shapefile.
    - engine: Le moteur SQLAlchemy pour la connexion à la base de données.

    """
    
    for root, dirs, files in os.walk(folder):
        for filename in files:
            if filename.endswith(".shp") and any(name in filename for name in allowed_names):
                # Chemin complet du fichier Shapefile
                shapefile_path = os.path.join(root, filename)

                # Nom de la table PostgreSQL à partir du nom du fichier sans extension
                table_name = os.path.splitext(filename)[0]

                table_name = convert_to_lowercase(table_name)  # Convertir en minuscules et ajuster si nécessaire

                # Charger les données dans le GeoDataFrame
                gdf = gpd.read_file(shapefile_path)

                # Convertir les noms de colonnes en minuscules et nettoyer les caractères spéciaux
                gdf.columns = [clean_column_name(col) for col in gdf.columns]

                # Convertir les noms de colonnes en minuscules
                gdf.rename(columns=str.lower, inplace=True)

                # Insérer les données dans la base de données PostgreSQL avec le schéma spécifié
                gdf.to_postgis(table_name, engine, schema='geotrek', if_exists='replace', index=False, dtype={'geometry': 'Geometry'})

                print(f"Le fichier {filename} a été importé dans la base de données PostgreSQL dans le schéma geotrek.")


# Chemin du dossier local contenant les fichiers Shapefile
root_folder = "C:/Users/chemin des couches shapefiles"

# Configuration du tunnel SSH utilisation de la fonction python pour tunnel ssh avec clé privé
server = SSHTunnelForwarder(
    (SSH_HOST, SSH_PORT),
    ssh_username=SSH_USER,
    ssh_pkey=SSH_KEY_PATH,
    remote_bind_address=(DB_HOST, DB_PORT)
)

# Démarrer le tunnel SSH
server.start()


# Créer le moteur SQLAlchemy pour la connexion à la base de données distante via le tunnel SSH cet étape est en lien pour générer le geom pour chaque entité des couches
engine = create_engine(f"postgresql://{DB_USER}:{DB_PASSWORD}@localhost:{server.local_bind_port}/{DB_NAME}")


# Créer un curseur pour exécuter des requêtes SQL
cur = engine.raw_connection().cursor()

# Supprimer les tables existantes
for table_name in tables_to_drop:
    cur.execute(f"DROP TABLE IF EXISTS geotrek.{table_name}")

# Valider la transaction et fermer le curseur
cur.close()


# Appel de la fonction pour importer les fichiers Shapefile
import_shapefiles(root_folder, engine)

# Arrêter le tunnel SSH
server.stop()



