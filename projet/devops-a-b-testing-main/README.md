# Projet DevOps – A/B Testing

Mise en place d'un test A/B entre deux versions d'une même application web, avec conteneurisation, reverse proxy, pipeline CI/CD et déploiement automatisé.

- **Version A** : Spring Boot (Java 21) – port 8080
- **Version B** : Django (Python 3.12) – port 8000

## Les parties du projet (tags Git)

| Tag | Partie | Description |
|---|---|---|
| `conteneurisation` | 1 | Dockerfiles multi-stage + docker-compose pour les 2 apps |
| `nginx` | 2 | Reverse proxy Nginx avec routing A/B local |
| `pipeline-ci` | 3 | Pipeline GitLab CI : compilation + tests |
| `infrastructure` | 4 | Code Terraform décrivant l'infrastructure Azure |
| `deploiement` | 5 | Pipeline CD : déploiement automatique des apps |
| `nginx-azure` | 6 | Nginx A/B vers les apps déployées en ligne |

## Lancement local (Parties 1 et 2)

```bash
docker compose up --build
```

Routes disponibles via Nginx (port 80) :

| Route | Description |
|---|---|
| http://localhost/test | A/B testing : alterne entre Version A et B |
| http://localhost/spring | Version A directement (Spring Boot) |
| http://localhost/django | Version B directement (Django) |

Arrêt :
```bash
docker compose down
```

## Pipeline CI/CD (Parties 3 et 5)

Le fichier `.gitlab-ci.yml` définit 3 stages :

1. **compile** : compilation de Spring Boot et vérification Django
2. **test** : tests unitaires Spring et Django
3. **deploy** : déploiement automatique des 2 apps via SCP (branche `main` uniquement)

Les secrets (clé SSH, hôte, utilisateur) sont stockés en variables masquées GitLab CI.

## Infrastructure (Partie 4)

Le dossier `terraform/` contient le code décrivant l'infrastructure Azure cible (Resource Group, Container Registry, App Service Plan, 2 App Services).

**Note** : le déploiement réel a été effectué sur AlwaysData en raison d'un problème d'accès au compte Azure (MFA indisponible), possibilité autorisée par les consignes.

## Déploiement en ligne

Les deux versions sont déployées sur AlwaysData :

- Version A (Spring Boot) : https://g66239.alwaysdata.net/spring/
- Version B (Django) : https://g66239.alwaysdata.net/django/

Le proxy A/B (`nginx-azure/`) répartit le trafic entre les deux versions via la directive `split_clients` (répartition 50/50).

## Auteur

Ilter Shakir

