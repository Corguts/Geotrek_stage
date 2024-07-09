import os
from dotenv import load_dotenv

# Charger les variables d'environnement à partir du fichier .env
load_dotenv(C:/Users/coren/Desktop/signaletique_geotrek/environnement/geotrek.env)

# Accéder aux variables d'environnement
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")

# Etablir la connexion à la base de données
conn = psycopg2.connect(
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT
)

# Créer un curseur pour exécuter des requêtes SQL
cur = conn.cursor()

# Fermer le curseur et la connexion
cur.close()
conn.close()

#l'idée est de ne pas réécrire à chaque fois les codes et nom pour se connecter a la base
#de cette facon aussi il sera facile de bloqué les données sensibles env