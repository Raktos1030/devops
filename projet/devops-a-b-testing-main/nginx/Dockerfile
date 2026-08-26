# Image officielle Nginx légère (basée sur Alpine)
FROM nginx:alpine

LABEL author="g66239"

# Copie de notre configuration personnalisée
# Remplace la config par défaut de Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Documentation : Nginx écoute sur le port 80
EXPOSE 80
