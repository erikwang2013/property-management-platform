# Guide d'installation

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Ce document vous guide pour déployer le système de gestion immobilière de zéro.

---

## Table des matières

1. [Assistant d'installation Web (recommandé)](#assistant-dinstallation-web-recommandé)
2. [Installation manuelle](#installation-manuelle)
3. [Déploiement Docker](#déploiement-docker)
4. [Compte par défaut](#compte-par-défaut)
5. [Vérification de l'installation](#vérification-de-linstallation)
6. [Questions fréquentes](#questions-fréquentes)

---

## Assistant d'installation Web (recommandé)

Le projet intègre un assistant d'installation Web : une fois le panneau d'administration démarré, toute la configuration se fait depuis le navigateur.

### Étapes d'utilisation

```bash
# 1. Entrer dans le répertoire du panneau d'administration
cd admin

# 2. Créer le fichier de variables d'environnement (copie du modèle)
cp .env.example .env

# 3. Installer les dépendances
composer install --no-dev --optimize-autoloader

# 4. Démarrer le service
php start.php start -d
```

### 5. Ouvrir l'assistant d'installation

Dans le navigateur, accéder à **`http://localhost:8787/install`**, puis suivre les trois étapes :

| Étape | Contenu | Description |
|------|------|------|
| Étape 1 | Configuration de la base de données | Renseigner hôte, port, nom de base, utilisateur, mot de passe |
| Étape 2 | Compte administrateur | Définir le nom d'utilisateur et le mot de passe de connexion (6 caractères minimum) |
| Étape 3 | Confirmation de l'installation | Vérifier les informations, cliquer sur confirmer pour exécuter automatiquement |

Le processus d'installation fait automatiquement :
1. Tester la connexion à la base de données
2. Écrire le fichier de configuration `.env`
3. Importer les 65 tables + les données de seeds de permissions
4. Créer le compte administrateur avec le rôle super administrateur
5. Créer le fichier de verrouillage `public/.installed`

### Après l'installation

- Adresse du panneau d'administration : `http://localhost:8787/admin`
- L'assistant affiche l'adresse de connexion et les informations du compte
- Redémarrage recommandé du service pour appliquer la configuration : `php start.php restart -d`
- Pour réinstaller, supprimer le fichier `public/.installed`

---

## Installation manuelle

### Exigences d'environnement

| Composant | Version requise | Description |
|------|---------|------|
| PHP | 8.1+ (8.3 recommandé) | Extensions pcntl、pdo_mysql、redis、gd、mbstring requises |
| MySQL | 8.0+ | Charset utf8mb4 |
| Redis | 6.0+ | Cache, limitation de débit, Session |
| Composer | 2.x | Gestion des dépendances PHP |
| Elasticsearch | 8.x | Recherche plein texte (optionnel, requêtes en base si désactivé) |
| Flutter SDK | 3.x | Uniquement pour le développement front-end |

### Vérification des extensions PHP

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## Initialisation de la base de données

### 1. Créer la base de données

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. Importer le script d'installation fusionné

```bash
mysql -u root -p management < docs/install.sql
```

`docs/install.sql` contient les 65 tables + les seeds de permissions RBAC, avec `CREATE TABLE IF NOT EXISTS` pour garantir la ré-exécutabilité.

Vérification après exécution :

```bash
mysql -u root -p management -e "SHOW TABLES;" | wc -l
# Doit afficher : 66 (65 tables + 1 ligne d'en-tête)
```

---

## Déploiement du panneau d'administration

Le panneau d'administration tourne sur `http://localhost:8787` et fournit les API du backend d'administration.

```bash
cd admin

# 1. Configurer les variables d'environnement
cp .env.example .env
# Éditer .env : mot de passe de la base, clés JWT, etc.

# 2. Installer les dépendances
composer install --no-dev --optimize-autoloader

# 3. Démarrer le service
php start.php start -d
# -d = arrière-plan ; sans -d, exécution au premier plan pour voir les journaux

# 4. Vérification
curl http://localhost:8787/health
```

### Éléments de configuration clés (admin/.env)

| Configuration | Description | Exigence production |
|--------|------|-------------|
| `JWT_SECRET_KEY` | Clé de signature JWT | Chaîne aléatoire de 64+ caractères |
| `HASHIDS_SALT` | Sel de chiffrement des ID | Chaîne aléatoire, identique à service |
| `SNOWFLAKE_DATACENTER_ID` | ID du datacenter (0-31) | À différencier en déploiement multi-datacenters |
| `SNOWFLAKE_WORKER_ID` | ID du nœud de travail (0-31) | Différent sur chaque machine d'un même datacenter |
| `ENCRYPTION_KEY` | Clé de chiffrement de transmission API | Chaîne aléatoire de 32 octets |
| `ENCRYPTABLE_KEY` | Clé de chiffrement des champs en base | Chaîne aléatoire de 32 octets |
| `DB_PASSWORD` | Mot de passe de la base | Mot de passe fort |

---

## Déploiement du service métier

Le service métier tourne sur `http://localhost:8788` et fournit les API du portail des propriétaires.

```bash
cd service

# 1. Configurer les variables d'environnement
cp .env.example .env
# Éditer .env : mot de passe de la base, clés JWT, etc.

# 2. Installer les dépendances
composer install --no-dev --optimize-autoloader

# 3. Démarrer le service
php start.php start -d

# 4. Vérification
curl http://localhost:8788/health
```

> **Attention :** admin et service partagent la même base de données. `HASHIDS_SALT` doit être identique à celui d'admin, sinon les ID chiffrés générés par admin ne pourront pas être déchiffrés côté service.

---

## Déploiement Docker

### Panneau d'administration

```bash
cd admin
cp .env.docker .env
# Éditer .env pour les clés de production

docker compose up -d
# Inclut : Nginx + PHP + MySQL + Redis + Elasticsearch
```

### Service métier

```bash
cd service
cp .env.docker .env
# Éditer .env pour les clés de production

docker compose up -d
```

### Plan des ports des services

| Service | admin | service | Description |
|------|-------|---------|------|
| Application | 8787 | 8788 | HTTP webman |
| MySQL | 3306 | 3307 | Mapping de port conteneur |
| Redis | 6379 | 6380 | Mapping de port conteneur |
| Elasticsearch | 9200 | 9201 | Mapping de port conteneur |
| Nginx | 80/443 | 80/443 | À décaler au déploiement |

> En déployant les deux docker-compose sur le même hôte, les ports du service sont prédécalés pour éviter les conflits.

---

## Compte par défaut

| Nom d'utilisateur | Mot de passe | Rôle | Description |
|--------|------|------|------|
| admin | admin123 | Super administrateur | Dispose de toutes les permissions |

> **En production, modifier immédiatement le mot de passe par défaut.**

---

## Vérification de l'installation

### 1. Contrôle de santé

```bash
# Panneau d'administration
curl http://localhost:8787/health

# Service métier
curl http://localhost:8788/health
```

### 2. Documentation API

Tous les endpoints API et leurs paramètres sont décrits dans le document dédié [API.md](API.md). Après démarrage du service, la documentation interactive générée automatiquement est aussi accessible :

| Extrémité | Adresse |
|----|------|
| Panneau d'administration | http://localhost:8787/apidoc |
| Service métier | http://localhost:8788/apidoc |

### 3. Test de connexion

```bash
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. Exécution des tests

```bash
# Panneau d'administration
cd admin && php vendor/bin/phpunit

# Service métier
cd service && php vendor/bin/phpunit
```

---

## Questions fréquentes

### Q : Erreur au démarrage `Call to undefined function pcntl_fork()`

L'extension pcntl manque au PHP.

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### Q : « Token invalide » après connexion

Vérifier que les configurations suivantes sont identiques dans les `.env` d'admin et de service :
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### Q : ID chiffrés incohérents entre les deux extrémités

S'assurer que `HASHIDS_SALT` est strictement identique entre admin et service.

### Q : Réseau inaccessible entre conteneurs Docker

Utiliser les noms de conteneurs plutôt que les IP pour les connexions (ex. `DB_HOST=mysql`).

### Q : Comment réinitialiser la base de données

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS management;"
mysql -u root -p -e "CREATE DATABASE management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p management < docs/install.sql
```

### Q : Comment configurer HTTPS

En production, il est recommandé d'utiliser un reverse proxy Nginx pour terminer le TLS. Configuration de référence : `admin/docs/nginx-security.conf`.

---

## Étapes suivantes

- [Document de conception d'architecture](ARCHITECTURE_DESIGN.md) — architecture en couches et chaîne d'exécution des middlewares
- [Documentation API](API.md) — référence complète des interfaces
- [Document de conception fonctionnelle](FEATURE_DESIGN.md) — spécifications des 34 modules
- [Comparaison des versions](EDITIONS.md) — différences Lite / Standard / Full
