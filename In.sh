#!/bin/bash

# Vérifier si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script en tant que root."
  exit 1
fi

# Mettre à jour le système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installer Java
echo "Vérification de l'installation de Java..."
if ! command -v java &> /dev/null; then
  echo "Java n'est pas installé. Installation de Java..."
  apt install openjdk-17-jre -y
else
  echo "Java est déjà installé."
fi

# Créer un répertoire pour le serveur Minecraft
echo "Vérification du répertoire du serveur Minecraft..."
if [ ! -d /opt/minecraft-server ]; then
  echo "Création du répertoire du serveur Minecraft..."
  mkdir -p /opt/minecraft-server
else
  echo "Le répertoire /opt/minecraft-server existe déjà."
fi
cd /opt/minecraft-server

# Télécharger le fichier jar du serveur Minecraft
echo "Téléchargement du serveur Minecraft..."
wget -O server.jar https://launcher.mojang.com/v1/objects/eae3605a3f16f66f659f9e5d9a7f674a76f52c47/server.jar

# Vérifier si le fichier eula.txt existe et l'accepter sinon
if [ ! -f eula.txt ]; then
  echo "Acceptation du EULA..."
  echo "eula=true" > eula.txt
else
  echo "Le fichier eula.txt existe déjà."
fi

# Démarrer initialement le serveur Minecraft pour générer les fichiers de configuration
if [ ! -f server.properties ]; then
  echo "Démarrage initial du serveur Minecraft pour générer les fichiers de configuration..."
  java -Xmx1024M -Xms1024M -jar server.jar nogui
else
  echo "Les fichiers de configuration du serveur Minecraft existent déjà."
fi

# Créer un service systemd pour le serveur Minecraft
echo "Vérification du service systemd pour le serveur Minecraft..."
SERVICE_FILE="/etc/systemd/system/minecraft.service"
if [ ! -f "$SERVICE_FILE" ]; then
  echo "Création d'un service systemd pour le serveur Minecraft..."
  cat <<EOF > /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=root
WorkingDirectory=/opt/minecraft-server
ExecStart=/usr/bin/java -Xmx1024M -Xms1024M -jar /opt/minecraft-server/server.jar nogui
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
else
  echo "Le fichier de service systemd existe déjà."
fi

# Recharger systemd et démarrer le service Minecraft
echo "Rechargement de systemd et démarrage du service Minecraft..."
systemctl daemon-reload
systemctl start minecraft
systemctl enable minecraft

# Afficher le statut du service
echo "Statut du service Minecraft :"
systemctl status minecraft

echo "Installation et configuration du serveur Minecraft terminées."
