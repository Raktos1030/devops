# ============================================
# Dockerfile multi-stage pour l'app Django (Version B)
# ============================================

# ----- STAGE 1 : Build des dépendances Python -----
FROM python:3.12-slim AS builder

WORKDIR /app

# Copie du fichier des dépendances en premier (cache Docker)
COPY requirements.txt .

# Installation des dépendances dans un dossier dédié
# --user installe dans ~/.local pour qu'on puisse copier facilement vers le stage 2
RUN pip install --user --no-cache-dir -r requirements.txt

# ----- STAGE 2 : Image runtime légère -----
FROM python:3.12-slim

LABEL author="g66239"

WORKDIR /app

# Copie des dépendances installées depuis le stage builder
COPY --from=builder /root/.local /root/.local

# Ajoute les binaires Python locaux au PATH
ENV PATH=/root/.local/bin:$PATH

# Copie du code source de l'application
COPY . .

# Préparation Django : migrations
RUN python manage.py makemigrations && \
    python manage.py migrate

# Documentation : Django écoute sur le port 8000
EXPOSE 8000

# Lancement du serveur Django sur toutes les interfaces (0.0.0.0)
# pour qu'il soit accessible depuis l'extérieur du conteneur
ENTRYPOINT ["python", "manage.py", "runserver", "0.0.0.0:8000"]
