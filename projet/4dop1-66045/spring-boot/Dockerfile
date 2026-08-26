# Etape 1 : compilation et empaquetage avec Maven
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copie du pom.xml et des sources
COPY pom.xml .
COPY src ./src

# Empaquetage de l'application en un fichier .jar
# Les tests seront executes dans le pipeline CI (Partie 3),
# on les saute ici pour accelerer le build de l'image.
RUN mvn clean package -DskipTests

# Etape 2 : image finale legere avec uniquement la JRE
FROM eclipse-temurin:21-jre-alpine
LABEL author="66045"
WORKDIR /app

# Copie du jar depuis l'etape de build
COPY --from=build /app/target/*.jar app.jar

# Port utilise par Spring Boot
EXPOSE 8080

# Lancement de l'application
CMD ["java", "-jar", "/app/app.jar"]
