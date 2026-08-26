# Image de base Python legere
FROM python:3.12-alpine
LABEL author="66045"

WORKDIR /app

# Copie du fichier des dependances et installation
# --no-cache-dir evite de stocker le cache de pip dans l'image
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code source de l'application
COPY . .

# Creation des tables des applications Django integrees (admin, auth, sessions).
# Pas de makemigrations ici : le projet ne definit aucun modele, et on ne genere
# pas de fichiers de migration au moment de construire l'image.
RUN python manage.py migrate

# Port utilise par le serveur de developpement Django
EXPOSE 8000

# Lancement du serveur Django, accessible depuis l'exterieur du conteneur
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
