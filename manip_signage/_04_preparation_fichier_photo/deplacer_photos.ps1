# Chemin vers le dossier principal
$cheminDossier = "C:\Users\chemin du dossier des photos"

# Liste de tous les sous-sous-dossiers
$sousSousDossiers = Get-ChildItem -Path $cheminDossier -Directory -Recurse

# Parcourir chaque sous-sous-dossier
foreach ($sousDossier in $sousSousDossiers) {
    # Déplacer les photos vers le dossier parent du sous-sous-dossier
    $parentSousDossier = $sousDossier.Parent.FullName
    Get-ChildItem -Path $sousDossier.FullName -Filter "*.jpg" | Move-Item -Destination $parentSousDossier
    Get-ChildItem -Path $sousDossier.FullName -Filter "*.png" | Move-Item -Destination $parentSousDossier
}

# Supprimer les sous-dossiers vides
Get-ChildItem -Path $cheminDossier -Directory -Recurse | Where-Object { $_.GetFileSystemInfos().Count -eq 0 } | Remove-Item -Force
