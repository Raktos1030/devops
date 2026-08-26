# ============================================
# Dockerfile multi-stage pour l'app Spring Boot (Version A)
# ============================================

# ----- STAGE 1 : Build avec Maven + JDK 21 -----
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copie du pom.xml d'abord (cache des dépendances Maven)
COPY pom.xml .

# Téléchargement des dépendances (cache si pom.xml inchangé)
RUN mvn dependency:go-offline -B

# Copie des sources et build
COPY src ./src
RUN mvn package -DskipTests

# ----- STAGE 2 : Runtime léger avec JRE 21 -----
FROM eclipse-temurin:21-jre

LABEL author="g66239"

WORKDIR /app

# Copie du JAR produit par le stage builder
# Le pom.xml indique : artifactId=abtesting, version=0.0.1-SNAPSHOT
COPY --from=builder /app/target/abtesting-0.0.1-SNAPSHOT.jar /app/app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
