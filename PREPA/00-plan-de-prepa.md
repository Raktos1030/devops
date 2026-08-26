# Plan de prépa — Défense 4DOP1DR

## C'est quoi ce dossier ?

Ton kit de révision pour la défense orale du projet DEVOPS. À lire avec **VS Code ouvert sur `projet/`** en parallèle, pour pouvoir cliquer dans le vrai code pendant que tu lis.

**Pas dans le dépôt** : ce dossier est volontairement hors de `projet/`, donc invisible pour le prof et pour git. C'est ton outil perso.

## La règle d'or de la défense

> Le prof peut pointer N'IMPORTE QUELLE ligne de code du dépôt et te demander de l'expliquer. Si tu butes, c'est 0/20 (consigne, remarque 2).

→ Tu dois savoir expliquer **chaque ligne** des fichiers qu'on a écrits nous (les Dockerfile, docker-compose, nginx.conf, .gitlab-ci.yml, terraform/*). Le code des apps (Spring Boot, Django) c'est l'école qui l'a filé, tu n'as pas à le défendre.

## Ordre de lecture conseillé

### Si tu as ~2h dispo (lecture rapide)
1. `01-tour-du-proprietaire.md` — savoir où regarder
2. `02-architecture.md` — comprendre la big picture
3. `XX-questions-defense.md` — les 13 questions du prof avec leurs réponses

### Si tu as 1 journée focus (~6-8h)
Ajoute, dans l'ordre :
4. `03-p1-conteneurisation.md`
5. `04-p2-nginx-local.md`
6. `05-p3-pipeline-ci.md`
7. `06-p4-terraform-azure.md`
8. `07-p5-deploiement-pipeline.md`
9. `08-p6-nginx-azure.md`

### Si tu as 2-3 jours focus (12-15h, recommandé pour viser 14-16/20)
Ajoute :
10. `09-transverses-securite.md`
11. `10-transverses-reseau.md`
12. `11-transverses-azure-secrets.md`
13. `12-commandes-utiles.md`

### Puis (toujours, indépendamment du temps)
- **Relecture finale** de `XX-questions-defense.md`
- **Mock défense** avec moi : tu me demandes « go mock défense », je te pose des questions au hasard, tu réponds, je note tes faiblesses

## Pre-defense checklist (la veille)

- [ ] Docker Desktop : se lance sans erreur
- [ ] `az login` : la session est encore valide (`az account show`)
- [ ] `terraform -version` : OK
- [ ] Cloner le dépôt sur le Mac (le portable de la défense) : `git clone https://git.esi-bru.be/2025-2026/4dop1dr/c112/4dop1-66045.git`
- [ ] Sur Mac, faire un dry-run complet : `docker-compose up --build` → vérifier que les 3 conteneurs locaux démarrent et que `/test` alterne A/B
- [ ] Pour la démo Azure : `terraform apply` → push images via le pipeline → vérifier que les URLs Azure répondent → `terraform destroy` pour libérer les crédits AVANT la défense
- [ ] Prendre 30 min pour relire `XX-questions-defense.md` à voix haute, comme si tu défendais

## Erreurs à éviter à l'oral

1. **Réciter** au lieu de **comprendre** — le prof teste si tu comprends, pas ta mémoire
2. **Mentir sur ce qu'on n'a pas fait** (genre dire qu'on a fait SonarQube si on l'a pas fait) — le prof va vérifier, et là c'est mort
3. **Bloquer sur une question piège** — dis « je ne suis pas sûr, mais d'instinct je dirais X parce que Y » → t'as au moins essayé
4. **Tomber dans l'overthinking** sur une commande basique — un Dockerfile c'est pas de la magie

## Ce que tu dois pouvoir faire LIVE pendant la défense

- Lire un Dockerfile et expliquer chaque ligne
- Lire le `nginx.conf` et expliquer la directive `upstream` + `proxy_pass`
- Lire le `.gitlab-ci.yml` et expliquer stages/jobs/variables
- Lire un fichier `.tf` et expliquer providers/resources/variables
- Lancer `docker-compose up`, `terraform apply`, `terraform destroy` sans hésiter
- Modifier en live un truc demandé par le prof (changer un port, ajouter une variable, etc.) et le faire fonctionner

## Comment utiliser les autres fichiers

Chaque fichier de partie (`03-p1`, `04-p2`...) suit la même structure :
- **Ce que dit la consigne** : rappel du brief
- **Ce qu'on a fait** : les fichiers concernés + ce qu'ils contiennent
- **Ligne par ligne** : décortique du code, avec à chaque concept clé :
  - 🎯 **À retenir** : la phrase à dire à l'oral
  - ⚠️ **Piège potentiel** : la question vicieuse + sa réponse
  - 🔧 **Code** : le chemin du fichier à pointer
- **Mini-récap** : un tableau Q/R en fin de fichier pour réviser en 30 sec

Bonne révision.
