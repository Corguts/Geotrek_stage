
import os
import psycopg2
from dotenv import load_dotenv
from sshtunnel import SSHTunnelForwarder
import pandas as pd
from pandas import ExcelWriter
import geopandas as gpd  # Importer geopandas

# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/coren/Desktop/stage_geotrek/signaletique_geotrek/environnement/geotrek.env")

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
    host='localhost',  # Utiliser localhost car le tunnel SSH redirige vers localhost
    port=server.local_bind_port,  # Utiliser le port local du tunnel SSH
    database=DB_NAME
)

# Créer un curseur
cur = conn.cursor()

# Exécution de la requête SQL pour compter le nombre total de lignes selon la condition spécifiée
query_total_pdipr = """
SELECT 
    COUNT(*)
FROM (
    SELECT DISTINCT topo_object_id
    FROM geotrek.prepa_pdipr
) AS subquery;
"""


cur.execute(query_total_pdipr)
total_pdipr_count = cur.fetchone()[0]
print("Nombre total de lignes selon le critère spécifié dans geotrek.pdipr:", total_pdipr_count)

# Exécution de la requête SQL pour compter le nombre de lignes dans la table land_landedge
query_land_landedge_count = "SELECT COUNT(*) FROM land_landedge"
cur.execute(query_land_landedge_count)
land_landedge_count = cur.fetchone()[0]
print("Nombre de lignes dans land_landedge:", land_landedge_count)

# Fermeture du curseur
cur.close()

# Fermeture de la connexion et arrêt du tunnel SSH
conn.close()
server.stop()