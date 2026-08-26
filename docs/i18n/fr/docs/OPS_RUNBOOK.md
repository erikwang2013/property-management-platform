# Manuel d'exploitation (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Applicable à : property-management-platform (côté admin + côté service, PHP 8.3 webman)

## 1. Sauvegarde et restauration de la base de données

Le côté admin et le côté service partagent la même instance MySQL et la même base `property_management`, une seule sauvegarde suffit. Point d'entrée unifié :

| Base | Script de sauvegarde | Description |
|---|---|---|
| `property_management` | `scripts/backup.sh` | Lit la connexion depuis `admin/.env` (surchargable avec `--container=`), mysqldump dans le conteneur par défaut |

Sortie `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, conservation par défaut des 7 derniers jours (`--keep-days=` réglable).

### 1.1 Sauvegarde complète

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 Tâche planifiée (crontab)

```cron
# Sauvegarde complète tous les jours à 02:00
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

Recommandation production : monter le répertoire de sauvegarde sur un disque indépendant/stockage distant, et vérifier régulièrement l'intégrité des fichiers de sauvegarde (`gzip -t`).

### 1.3 Procédure d'exercice de restauration (au moins une fois par trimestre)

1. Choisir la sauvegarde la plus récente : `ls -t backups/backup_*.sql.gz`
2. Exécuter la restauration dans un **environnement indépendant** (ou une base temporaire) : voir [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) scénario A (restauration sur base vide) et scénario B (restauration à un point dans le temps).
3. Vérifications :
   - Comparaison des compteurs de lignes : `SELECT COUNT(*) FROM erik_user;` cohérent avec l'avant-sauvegarde
   - Les champs chiffrés se déchiffrent correctement : consulter un enregistrement avec champs encryptable, valeurs correctes, aucun message d'erreur decrypt dans les journaux
   - Smoke test métier : connexion, appel des interfaces de liste normaux
4. Consigner la durée et le résultat de l'exercice (pour l'évaluation RTO).

> Le manuel d'exercice complet (restauration sur base vide / point dans le temps / validation de cohérence / planning d'exercice de 30 minutes) est dans [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md).

### 1.4 Explications RPO / RTO

- **RPO (perte de données admissible)** : déterminé par la fréquence de sauvegarde. Sauvegarde complète quotidienne → RPO ≤ 24 h, soit au plus un jour de données perdues. Pour un RPO plus petit, augmenter la fréquence (ex. 2 fois/jour) ou activer les sauvegardes incrémentales binlog.
- **RTO (temps de restauration)** : dépend de la taille de la base et de la vitesse de restauration, objectif ≤ 1 h (restauration + validation + redémarrage des services). Mettre à jour la valeur mesurée après chaque exercice.
- En cas d'échec de restauration : d'abord revenir en arrière sur le code applicatif, puis réessayer avec la sauvegarde disponible la plus récente ; si la sauvegarde est corrompue, utiliser une sauvegarde plus ancienne en acceptant un RPO plus grand.

## 2. Gestion des clés

Le projet dépend de 5 clés, toutes dans `.env` (admin et service indépendants, ne pas partager le même jeu) :

| Variable | Longueur | Usage |
|---|---|---|
| `ENCRYPTION_KEY` | 32 octets | Chiffrement de la transmission API (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 octets | Chiffrement des champs sensibles en base (plugin encryptable, **ne pas réutiliser ENCRYPTION_KEY**) |
| `JWT_SECRET_KEY` | 64+ bits | Signature JWT |
| `HASHIDS_SALT` | — | Chiffrement/déchiffrement des ID |
| `HASHIDS_ALT_SALT` | — | Clé de secours du chiffrement des ID |

### 2.1 Génération des clés

```bash
# Sort les 5 KEY=VALUE sur stdout, à ajouter directement au .env
php scripts/gen_env_keys.php

# Écrit directement dans .env : ne remplace pas les clés existantes, n'ajoute que les manquantes
php scripts/gen_env_keys.php --file=.env
```

> Si une clé du .env est encore le placeholder `change-me`, supprimer d'abord la ligne avant d'exécuter (le placeholder est considéré comme « déjà présent », non remplacé).

### 2.2 Rotation des clés (encryptable)

```bash
bash scripts/rotate_keys.sh            # agit par défaut sur le .env du répertoire courant
bash scripts/rotate_keys.sh /path/to/service/.env
```

Le script fait automatiquement : sauvegarde du .env → génération d'une nouvelle `ENCRYPTABLE_KEY` → ajout de l'ancienne clé à `ENCRYPTION_PREVIOUS_KEYS` (séparée par des virgules, la plus récemment tournée en premier) → écriture de la nouvelle clé. Puis manuellement, comme indiqué : redémarrer le service → vérifier le déchiffrement → supprimer la sauvegarde après confirmation.

**Explication de `ENCRYPTION_PREVIOUS_KEYS`** : au déchiffrement, encryptable essaie d'abord la `ENCRYPTABLE_KEY` courante, puis tente les clés historiques dans l'ordre de la liste. Donc **lors de la rotation, l'ancienne clé doit être ajoutée à cette liste avant la mise en service de la nouvelle clé**, sinon les anciennes données ne pourront pas être déchiffrées après le redémarrage (aucune perte de données, un retour arrière sur le .env suffit). La liste ne fait que croître ; avant de supprimer une clé historique, confirmer que toutes les anciennes données ont été rechiffrées.

**Pas de migration automatique des données** : après rotation, les anciennes données restent chiffrées avec l'ancienne clé et restent lisibles/écrivables. Pour réécrire les données existantes avec la nouvelle clé, exécuter séparément une tâche de migration des données (lecture table par table → écriture déclenchant le rechiffrement).

### 2.3 Validation de démarrage Fail-fast

Les configurations suivantes sont validées au démarrage du service ; une clé **manquante ou encore placeholder `change-me`** lève directement une `RuntimeException` refusant le démarrage (pour éviter une mise en ligne avec des clés placeholder) :

| Configuration | Clé validée |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

Exemple d'erreur au démarrage : `ENCRYPTABLE_KEY 未配置或仍为占位符，请在 .env 中配置 32 字节随机密钥`.

**Liste de contrôle des opérations courantes** :

1. Déployer un nouvel environnement : `cp .env.example .env` → supprimer les lignes placeholder `change-me` → `php scripts/gen_env_keys.php --file=.env` → démarrer le service et confirmer l'absence d'erreur de clé.
2. Rotation de routine : selon 2.2, une fois par trimestre suffit (aucun cycle imposé, rotation immédiate en cas de fuite).
3. Les `.env.bak.*` de sauvegarde contiennent les clés en clair, à traiter comme les sauvegardes de base de données (permissions 600, stockage distant).

## 3. Surveillance et alertes (Prometheus + Grafana)

Orchestré dans `admin/docker-compose.yml` (trois services ajoutés : prometheus / grafana / redis-exporter), configurations dans `admin/deploy/monitoring/` :

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# Première connexion Grafana: admin / ${GRAFANA_ADMIN_PASSWORD} (défaut change-me-grafana-password)
```

- **Source de données** : Grafana configure automatiquement la source Prometheus au démarrage (provisioning), les panneaux se créent dans l'UI.
- **Règles d'alerte** : `deploy/monitoring/alerts.yml`, couverture :
  - `AppDown` (application injoignable, équivaut à du 5xx global) — critical
  - `MysqlDown` / `RedisDown` (échec de sonde côté application) — critical
  - `ElasticsearchDown` (échec de collecte native ES `/_prometheus/metrics`) + `ElasticsearchHealthYellow` (cluster non vert) — critical/warning
  - `QueueBacklog` (file scout `queues:scout_*` en accumulation > 100 éléments pendant 10 minutes) — warning
- **Injection du mot de passe ES** : prometheus lit `ELASTIC_PASSWORD` via les `secrets` compose (nécessite Docker Compose ≥ 2.24), aucun mot de passe en dur dans les fichiers de configuration ; sans valeur définie, placeholder change-me, et un 401 de collecte ES déclenche ElasticsearchDown.
- **Rechargement des règles** : après modification d'alerts.yml, `curl -X POST localhost:9090/-/reload` (prometheus doit avoir `--web.enable-lifecycle` ; sans cela, redémarrer le conteneur).
- **Validation locale** : `bash scripts/verify_monitoring.sh` — vérifie la syntaxe YAML des règles d'alerte des deux côtés admin/service, la sortie des métriques `/metrics` des deux extrémités (admin:8787 / service:8788), le chargement des règles Prometheus (9090/9091) ; si l'application/Prometheus ne tourne pas, l'élément correspondant affiche SKIP et sort en exit 0.

**État** : admin et service ont chacun un endpoint `/metrics` (MetricsController, sans authentification). Le middleware MetricsCollector compte réellement selon `code="all"|"5xx"` (admin sort `open_admin_http_requests_total`, service sort `property_service_http_requests_total`), les règles `Http5xxRatio` des deux alerts.yml (ratio 5xx > 5 % pendant 10 minutes) sont directement opérationnelles. **Test réel des alertes à faire au déploiement** : les règles sont prêtes mais n'ont pas encore été déclenchées et vérifiées dans un environnement de déploiement réel (dépend de `verify_monitoring.sh` et de la mise en ligne de Prometheus).

## 4. Rotation des journaux

- **Journaux de conteneurs** : tous les services du compose sont configurés en `json-file` + `max-size 10m / max-file 3`, aucun traitement supplémentaire.
- **Journaux d'application de l'hôte** (`runtime/*.log`、`service/workerman.log`) : utiliser `admin/deploy/logrotate/pmp-app` :

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# Modifier le chemin dans le fichier selon le chemin de déploiement réel ; copytruncate évite le redémarrage de webman
sudo logrotate -d /etc/logrotate.d/pmp-app   # vérification à blanc
```

Rotation quotidienne par défaut, conservation 30 jours, compression gzip.

## 5. Smoke test après déploiement

Après le déploiement, utiliser k6 pour vérifier en smoke test l'accessibilité de la chaîne de connexion et des interfaces métier clés (faible débit, pas un test de charge). Script : `scripts/loadtest/smoke.js` (par défaut 2 VU, 30 s, connexion + dashboard, avec variables d'environnement `BASE_URL`/`VUS`/`DURATION`/`TOKEN` de surcharge).

### 5.1 Smoke test local

```bash
cd /path/to/property-management-platform/scripts/loadtest

# Sonde la chaîne de connexion uniquement (pas de token nécessaire ; 422 code de vérification / 429 limitation = défenses actives, considéré accessible)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# Avec interfaces métier authentifiées : émettre un JWT de test sur le serveur de déploiement (dépend de admin/.env et vendor) puis le passer
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# Concurrence/durée personnalisées
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

Le test de charge complet (login + dashboard + fee, trois scripts) passe toujours par `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`.

### 5.2 Smoke test CI (GitHub Actions déclenché manuellement)

Page Actions du dépôt → **Loadtest Smoke** → **Run workflow** :

| Entrée | Requis | Description |
|---|---|---|
| `target_url` | Oui | Adresse de l'environnement testé, ex. `https://admin.example.com` |
| `duration` | Non | Durée du smoke test, défaut `30s` |
| `token` | Non | JWT de test ; laisser vide pour ne sonder que la chaîne de connexion |

Obtention du token (à exécuter à la racine du dépôt sur le serveur de déploiement, nécessite `admin/.env` et `admin/vendor/`) :

```bash
php scripts/loadtest/mint-token.php
```

> Attention : le token est un JWT dédié au test de charge (compte admin erik par défaut), il apparaîtra en clair dans les journaux du workflow — l'émettre avec un compte dédié au test ; si l'exposition est gênante en production, utiliser le smoke test local 5.1.
