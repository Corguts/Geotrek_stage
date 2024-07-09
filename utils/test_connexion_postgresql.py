# ceci est pour tester la connexion aux bases postgres sql par un essai oui ou non ca a marché

import os
import psycopg2
from dotenv import load_dotenv

def connect_to_database():
    try:
        # Charger les variables d'environnement à partir du fichier .env
        load_dotenv("C:/Users/coren/Desktop/signaletique_geotrek/environnement/geotrek.env")

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
        print("Connexion réussie !")
        
        # Retourner la connexion et le curseur
        return conn, conn.cursor()
    
    except psycopg2.Error as e:
        print("Erreur lors de la connexion à PostgreSQL:", e)
        # Retourner None si la connexion échoue
        return None, None

# Appel de la fonction pour se connecter à la base de données
conn, cur = connect_to_database()

# Si la connexion est établie avec succès, vous pouvez exécuter des opérations sur la base de données
if conn:
    # Fermer le curseur et la connexion
    cur.close()
    conn.close()
    print("Déconnexion réussie !")


#e est une variable qui stocke l'exception levée. Cela permet de récupérer des informations sur l'exception, 
#telles que son type ou son message, et de les utiliser pour afficher des informations de débogage ou gérer l'erreur d'une manière appropriée.



