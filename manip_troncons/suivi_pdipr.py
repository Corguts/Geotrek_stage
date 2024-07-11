import os
import psycopg2
from dotenv import load_dotenv
from sshtunnel import SSHTunnelForwarder
import pandas as pd
from pandas import ExcelWriter
import geopandas as gpd  # Importer geopandas
import re



# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/chemin du fichier environnement geotrek.env")

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT"))
DB_NAME = os.getenv("DB_NAME")
SSH_HOST = os.getenv("SSH_HOST")
SSH_PORT = int(os.getenv("SSH_PORT"))
SSH_USER = os.getenv("SSH_USER")
SSH_KEY_PATH = os.getenv("SSH_KEY_PATH")

# Connexion à la base de données PostgreSQL à travers SSH
server = SSHTunnelForwarder(
    (SSH_HOST, SSH_PORT),
    ssh_username=SSH_USER,
    ssh_pkey=SSH_KEY_PATH,
    remote_bind_address=(DB_HOST, DB_PORT)
)

# Démarrer le tunnel SSH
server.start()

# Connexion à la base de données PostgreSQL
conn = psycopg2.connect(
    user=DB_USER,
    password=DB_PASSWORD,
    host='localhost',
    port=server.local_bind_port,
    database=DB_NAME
)


# Exécution des requêtes pour récupérer les données
pdipr_query = """
    SELECT p.idpdipr, c.name as commune_name
    FROM geotrek.pdipr p
    JOIN zoning_city c ON ST_Intersects(p.geometry, c.geom)
"""
land_landedge_query = """
    SELECT owner
    FROM land_landedge
    WHERE owner IS NOT NULL
"""

pdipr_df = pd.read_sql_query(pdipr_query, conn)
land_landedge_df = pd.read_sql_query(land_landedge_query, conn)

# Fermer la connexion
conn.close()
server.stop()

# Fonction pour extraire les idpdipr de la colonne owner
def extract_idpdipr_from_owner(owner_str):
    # Utiliser une expression régulière pour extraire l'identifiant
    match = re.search(r'(?<=identifiant:\s)(\w+)', owner_str)
    if match:
        return match.group(0)  # Retourner l'identifiant trouvé
    else:
        return None

# Appliquer la fonction pour extraire les id_pdipr de la colonne owner
land_landedge_df['idpdipr'] = land_landedge_df['owner'].apply(lambda x: extract_idpdipr_from_owner(str(x)))

# Comparer les id_pdipr et ajouter la colonne 'status'
pdipr_df['status'] = pdipr_df['idpdipr'].astype(str).apply(lambda x: 'OK' if x in land_landedge_df['idpdipr'].values else 'Non')

# Supprimer les lignes où idpdipr est nul
pdipr_df.dropna(subset=['idpdipr'], inplace=True)

# Supprimer les doublons d'identifiants
pdipr_df.drop_duplicates(subset=['idpdipr'], inplace=True)

# Sauvegarder le résultat dans un fichier Excel sur le bureau
output_file = os.path.join(os.path.expanduser("~"), "Desktop", "suivi_pdipr_land_landedge.xlsx")
with ExcelWriter(output_file) as writer:
    pdipr_df.to_excel(writer, index=False, sheet_name='Suivi_PDIpr_LandEdge')

print(f"Le fichier Excel a été créé : {output_file}")



'''


# Exécution des requêtes pour récupérer les données
pdipr_query = """
    SELECT p.idpdipr, c.name as commune_name
    FROM geotrek.pdipr p
    JOIN zoning_city c ON ST_Intersects(p.geometry, c.geom)
"""
land_landedge_query = """
    SELECT owner
    FROM land_landedge
    WHERE owner IS NOT NULL
"""

pdipr_df = pd.read_sql_query(pdipr_query, conn)
land_landedge_df = pd.read_sql_query(land_landedge_query, conn)

# Fermer la connexion
conn.close()
server.stop()

# Fonction pour extraire les idpdipr de la colonne owner
def extract_idpdipr_from_owner(owner_str):
    # Utiliser une expression régulière pour extraire l'identifiant
    match = re.search(r'(?<=identifiant:\s)(\w+)', owner_str)
    if match:
        return match.group(0)  # Retourner l'identifiant trouvé
    else:
        return None

# Appliquer la fonction pour extraire les id_pdipr de la colonne owner
land_landedge_df['idpdipr'] = land_landedge_df['owner'].apply(lambda x: extract_idpdipr_from_owner(str(x)))

# Comparer les id_pdipr et ajouter la colonne 'status'
pdipr_df['status'] = pdipr_df['idpdipr'].astype(str).apply(lambda x: 'OK' if x in land_landedge_df['idpdipr'].values else 'Non')

# Supprimer les lignes où idpdipr est nul
pdipr_df.dropna(subset=['idpdipr'], inplace=True)

# Sauvegarder le résultat dans un fichier Excel sur le bureau
output_file = os.path.join(os.path.expanduser("~"), "Desktop", "suivi_pdipr_land_landedge.xlsx")
with ExcelWriter(output_file) as writer:
    pdipr_df.to_excel(writer, index=False, sheet_name='Suivi_PDIpr_LandEdge')

print(f"Le fichier Excel a été créé : {output_file}")


'''
