#vrai script , réussi
import os
import psycopg2
# psycopg2 permet de se connecter à une base de données PostgreSQL, d'exécuter des requêtes SQL, de récupérer des résultats et bien plus encore. Il fournit une interface Python
from dotenv import load_dotenv
from sshtunnel import SSHTunnelForwarder
import re
#Cette bibliothèque fournit des fonctions pour travailler avec des expressions régulières. Elle est utilisée ici pour extraire les numéros de poteaux à partir des chemins de fichier.
import geopandas as gpd

# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/coren/Desktop/signaletique_geotrek/environnement/geotrek.env")

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
def list_paths_last_digits(path, base_path):
    """
    Parcourt récursivement les dossiers à partir du dossier spécifié et récupère les chemins relatifs des fichiers
    ainsi que les numéros de poteaux correspondants.

    Args:
    - path: Le chemin du dossier racine à partir duquel parcourir les sous-dossiers pour les fichiers.
    - base_path: Le chemin de base relatif utilisé pour extraire les numéros de poteaux.

    Returns:
    - paths: Liste des chemins relatifs des fichiers.
    - codes_poteau: Liste des numéros de poteaux correspondants.
    """
    paths = []
    codes_poteau = []   # Liste pour stocker les numéros de poteaux

    for root, dirs, files in os.walk(path):
         #La fonction os.walk() parcourt récursivement un répertoire et retourne un générateur fournissant des tuples contenant le chemin du répertoire racine, 
        #une liste des sous-répertoires et une liste des fichiers dans le répertoire.
        for file in files:
            # Chemin complet du fichier
            full_path = os.path.relpath(os.path.join(root, file), path)
            #Cette fonction retourne un chemin relatif entre deux chemins. Elle prend en paramètre deux chemins et retourne le chemin relatif du premier par rapport au second.
            # Chemin relatif par rapport au chemin de base
            relative_path = os.path.join(base_path, full_path.replace("\\", "/"))
            #Cette fonction concatène plusieurs chemins pour former un seul chemin. Elle prend en paramètre une liste de chemins et les concatène avec le séparateur de chemin approprié 
            #pour le système d'exploitation.
            # Utilisation de regex pour extraire les numéros de poteaux à partir du chemin
            match = re.search(r'(\d{1,3})[^0-9]*$', relative_path)
            # C'est une expression régulière utilisée pour rechercher des numéros de poteaux à la fin d'un chemin. Cette expression recherche un groupe de un à trois chiffres (\d{1,3}) 
            if match:
                code_poteau = int(match.group(1))
                paths.append(relative_path)
                codes_poteau.append(code_poteau)

    return paths, codes_poteau

# Connexion à la base de données PostgreSQL à travers SSH
server = SSHTunnelForwarder(
    (SSH_HOST, SSH_PORT),
    ssh_username=SSH_USER,
    ssh_pkey=SSH_KEY_PATH,
    remote_bind_address=(DB_HOST, DB_PORT)
)

# Démarrer le tunnel SSH
server.start()

#Cette fonction prend comme arguments un chemin de base et un chemin relatif.
#Elle parcourt les fichiers locaux à l'intérieur du répertoire spécifié par path.
#Pour chaque fichier, elle construit le chemin relatif par rapport au chemin de base.
#Elle utilise une expression régulière pour extraire les 1, 2 ou 3 derniers chiffres du chemin relatif, qui sont supposés être les numéros de poteaux.
#Elle stocke les chemins relatifs et les numéros de poteaux correspondants dans deux listes distinctes.
# Créer une connexion à la base de données distante PostgreSQL


# Connexion à la base de données PostgreSQL
conn = psycopg2.connect(
    user=DB_USER,
    password=DB_PASSWORD,
    host=SSH_HOST,  # Utiliser l'adresse IP de la machine distante SSH
    port=DB_PORT,  # Utiliser le port du tunnel SSH
    database=DB_NAME
)

# Créer un curseur pour exécuter des requêtes SQL
cur = conn.cursor()

# Supprimer la table existante si elle existe déjà
cur.execute("DROP TABLE IF EXISTS geotrek.image_collector")

# Chemin du dossier local contenant les images
dossier_local = "C:/Users/coren/Desktop/signaletique_geotrek/data/data_sign_photo/"

# Chemin de base relatif dans le schéma Geotrek
chemin_base = "paperclip/signage_signage/data_sign_photo/"

# Création de la table image_collector
cur.execute("CREATE TABLE IF NOT EXISTS geotrek.image_collector (id SERIAL PRIMARY KEY, chemin VARCHAR, code_poteau INTEGER,source_id INTEGER)")

# Liste des chemins locaux avec les numéros de poteaux
chemins, codes_poteau = list_paths_last_digits(dossier_local, chemin_base)

# Insertion des chemins et des numéros de poteaux dans la base de données
for chemin, code_poteau in zip(chemins, codes_poteau):
    cur.execute("INSERT INTO geotrek.image_collector (chemin, code_poteau) VALUES (%s, %s)", (chemin, code_poteau))
 #marqueur de paramètre de substitution utilisé dans les requêtes SQL pour indiquer où les valeurs de paramètres doivent être insérées. Lors de l'exécution de la requête, 
#les valeurs de paramètres sont passées en tant que tuple en deuxième argument de la méthode execute()


# Validation de la transaction
conn.commit()
print("Insertion réussie !")

# Fermer le curseur et la connexion
cur.close()
conn.close()
print("Déconnexion réussie !")

# Arrêter le tunnel SSH
server.stop()

