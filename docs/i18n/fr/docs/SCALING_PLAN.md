# Plan de mise à l'échelle (Scaling Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Le déploiement actuel est un docker-compose mono-machine (MySQL/Redis/Elasticsearch sur la même machine que l'application, voir `admin/docker-compose.yml`), sans HA. Ce document décrit les risques et les atténuations existantes, donne le chemin d'expansion horizontale, les points de déclenchement par volume de données et des recommandations d'exercices. La base d'exploitation (sauvegarde/restauration, surveillance/alertes, rotation des journaux) est dans [OPS_RUNBOOK.md](OPS_RUNBOOK.md).

---

## 1. Déploiement actuel et risques

### 1.1 État actuel

| Composant | Version | Description |
|------|------|------|
| MySQL | 8.0.36 | Instance unique, données persistées dans un volume de l'hôte |
| Redis | 7.2-alpine | Instance unique, cache/queues/verrous |
| Elasticsearch | 8.12.0 | Nœud unique, recherche plein texte scout |
| nginx + webman | — | admin (8787) et service (8788) multi-processus sur la même machine |
| Prometheus + Grafana | — | Surveillance/alertes, même machine |

### 1.2 Liste des risques

| Risque | Impact | Probabilité | Conséquence |
|------|------|------|------|
| Panne unique (un middleware tombe) | Tout le site indisponible | Faible | Élevée |
| Contention disque/mémoire/CPU de l'hôte | Requêtes lentes, ralentissements ES, OOM | Moyenne (augmente avec la croissance des données) | Moyenne |
| MySQL instance unique corrompue irrécupérable | Perte de données | Très faible | Très élevée |
| Pas de site de reprise | Perte totale en cas de sinistre niveau datacenter | Très faible | Très élevée |
| Sauvegarde/restauration non exercée | Dépassement ou échec de la restauration | Moyenne | Élevée |

## 2. Atténuations existantes (déjà en place)

- **Sauvegarde** : script de sauvegarde à entrée unique `scripts/backup.sh` (lit la connexion depuis `admin/.env`, mysqldump dans le conteneur par défaut), sauvegarde complète quotidienne par crontab, conservation par défaut de 7 jours (`--keep-days=30` configurable) ; procédure d'exercice de restauration et explications RPO/RTO dans OPS_RUNBOOK §1 et RECOVERY_RUNBOOK.
- **Surveillance/alertes** : Prometheus + Grafana + `deploy/monitoring/alerts.yml`, couvrant AppDown / MysqlDown / RedisDown / ElasticsearchDown / QueueBacklog, voir OPS_RUNBOOK §3.
- **Rotation des journaux** : journaux de conteneurs `max-size 10m`, logrotate hôte quotidien avec conservation de 30 jours, voir OPS_RUNBOOK §4.
- **Couche application** : webman multi-processus résident, découplage des opérations lentes dans les tâches de queue, contrôle de santé `/health`.

Conclusion : ces atténuations couvrent « récupérable après panne », **pas** « sans interruption de service ». Si l'activité ne tolère pas l'interruption, passer à l'expansion horizontale du §3.

## 3. Chemin d'expansion horizontale (par priorité)

Principe général : d'abord vertical (ajouter CPU/mémoire/disque) puis horizontal (découper les composants), d'abord les middlewares puis l'application, chaque étape est réversible indépendamment.

### 3.1 MySQL maître-esclave + semi-synchrone (première priorité)

- Architecture : maître (instance actuelle) → esclave (nouvelle machine), réplication semi-synchrone activée (`rpl_semi_sync_master_enabled=1`).
- Extension lecture : configurer la séparation lecture/écriture dans l'application (`config/database.php` quand la séparation lecture/écriture est activée ; sinon, commencer par la haute disponibilité maître-esclave seule).
- Migration de sauvegarde : le script de sauvegarde pointe vers l'esclave, pour ne pas charger le maître.
- Version : l'esclave doit être aligné sur la version majeure du maître (actuellement 8.0.36).
- Conditions de mise à niveau : CPU du maître durablement > 70 %, connexions proches de max_connections, explosion du nombre de lignes scannées dans le journal des requêtes lentes.

### 3.2 Redis sentinelle ou cluster (deuxième priorité)

- Sentinel (3 nœuds) : choisir Sentinel quand les besoins en capacité sont faibles, bascule en quelques secondes, le client doit supporter le mode `sentinel`.
- Cluster (≥ 3 maîtres 3 esclaves) : choisir Cluster quand le volume de cache dépasse la mémoire d'une machine, ou quand la concurrence d'écriture augmente.
- Attention : les queues et verrous distribués dépendent de Redis, un changement de topologie impose de modifier `config/redis.php` et de valider le comportement des verrous/queues en cas de bascule.

### 3.3 Nœud Elasticsearch indépendant

- Un ES mono-nœud sans réplica : un index corrompu rend la recherche indisponible. Au minimum, migrer vers une machine indépendante + 1 réplica.
- Quand le volume grandit, découper les index (par domaine métier), désactiver les réplicas des index inutiles pour maîtriser les ressources.
- Conditions de mise à niveau : mémoire de tas > 70 % durable, rejets d'écriture (`es_rejected_executions` en hausse), P95 des requêtes > 1 s.

### 3.4 Multi-réplicas d'application + équilibrage de charge (en dernier)

- 2+ réplicas pour admin/service, nginx en amont en équilibrage de charge (round-robin ou least_conn).
- Précondition : apatride (sessions dans Redis, pas de dépendance d'écriture de fichiers locaux ; ce système en JWT + sessions Redis, globalement satisfait).
- Ensuite, doubler la capacité de traitement par le nombre de réplicas, puis revenir aux goulots des middlewares §3.1–3.3.

## 4. Points de déclenchement par volume de données et recommandations

| Point de déclenchement | Seuil recommandé | Action obligatoire |
|--------|----------|----------|
| Volume total de la base | > 50 Go ou table unique > 50 millions de lignes | Découpage maître-esclave + archivage des factures/journaux historiques |
| Requêtes lentes | > 10 requêtes lentes/jour ou une seule > 2 s | Ajouter des index, partitionner, vérifier les N+1 |
| Connexions MySQL | durablement > 80 % de max_connections | Pool de connexions + maître-esclave |
| Mémoire Redis | > 70 % et en croissance | Purger les clés expirées → Sentinel → Cluster |
| Mémoire de tas ES | > 70 % ou rejets d'écriture | Nœud indépendant + réplicas + découpage d'index |
| CPU | un cœur durablement > 80 % et file de queue qui s'accumule | Multi-réplicas d'application → découpage des middlewares |
| Disque | > 80 % | Nettoyer sauvegardes/journaux, archiver les données froides |

Recommandation : vérifier le tableau ci-dessus une fois par mois (données disponibles depuis les panneaux Grafana) ; tout élément au-dessus du seuil pendant deux semaines consécutives déclenche la mise à l'échelle correspondante.

## 5. Recommandations d'exercices de mise à l'échelle

- **Une fois par trimestre** : exercice de restauration (voir OPS_RUNBOOK §1.3), valider que RPO/RTO sont atteints.
- **Une fois par an** : exercice de bascule maître-esclave (à répéter sur une nouvelle machine, ne pas toucher au maître de production) : créer l'esclave → rattraper → basculer → valider la lecture/écriture des deux côtés → rebasculer.
- **Après la première mise à l'échelle** : utiliser `scripts/loadtest` pour tester les trois parcours (connexion/liste/recherche) et confirmer le P95 (référence : `docs/PERFORMANCE_REPORT_2026-08-16.md`).
- **Journal des exercices** : chaque exercice est consigné dans le journal des changements (CHANGELOG.md), avec : date, élément exercé, résultat, problèmes restants.

## 6. Aide-mémoire du chemin de mise à niveau

```
Mono-machine (état actuel)
  ├─ MySQL maître-esclave semi-synchrone  ← première priorité
  ├─ Redis Sentinel/Cluster               ← deuxième priorité
  ├─ ES nœud indépendant + réplicas        ← troisième priorité
  └─ Multi-réplicas d'application + LB     ← en dernier
        ↓
Déploiement multi-machines (sans point unique, interruption tolérable → interruption de l'ordre de la minute → bascule en secondes)
```

> Au volume d'activité actuel, aucune mise à l'échelle n'est nécessaire ; ce document sert à l'appliquer directement quand « le volume/les exigences de panne changent », sans décision improvisée.
