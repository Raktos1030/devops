# Dockerfile - service-java
FROM maven:3.8.5-openjdk-17 AS build

# Créer un dossier pour l'application
WORKDIR /app

# Copier les fichiers Maven et pom.xml
COPY pom.xml .

# Télécharger les dépendances
RUN mvn dependency:go-offline

# Copier tout le code source
COPY . .

# Compiler l'application
RUN mvn compile

# Étape finale pour exécuter l'application
CMD ["mvn", "spring-boot:run"]
