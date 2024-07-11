import os
import subprocess
from dotenv import load_dotenv
from sshtunnel import SSHTunnelForwarder
import psycopg2


# Charger les variables d'environnement à partir du fichier .env
load_dotenv("C:/Users/chemin du fichier environnement de geotrek.env")

# Accéder aux variables d'environnement
SSH_HOST = os.getenv("SSH_HOST")
SSH_PORT = int(os.getenv("SSH_PORT"))
SSH_USER = os.getenv("SSH_USER")
SSH_KEY_PATH = os.getenv("SSH_KEY_PATH")  # Chemin de votre clé privée SSH
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT"))
DB_NAME = os.getenv("DB_NAME")

# Fonction pour établir une connexion SSH
def establish_ssh_connection():
    server = SSHTunnelForwarder(
        (SSH_HOST, SSH_PORT),
        ssh_username=SSH_USER,
        ssh_pkey=SSH_KEY_PATH,
        remote_bind_address=(DB_HOST, DB_PORT)
    )
    server.start()
    return server

# Fonction pour exécuter un script SQL
def execute_sql_script(script_path, server):
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host='localhost',
        port=server.local_bind_port
    )
    cur = conn.cursor()
    with open(script_path, 'r') as f:
        cur.execute(f.read())
    conn.commit()
    cur.close()
    conn.close()

# Fonction pour arrêter la connexion SSH
def close_ssh_connection(server):
    server.stop()

# Fonction pour exécuter un script Python
def execute_python_script(script_path):
    subprocess.run(['python', script_path])


# Fonction pour exécuter un script bash (sh)
def execute_bash_script(script_path):
    subprocess.run(['bash', script_path])

#fonction pour du powershell
def execute_powershell_script(script_path):
    command = ['powershell.exe', '-File', script_path]
    subprocess.run(command)


# Définir les chemins vers les scripts
BASE_DIR = "C:/Users/chemin du dossier de tous les scripts"
etape0 = os.path.join(BASE_DIR,"_01_a_supprimer_dabord","supprimer_test.sql")
etape1 = os.path.join(BASE_DIR,"_01_b_shp_to_psql","shp2pgpsql.py")
etape2 = os.path.join(BASE_DIR,"_02_preparation_donneesgeotrek","_021_refonte_signage_collector.sql")
etape3 = os.path.join(BASE_DIR,"_02_preparation_donneesgeotrek","_022_signage_intersection.sql")
etape4 = os.path.join(BASE_DIR,"_03_importationgeotrek","core_topology.sql")
etape5 = os.path.join(BASE_DIR,"_03_importationgeotrek","signage_signage.sql")
etape6 = os.path.join(BASE_DIR,"_04_preparation_fichier_photo","_1_clean_nommage_photo.py")
etape7 = os.path.join(BASE_DIR,"_04_preparation_fichier_photo","_2_data_sign_photo.py")
etape8 = os.path.join(BASE_DIR,"_05_importation_fichierphoto","importation_chemin_photos.py")
etape9 = os.path.join(BASE_DIR,"_05_importation_fichierphoto","importation_fichier_serveurdist.ps1")
etape10 = os.path.join(BASE_DIR,"_06_lien_chemin_image_thumbnail","easy_thumbnails_thumbnail.sql")
etape11 = os.path.join(BASE_DIR,"_07_liaison_attachment_image","common_attachment.sql")
etape12 = os.path.join(BASE_DIR,"_08_liaison_path_topology","core_pathaggregation.sql")
etape13 = os.path.join(BASE_DIR,"_09_preparation_lame","pre_traitement_lame.sql")
etape14 = os.path.join(BASE_DIR,"_10_importation_lame","signage_blade.sql")
etape15 = os.path.join(BASE_DIR,"_11_preparation_lignes_signage","pre_traitement_lignes.sql")
etape16 = os.path.join(BASE_DIR,"_12_importation_lignes","signage_line.sql")
etape17 = os.path.join(BASE_DIR,"_13_lien_picto","import_linepicto.sql")
etape18 = os.path.join(BASE_DIR,"_14_verification","python_excel.py")
if __name__ == "__main__":
    # Établir une connexion SSH
    ssh_server = establish_ssh_connection()
    
    # Initialiser le compteur des étapes
    total_etapes = 0
    
    # Exécuter les étapes
    etapes_reussies = {}
    etapes_reussies["Étape 0"] = execute_sql_script(etape0, ssh_server)
    total_etapes += 1
    print("Étape 0 terminée.")
    
    etapes_reussies["Étape 1"] = execute_python_script(etape1)
    total_etapes += 1
    print("Étape 1 terminée.")
    
    etapes_reussies["Étape 2"] = execute_sql_script(etape2, ssh_server)
    total_etapes += 1
    print("Étape 2 terminée.")
    
    etapes_reussies["Étape 3"] = execute_sql_script(etape3, ssh_server)
    total_etapes += 1
    print("Étape 3 terminée.")
    
    etapes_reussies["Étape 4"] = execute_sql_script(etape4, ssh_server)
    total_etapes += 1
    print("Étape 4 terminée.")
    
    etapes_reussies["Étape 5"] = execute_sql_script(etape5, ssh_server)
    total_etapes += 1
    print("Étape 5 terminée.")
    
    etapes_reussies["Étape 6"] = execute_python_script(etape6)
    total_etapes += 1
    print("Étape 6 terminée.")

    etapes_reussies["Étape 7"] = execute_python_script(etape7)
    total_etapes += 1
    print("Étape 7 terminée.")
    
    etapes_reussies["Étape 8"] = execute_python_script(etape8)
    total_etapes += 1
    print("Étape 8 terminée.")

    etapes_reussies["Etape 9"] = execute_powershell_script(etape9)
    total_etapes += 1
    print("Étape 9 terminée.")
    
    etapes_reussies["Étape 10"] = execute_sql_script(etape10, ssh_server)
    total_etapes += 1
    print("Étape 10 terminée.")
    
    etapes_reussies["Étape 11"] = execute_sql_script(etape11, ssh_server)
    total_etapes += 1
    print("Étape 11 terminée.")
    
    etapes_reussies["Étape 12"] = execute_sql_script(etape12, ssh_server)
    total_etapes += 1
    print("Étape 12 terminée.")
    
    etapes_reussies["Étape 13"] = execute_sql_script(etape13, ssh_server)
    total_etapes += 1
    print("Étape 13 terminée.")
    
    etapes_reussies["Étape 14"] = execute_sql_script(etape14, ssh_server)
    total_etapes += 1
    print("Étape 14 terminée.")
    
    etapes_reussies["Étape 15"] = execute_sql_script(etape15, ssh_server)
    total_etapes += 1
    print("Étape 15 terminée.")
    
    etapes_reussies["Étape 16"] = execute_sql_script(etape16, ssh_server)
    total_etapes += 1
    print("Étape 16 terminée.")

    etapes_reussies["Étape 17"] = execute_sql_script(etape17, ssh_server)
    total_etapes += 1
    print("Étape 17 terminée.")

    etapes_reussies["Étape 18"] = execute_python_script(etape18)
    total_etapes += 1
    print("Étape 18 terminée.")

    # Vérifier les résultats
    print("\nRésultats des étapes :")
    if all(etapes_reussies.values()):
        print("Toutes les étapes ont été exécutées avec succès !")
    else:
        print("Certaines étapes ont échoué ou se sont arrêtées. Veuillez vérifier les résultats ci-dessus.")
        for etape, reussie in etapes_reussies.items():
            if not reussie:
                print(f"Étape {etape} a échoué.")
    
    # Afficher le nombre total d'étapes lancées
    print(f"Nombre total d'étapes lancées : {total_etapes}")

""""
if __name__ == "__main__":
    # Établir une connexion SSH
    ssh_server = establish_ssh_connection()
    
    # Exécuter les étapes
    etapes_reussies = {}
    etapes_reussies["Etape 0"] = execute_sql_script(etape0, ssh_server)
    print("Étape 0 terminée.")
    
    etapes_reussies["Etape 1"] = execute_python_script(etape1)
    print("Étape 1 terminée.")
    
    etapes_reussies["Etape 2"] = execute_sql_script(etape2, ssh_server)
    print("Étape 2 terminée.")
    
    etapes_reussies["Etape 3"] = execute_sql_script(etape3, ssh_server)
    print("Étape 3 terminée.")
    
    etapes_reussies["Etape 4"] = execute_sql_script(etape4, ssh_server)
    print("Étape 4 terminée.")
    
    etapes_reussies["Etape 5"] = execute_sql_script(etape5, ssh_server)
    print("Étape 5 terminée.")
    
    etapes_reussies["Etape 6"] = execute_python_script(etape6)
    print("Étape 6 terminée.")
    
    etapes_reussies["Etape 7"] = execute_python_script(etape7)
    print("Étape 7 terminée.")
    
    etapes_reussies["Etape 8"] = execute_powershell_script(etape8)
    print("Étape 8 terminée.")
    
    etapes_reussies["Etape 9"] = execute_sql_script(etape9, ssh_server)
    print("Étape 9 terminée.")
    
    etapes_reussies["Etape 10"] = execute_sql_script(etape10, ssh_server)
    print("Étape 10 terminée.")
    
    etapes_reussies["Etape 11"] = execute_sql_script(etape11, ssh_server)
    print("Étape 11 terminée.")
    
    etapes_reussies["Etape 12"] = execute_sql_script(etape12, ssh_server)
    print("Étape 12 terminée.")
    
    etapes_reussies["Etape 13"] = execute_sql_script(etape13, ssh_server)
    print("Étape 13 terminée.")
    
    etapes_reussies["Etape 14"] = execute_sql_script(etape14, ssh_server)
    print("Étape 14 terminée.")
    
    etapes_reussies["Etape 15"] = execute_sql_script(etape15, ssh_server)
    print("Étape 15 terminée.")
    
    etapes_reussies["Etape 16"] = execute_sql_script(etape16, ssh_server)
    print("Étape 16 terminée.")

# Vérifier les résultats
    print("toutes les étapes ont fonctionnées")

   # Vérifier les résultats
    print("\nRésultats des étapes :")
    for etape, reussie in etapes_reussies.items():
        print(f"{etape}: {'Réussie' if reussie else 'Échouée'}")

    # Vérifier si toutes les étapes ont été réussies
    if all(etapes_reussies.values()):
        print("\nToutes les étapes ont été réussies avec succès !")
    else:
        print("\nCertaines étapes ont échoué. Veuillez vérifier les résultats ci-dessus.")

    # Fermer la connexion SSH
    close_ssh_connection(ssh_server)

"""


""" modèles pour executer les differents scripts
# Exécuter le script SQL
subprocess.run(['psql', '-h', 'votre_host', '-p', 'votre_port', '-U', 'votre_utilisateur', '-f', SQL_SCRIPT_PATH])

# Exécuter le script Python
subprocess.run(['python', PYTHON_SCRIPT_PATH])

# Exécuter le script Bash
subprocess.run(['bash', BASH_SCRIPT_PATH])
"""
