import os
import psycopg2
from dotenv import load_dotenv
from sshtunnel import SSHTunnelForwarder
import pandas as pd
from pandas import ExcelWriter

# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/chemin du fichier d'environnement")

DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT"))
DB_NAME = os.getenv("DB_NAME")
SSH_HOST = os.getenv("SSH_HOST")
SSH_PORT = int(os.getenv("SSH_PORT"))
SSH_USER = os.getenv("SSH_USER")
SSH_KEY_PATH = os.getenv("SSH_KEY_PATH")

# Définir la fonction pour compter récursivement le nombre de fichiers dans un répertoire
def count_photos_in_directory(directory):
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.lower().endswith(('.jpg', '.jpeg', '.png')):
                count += 1
    return count

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
    host=SSH_HOST,  # Utiliser l'adresse IP de la machine distante SSH
    port=DB_PORT,  # Utiliser le port du tunnel SSH
    database=DB_NAME
)

# Récupération du nombre de lignes avec des valeurs dans la colonne "photo" de la table "geotrek.signaletique_collector"
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM geotrek.signaletique_collector WHERE photo IS NOT NULL")
nombre_lignes_avec_photos = cur.fetchone()[0]

#on peut se permettre un pourcentage de perte de 1% donc c'est parfait juste deux soucis car je demandes de chercher dans la colonne date ,
#or il manque des poteaux qui ont des photos mais pas de date donc c'est normal 
#et l'autre souci et juste que c'est poteau doublon en code que j'ai créé et donc on ne sait pas quelle photo appartient a ce nouveau point qui sont donc mal renommer,pas fiable a 100%(95% est suffisant)

# Compter le nombre de lignes dans geotrek.image_collector
cur.execute("SELECT COUNT(*) FROM geotrek.image_collector")
nombre_photos_output = cur.fetchone()[0]

# Récupération du nombre de poteaux au début de chaque table
cur.execute("SELECT COUNT(*) FROM geotrek.signaletique_collector")
signaletique_collector_count = cur.fetchone()[0]

# Récupération du nombre de poteaux dans la table signage_signage
cur.execute("SELECT COUNT(*) FROM public.signage_signage")
signage_signage_count = cur.fetchone()[0]

# Exécution de la requête SQL pour récupérer les numéros de poteau sans photos et leurs codes
cur.execute("""
    SELECT pa.topo_object_id, pa.code
    FROM public.signage_signage AS pa
    LEFT JOIN public.common_attachment AS ca ON pa.topo_object_id = ca.object_id
    WHERE ca.object_id IS NULL
""")
poteaux_sans_photos = cur.fetchall()

# Convertir les résultats en listes séparées pour les numéros de poteau et les codes
numeros_poteaux_sans_photos = [row[0] for row in poteaux_sans_photos]
codes_poteaux_sans_photos = [row[1] for row in poteaux_sans_photos]

# Exécution de la requête SQL pour compter le nombre de poteaux avec des photos
cur.execute("""
SELECT COUNT(DISTINCT pa.topo_object_id) AS nombre_de_poteaux_avec_photos
    FROM public.common_attachment AS ca
    INNER JOIN signage_signage AS pa ON ca.object_id = pa.topo_object_id
""")
nombre_poteaux_avec_photos = cur.fetchone()[0]

# Récupération des signaletiques avec des photos
cur.execute("""
    SELECT sc."N_Poteau", sc."photo"
    FROM geotrek.signaletique_collector AS sc
    WHERE photo IS NOT NULL
""")
signaletiques_avec_photos = cur.fetchall()


# Récupération du nombre de lames
cur = conn.cursor()
cur.execute("""
SELECT "N_Poteau", COUNT(*) AS nombre_de_lames
    FROM geotrek.signaletique_collector
    WHERE "FLECHE_1" IS NOT NULL OR "FLECHE_2" IS NOT NULL OR "FLECHE_3" IS NOT NULL OR "FLECHE_4" IS NOT NULL OR "FLECHE_5" IS NOT NULL
    GROUP BY "N_Poteau"
""")
nombre_lames = cur.fetchall()

# Convertir les résultats en dictionnaire pour faciliter l'ajout à DataFrame
dict_lames = dict(nombre_lames)

# Récupération du nombre total de lames dans la table public.signage_blade
cur = conn.cursor()
cur.execute("SELECT COUNT(*) FROM public.signage_blade")
nombre_lame_output = cur.fetchone()[0]

# Récupération du nombre total de lames
cur.execute("""
SELECT SUM((
    CASE WHEN "FLECHE_1" IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN "FLECHE_2" IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN "FLECHE_3" IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN "FLECHE_4" IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN "FLECHE_5" IS NOT NULL THEN 1 ELSE 0 END
)) AS total_lames
FROM geotrek.signaletique_collector
""")
total_lames = cur.fetchone()[0]

# Récupération des lignes avec distance_topo = 0
cur.execute("""
    SELECT "N_Poteau"
    FROM geotrek.signage_intersection
    WHERE distance_topo = 0
""")
zero_distance_lignes = cur.fetchall()

# Fermeture du curseur et de la connexion
cur.close()
conn.close()
server.stop()

# Chemin vers le dossier principal
main_directory = "C:/Users/chemin du dossier principal dans le serveur à distance/"

# Compter le nombre total de photos dans le dossier principal et ses sous-dossiers
nombre_photos_total = count_photos_in_directory(main_directory)

# Création du DataFrame pour les poteaux sans photos
df_poteaux_sans_photos = pd.DataFrame(poteaux_sans_photos, columns=['topo_object_id', 'code'])

# Création du DataFrame pour les lignes avec distance_topo = 0
df_zero_distance_lignes = pd.DataFrame(zero_distance_lignes, columns=['N_Poteau'])

# Création du DataFrame
data = {
    'signaletique_input': [signaletique_collector_count],
    'signaletique_output': [signage_signage_count],
    'signage_photo_input': [nombre_lignes_avec_photos],
    'signage_photo_output': [nombre_poteaux_avec_photos],
    'nombre_photos_input': [nombre_photos_total],
    'nombre_photos_output':[nombre_photos_output],
    'nombre_lames_input': [total_lames],
    'nombre_lame_output': [nombre_lame_output]
}

# Trouver la longueur maximale parmi les listes de données
max_length = max(len(v) for v in data.values())

# Ajouter des listes vides pour les colonnes qui ont moins d'éléments
for key, value in data.items():
    data[key] += [None] * (max_length - len(value))

# Création du DataFrame à partir du dictionnaire de données
df = pd.DataFrame(data)

# Chemin vers le fichier Excel existant
excel_path = "C:/Users/chemin vers l'excel déjà existant.xlsx"

# Export vers Excel sur le bureau
df.to_excel(excel_path, index=False)

# ---------------------------------------------------------------------

# Connexion à la base de données PostgreSQL
conn = psycopg2.connect(
    user=DB_USER,
    password=DB_PASSWORD,
    host=SSH_HOST,  # Utiliser l'adresse IP de la machine distante SSH
    port=DB_PORT,  # Utiliser le port du tunnel SSH
    database=DB_NAME
)

# Récupération des signaletiques avec des photos
cur = conn.cursor()
cur.execute("""
    SELECT sc."N_Poteau", sc."photo"
    FROM geotrek.signaletique_collector AS sc
    WHERE photo IS NOT NULL
""")
signaletiques_avec_photos = cur.fetchall()

# Récupération des codes_poteau de image_collector
cur.execute("""
    SELECT ic."code_poteau"
    FROM geotrek.image_collector AS ic
""")
codes_poteau_image_collector = [row[0] for row in cur.fetchall()]

# Fermeture du curseur
cur.close()

# Convertir les résultats en DataFrame pandas
df_signaletiques_avec_photos = pd.DataFrame(signaletiques_avec_photos, columns=['N_Poteau', 'Photo'])

# Identifier les signaletiques avec des photos mais dont le code_poteau n'est pas retrouvé dans image_collector
signaletiques_absentes_image_collector = df_signaletiques_avec_photos[~df_signaletiques_avec_photos['N_Poteau'].isin(codes_poteau_image_collector)]




#partie création d'autres feuilles sur l'excel de travail


# Créer un ExcelWriter pour écrire dans le fichier Excel existant
with ExcelWriter(excel_path, mode='a', engine='openpyxl') as writer:

    # Ajouter le DataFrame du deuxième script à une deuxième feuille, identifier les points avec photos mais qui n'ont pas de photo sur geotrek
    signaletiques_absentes_image_collector.to_excel(writer, sheet_name='Signaletiques_Absentes_geotrek', index=False)

    # Ajouter le DataFrame des signaletiques sans photos à une nouvelle feuille, les points sans photos
    df_poteaux_sans_photos.to_excel(writer, sheet_name='Signaletiques_Sans_Photos', index=False)
    
    # Ajouter le DataFrame des lignes avec distance_topo = 0 à une nouvelle feuille,les points n'ont pas bougés
    df_zero_distance_lignes.to_excel(writer, sheet_name='Zero_Distance_Lignes', index=False)





#partie application de couleur pour savoir si bonne concordance ou pas
from openpyxl import load_workbook
from openpyxl.styles import PatternFill

# Chemin vers le fichier Excel existant
excel_path = "C:chemin vers le fichier excel existant.xlsx"

# Charger le fichier Excel existant
wb = load_workbook(excel_path)
ws = wb.active



# Parcourir les cellules et appliquer la couleur en fonction de la condition,vert égalité,rouge  taux d'erreur au dessus de 5% et orange marge d'erreur acceptable jusqu'a 5%
for row in ws.iter_rows(min_row=2, max_row=2, min_col=1, max_col=ws.max_column):
    for i in range(0, len(row), 2):  # Parcourir par paires de colonnes input-output
        input_cell = row[i]
        output_cell = row[i + 1]
        if input_cell.value == output_cell.value:
            input_cell.fill = PatternFill(start_color="00FF00", end_color="00FF00", fill_type="solid")  # Vert
            output_cell.fill = PatternFill(start_color="00FF00", end_color="00FF00", fill_type="solid")  # Vert
        else:
            input_value = input_cell.value
            output_value = output_cell.value
            if output_value >= 0.95 * input_value and output_value <= 1.05 * input_value:
                input_cell.fill = PatternFill(start_color="FFA500", end_color="FFA500", fill_type="solid")  # Orange
                output_cell.fill = PatternFill(start_color="FFA500", end_color="FFA500", fill_type="solid")  # Orange
            else:
                input_cell.fill = PatternFill(start_color="FF0000", end_color="FF0000", fill_type="solid")  # Rouge
                output_cell.fill = PatternFill(start_color="FF0000", end_color="FF0000", fill_type="solid")  # Rouge



""""

# Parcourir les cellules et appliquer la couleur en fonction de la condition
for row in ws.iter_rows(min_row=2, max_row=2, min_col=1, max_col=ws.max_column):
    for i in range(0, len(row), 2):  # Parcourir par paires de colonnes input-output
        input_cell = row[i]
        output_cell = row[i + 1]
        if input_cell.value == output_cell.value:
            input_cell.fill = PatternFill(start_color="00FF00", end_color="00FF00", fill_type="solid")  # Vert
            output_cell.fill = PatternFill(start_color="00FF00", end_color="00FF00", fill_type="solid")  # Vert
        else:
            input_cell.fill = PatternFill(start_color="FF0000", end_color="FF0000", fill_type="solid")  # Rouge
            output_cell.fill = PatternFill(start_color="FF0000", end_color="FF0000", fill_type="solid")  # Rouge
"""
# Enregistrer les modifications
wb.save(excel_path)
