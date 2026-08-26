# Manuel d'exercice de restauration de base de données (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Applicable à : property-management-platform (côté admin + côté service, MySQL 8.0)
> À lire avec la section 1 de [OPS_RUNBOOK.md](OPS_RUNBOOK.md) : génération des sauvegardes, crontab, RPO/RTO sont dans OPS_RUNBOOK ; ce document ne traite que « comment restaurer, comment valider ».

## 0. Objectif

- **Objectif de l'exercice : réaliser un exercice de restauration complet en 30 minutes** (restauration + validation), au moins une fois par trimestre.
- À tout moment, avec la sauvegarde la plus récente, pouvoir restaurer sur une base vide ou à un point dans le temps selon ce document.

Préconditions :

- Fichier de sauvegarde disponible : `scripts/backup.sh` tourne via cron (voir OPS_RUNBOOK 1.2).
- L'environnement cible de restauration (machine d'exercice ou de production) est homologue à la production : même docker-compose, même version MySQL 8.0.
- Avant restauration, confirmer : `gzip -t <fichier de sauvegarde>` passe ; espace disque restant ≥ 2× la taille de la sauvegarde.

## 1. Scénario A : restauration sur base vide (le plus courant, scénario d'exercice par défaut)

Objectif : importer la sauvegarde dans une base vide toute neuve et valider la disponibilité des données.

```bash
cd /path/to/property-management-platform

# 1) Choisir la sauvegarde la plus récente
ls -lt backups/backup_*.sql.gz | head

# 2) Vérification d'intégrité (sinon prendre une sauvegarde plus ancienne)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) Confirmer que le conteneur cible tourne
docker compose -f admin/docker-compose.yml ps mysql

# 4) Créer une base vide (suffixe _drill pour l'exercice, éviter d'écraser la production)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) Import (-T désactive TTY pour le non-interactif ; environ 1-5 minutes)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> Note d'identification : `MYSQL_PWD` reprend `DB_PASSWORD` de `admin/.env` ; en production, interdiction de l'avoir en clair dans l'historique du shell — utiliser `--env-file admin/.env` ou injecter une variable d'environnement. Les exemples de ce manuel sont des valeurs convenues d'environnement d'exercice.

## 2. Scénario B : restauration à un point dans le temps (rejeu binlog)

Prérequis : MySQL 8 active le binlog par défaut (`log_bin=ON`), l'incrément postérieur à la sauvegarde est dans le binlog. La perte de données ≤ dernière sauvegarde + durée de conservation du binlog (défaut `binlog_expire_logs_seconds=2592000`, 30 jours).

Principe : restauration complète → trouver le point de départ du binlog → rejouer avec `mysqlbinlog` jusqu'au point cible.

```bash
# 1) Confirmer que le binlog est activé et lister les fichiers de journal
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) Restauration complète (comme scénario A étapes 4-5, sur base vide)

# 3) Trouver le point de départ du binlog correspondant à la sauvegarde : position consignée dans le fichier (avec --master-data=2)
#    Ce script n'utilise pas --master-data, le point de départ est « l'heure de début de sauvegarde », erreur dans la durée de la sauvegarde.
#    Rejouer le binlog jusqu'au point cible (exemple : restauration au 2026-08-16 10:30:00)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

Points clés :

- Le binlog est dans le conteneur à `/var/lib/mysql/binlog.0000NN`, à faire correspondre avec la sortie de `SHOW BINARY LOGS`.
- Ne rejouer que le binlog « postérieur à l'heure de début de sauvegarde » ; valider immédiatement après le rejeu (voir section 3), confirmer que `max(updated_at)` est conforme.
- Restauration d'une opération erronée à la seconde près : d'abord localiser la requête fautive `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "mot-clé de l'opération fautive"`, puis choisir `--stop-datetime` ou `--stop-position`.

## 3. Validation de la cohérence des données (obligatoire après restauration)

| Élément de contrôle | Commande | Critère de passage |
|---|---|---|
| Intégrité du fichier de sauvegarde | `gzip -t <sauvegarde>` | Aucune erreur |
| Compteurs de lignes des tables clés | `SELECT COUNT(*) FROM erik_admin_user;` | Cohérent avec le compte avant sauvegarde |
| Sondage des tables métier | `SELECT COUNT(*) FROM erik_owner;`、`erik_tenant`、`erik_fee_bill`、`erik_repair_order` | Trois tables ou plus d'ordres de grandeur raisonnables (non nul et cohérent avec l'avant-sauvegarde) |
| Champs chiffrés déchiffrables | Consulter un enregistrement avec champs encryptable (ex. `erik_owner` pièce d'identité/téléphone) | Valeurs correctes, aucune erreur decrypt dans les journaux applicatifs |
| Smoke test métier | Connexion, appel d'une interface de liste chacun | 200 / retour normal |

Exemple de script de sondage (environnement d'exercice) :

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> Cohérence des compteurs : enregistrer la ligne de base avec la même requête SQL avant la sauvegarde, comparer après restauration ; lors de l'exercice, consigner la ligne de base dans le compte-rendu.

## 4. Planning d'exercice de 30 minutes

| Temps | Action | Responsable |
|---|---|---|
| 0-5 min | Choisir la sauvegarde, `gzip -t`, créer la base vide, consigner les compteurs de ligne de base | Ops |
| 5-15 min | Restauration et import du scénario A | Ops |
| 15-25 min | Validation de cohérence de la section 3 + smoke test métier | Ops + Métier |
| 25-30 min | Consigner les résultats, nettoyer la base d'exercice (`DROP DATABASE property_management_drill`), mettre à jour le RTO mesuré dans OPS_RUNBOOK 1.4 | Ops |

## 5. Gestion des échecs

| Symptôme | Traitement |
|---|---|
| `gzip -t` échoue | Sauvegarde corrompue, prendre une sauvegarde plus ancienne, accepter un RPO plus grand, vérifier le cron de sauvegarde |
| Erreur à l'import (charset/permissions) | Vérifier `--default-character-set=utf8mb4` et la cohérence du charset de la base vide ; vérifier que l'utilisateur a le droit de créer des tables |
| Compteurs incohérents avec la ligne de base | Arrêter immédiatement l'exercice, vérifier si la mauvaise base/fichier a été importé ; en scénario de restauration production, continuer l'investigation et revenir en arrière sur l'application |
| Données toujours manquantes après rejeu binlog | Vérifier que `--stop-datetime` est postérieur à l'heure de début de sauvegarde ; confirmer que le rejeu commence au premier binlog après la sauvegarde |

## 6. Modèle de compte-rendu d'exercice

```text
日期: 2026-08-16
恢复目标: 空库（场景 A）/ 时间点（场景 B）
备份文件: backups/backup_20260816_020000.sql.gz
基线行数: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
恢复耗时: XX 分钟    验证耗时: XX 分钟    总计: XX 分钟（目标 ≤ 30）
结果: 通过 / 失败（附失败原因与处理）
```
