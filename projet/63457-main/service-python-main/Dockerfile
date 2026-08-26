# Dockerfile - service-python
FROM python:3.10-slim

# Dossier de travail dans le conteneur
WORKDIR /app

# Copier les fichiers de l'application
COPY . .

# Installer les dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

# Lancer l’application Flask
CMD ["python", "app.py"]
