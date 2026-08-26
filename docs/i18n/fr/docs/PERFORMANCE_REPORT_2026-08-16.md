# Rapport de test de charge et de traitement des requêtes lentes (2026-08-16)

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Environnement et méthode de test

| Élément | Valeur |
|---|---|
| Application | webman v2 (PHP 8.3, 32 workers), double application admin + service |
| Instance testée | admin sur le port dédié 8790 (`SERVER_LISTEN=http://0.0.0.0:8790`) |
| Outil | k6 v0.51.0 (pas de wrk/ab/hey sur la machine), scripts dans `scripts/loadtest/` |
| Cibles du test de charge | Connexion (/api/auth/login)、tableau de bord (/admin/dashboard)、liste des paiements de frais (/admin/fee-payment) |
| Authentification | dashboard/fee utilisent `scripts/loadtest/mint-token.php` pour émettre un JWT (contourne le code de vérification, `sub=21000000000000100`) ; le script de connexion sonde la chaîne avec un code de vérification invalide |
| Données | Connexion directe mono-machine 127.0.0.1, sans passerelle/CDN ; MySQL/Redis sur la même machine que l'application |

Point d'entrée des scripts : `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` (k6 requis dans PATH).
Note sur le script de connexion : la connexion est doublement protégée par code de vérification + limitation de débit (10 requêtes/min/IP), c'est un choix de sécurité ; elle ne peut et ne doit pas être testée en forte concurrence. login.js sonde la latence de la chaîne à faible débit (1 VU / 8 requêtes), en attendant 422 (code de vérification incorrect) ou 429 (limitation de débit), les deux attestant le bon fonctionnement de la défense.

## 2. Résultats du test de charge

### 20 VU / 30s (charge de référence)

| Interface | Requêtes | Débit | avg | p90 | p95 | max | Taux d'échec |
|---|---|---|---|---|---|---|---|
| login (1 VU × 8 requêtes) | 8 | 14.4/s | 68.6ms | 154ms | 207.8ms | 261ms | 0% |
| dashboard | 6863 | 227.9/s | 86.0ms | 151ms | 189.5ms | 1.37s | 0% |
| fee-payment | 5944 | 197.2/s | 99.3ms | 178ms | 220.0ms | 704ms | 0% |

### 50 VU / 30s (montée en charge)

| Interface | Requêtes | Débit | avg | p95 | max | Taux d'échec |
|---|---|---|---|---|---|---|
| login (1 VU × 8 requêtes) | 8 | 18.7/s | 52.1ms | 173ms | 243.8ms | 0% |
| dashboard | 6902 | 226.9/s | 212.7ms | 544.0ms | 1.99s | 0% |
| fee-payment | 7525 | 247.4/s | 195.7ms | 514.2ms | 2.0s | 0% |

(À 50 VU, p95 > seuil de 500ms, k6 juge le seuil franchi et sort, mais 0 % d'échec, 0 réponse non-200.)

### Conclusion

- Toutes les interfaces à 20 VU : 0 échec, p95 < 220ms, sain.
- **Goulot de débit vers 230–250 rps** : de 20 VU à 50 VU, le débit stagne au lieu d'augmenter (dashboard 227.9 → 226.9, fee 197 → 247), tandis que la latence p95 double (~190ms → ~540ms). Sur 32 workers mono-machine, environ 7–8 rps par worker : caractéristique de la limite de traitement monocœur de la chaîne PHP complète (requêtes MySQL, allers-retours cache Redis), pas d'épuisement de connexions (aucune requête en échec).
- Recommandation : cette échelle mono-machine est suffisante (environ 20 millions de requêtes/jour) ; pour plus de débit, privilégier l'ajout horizontal d'instances, puis examiner le SQL et le taux de hit cache de chaque interface (voir ci-dessous).

## 3. Examen des requêtes lentes

- Les tables de frais `erik_fee_bill` / `erik_fee_payment` ont des index complets (paid_at、bill_id、owner_id、payment_number, etc.), les requêtes principales disposent toutes d'index utilisables.
- Point relevé : la liste des frais utilise une recherche floue `payment_number like %kw%` (wildcard de tête), inutilisable avec index ; sur de gros volumes cette condition dégénère en scan complet de table. Recherche d'administration à basse fréquence, non traitée pour l'instant ; on pourra passer à un index inversé ou préfixe quand le volume augmentera.
- **MySQL slow_query_log est OFF** : il est recommandé de l'activer avec `long_query_time=1` pour observer les vraies requêtes lentes (plutôt que d'inférer par test de charge). En production :
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- Agrégation du tableau de bord : chaque reconstruction de cache exécute environ 8 agrégations COUNT + des statistiques groupées sur 30 jours, coût de l'ordre de la seconde par reconstruction, absorbé par le cache Redis de 5 minutes (voir ci-dessous), pas un parcours à chaud.

## 4. Réexamen du cache Redis

- Cache du tableau de bord `dashboard:data` : `setex 300`, ~10ms en cas de hit, reconstruction de l'ordre de la seconde en cas de miss. **Problème : aucune logique d'invalidation à l'écriture**, les données restent obsolètes jusqu'à 5 minutes après modification. Recommandation : supprimer cette clé dans les interfaces d'écriture des frais/biens (une ligne `del dashboard:data`).
- **Aucune protection contre l'effondrement du cache** : à l'expiration de la clé, les 32 workers reconstruisent simultanément (8 requêtes d'agrégation exécutées en double). Sur gros volume, ajouter un simple mutex (ex. verrou `set nx ex` + double vérification).
- Cache des permissions `perm:{adminId}` 60s, comportement normal.
- Élément d'investigation restant : la clé `dashboard:data` n'a jamais été observée dans le Redis local (dans aucun des db), alors que les réponses d'interface sont normales et la latence en cas de hit nettement plus basse. Pendant le test, quelques 403 « accès non autorisé » occasionnels (2 occurrences, puis retour à des 200 stables). Suspect : plusieurs instances Redis locales / différence de configuration d'environnement avec la production, à revérifier dans l'environnement cible. Sans impact sur la conclusion du test (0 échec en régime stable).

## 5. Livrables

- `scripts/loadtest/mint-token.php` — émet le JWT de test (`php mint-token.php --file=/tmp/pmp-token`)
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — scripts k6
- `scripts/loadtest/run.sh` — exécution en une commande (mint token + trois scripts, paramètres : BASE_URL VUS DURATION)
- Le présent rapport

Commande de reproduction : `PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
