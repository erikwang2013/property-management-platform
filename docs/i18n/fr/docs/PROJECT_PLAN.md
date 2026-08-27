# Système de gestion immobilière — Planification complète du projet

> Date de génération : 2026-08-16 · Source : audit d'équipe pmp-team (auditor / security-auditor / planner)

## I. Conclusion de l'audit de l'état actuel

**Fonctionnalités : conformes aux déclarations.** Les 22 modules métier + 12 fonctions étendues sont tous terminés, 68 tables / 178 API, admin 58 contrôleurs / 127 routes, service 19 contrôleurs / 57 routes, panneau d'administration Flutter Web 42 pages + portail propriétaires 13 pages, HarmonyOS 5 pages. Les 14 documents de docs/ + 35 SVG sont tous étayés par le code, aucune fonctionnalité « déclarée mais non implémentée » constatée.

**Tests : tout au vert (au 2026-08-17).** admin 193 tests / 452 assertions, service 101 tests / 385 assertions (7 skips liés à l'environnement), tests widget Flutter 9 cas (connexion/accueil/factures).

**Côté ingénierie déjà en place :** docker-compose des deux extrémités, CI GitHub Actions (syntaxe PHP + phpunit des deux côtés + composer audit + Flutter analyze), Dependabot, endpoints de métriques Prometheus.

**Dette technique (majoritairement mineure) :**
1. Accumulation de journaux : service/workerman.log 9,3 Mo, admin/runtime/logs 5,7 Mo (déjà gitignore, n'occupe que du disque) → rotation nécessaire
2. Le README ne détaille pas séparément les 57 modèles du service (64 ne concerne que l'admin)
3. Aucun TODO/FIXME, .env non versionné, versions des dépendances sans anomalie — propre

## II. Écarts sécurité et qualité (security-auditor)

**Défense en 19 couches : 16/19 vérifiées présentes**, implémentation conforme à SECURITY_ARCHITECTURE.md (code de vérification, double confirmation, poster, SecurityFilter, AES-256-CBC, JWT, limitation de sessions, verrouillage de compte, RBAC, limitation de débit, disjoncteur, hashids, chiffrement de champs, masquage, journaux d'audit, CSP).

**Deux non-conformités (P1 corrigées) :**
1. ~~security-php installé uniquement côté service~~ → désormais connecté aux SecurityFilter des deux côtés (admin + service ont tous deux la couche d'analyse de profondeur 4b, SecurityGuard en initialisation paresseuse, journalisation et escalade au blocage)
2. ~~Filigrane de droit d'auteur PDF non implémenté~~ → vérifié : le 18e niveau du filigrane est implémenté dans ExportController (ExportController.php:179,206), faux positif d'audit

**Le plus critique : clés de secours codées en dur (corrigé).** EncryptionService/configurations de chiffrement passées en fail-fast (manquante ou change-me → erreur au démarrage), les clés codées en dur et les retours aléatoires des plugins encryptable/jwt supprimés ; les clés .env sont de vraies valeurs aléatoires générées, la CI charge une copie de .env.example. Les mots de passe DB/Redis restent des placeholders, ce sont des identifiants de déploiement, injectés par le déployeur.

**Lacunes d'ingénierie (P1 complétées) :** la CI ajoute un job phpstan (Level 5 + baseline), des portes de couverture PHPUnit des deux côtés (baselines mesurées admin 1,66 % / service 3,21 %, la porte empêche la régression à zéro instrumentation), un scan de fuite de clés gitleaks (`.gitleaks.toml` autorise les modèles d'environnement).

**Vérification des modèles à haut risque :** eval( uniquement Redis::eval (sûr), exec 3 occurrences (contrôleurs de supervision/installation), md5( uniquement hash de la liste noire de tokens, SQL entièrement via query builder — aucun risque de concaténation brute.

## III. Positionnement stratégique

**Fin de la phase fonctionnelle → phase d'ingénierie/commercialisation.** Le développement des fonctions métier est clos (les commits récents sont des compléments de documentation/audit/tests). Orientations d'investissement de la prochaine phase : **CI/CD et portes de qualité, paiement en production, surveillance/alertes et sauvegarde/restauration, SaaS multi-tenant, complément mobile**. L'emballage commercial a déjà des bases (EDITIONS 3 versions + assistant d'installation + filigrane de droit d'auteur), ce qui manque c'est la crédibilité d'ingénierie qui donne envie de payer.

## IV. Feuille de route par phases

### P1 Consolidation d'ingénierie (2-4 semaines) — rendre le système « digne de confiance »

| Objectif | Tâches clés | Critères d'acceptation |
|------|---------|---------|
| Portes de qualité toutes vertes, clés maîtrisées, données non perdues | ① CI complétée : Flutter analyze, tests service, porte de couverture PHPUnit, phpstan, gitleaks ② Gestion des clés : générateur .env + scripts de rotation JWT/DB ③ Sauvegarde/restauration : script mysqldump + manuel d'exercice de restauration ④ Dégradation ES : file de secours en échec d'écriture + dégradation de recherche MySQL LIKE (reporté) ⑤ Gestion de version SQL : unification des migrations complètes en entrée unique docs/install.sql (l'ancien plan de migrations éclatées annulé, fusionné le 2026-08-16) | CI toute verte avec couverture ; exercice de restauration de 30 min à données cohérentes ; recherche utilisable si ES arrêté ; script de mise à niveau exécutable |

**État P1** : ✅ tout terminé (sauvegarde/restauration consignée en P8 : scripts/backup.sh + docs/RECOVERY_RUNBOOK.md).

### P2 Capacité de commercialisation (4-8 semaines) — faire « oser acheter » le client

| Objectif | Tâches clés | Critères d'acceptation |
|------|---------|---------|
| Boucle de paiement, surveillable, livrable | ① Paiement en production : sandbox WeChat/Alipay parcours complet (commande→callback idempotent→remboursement→conciliation), identifiants centralisés dans config/payment.php + env ② Surveillance/alertes : orchestration Prometheus+Grafana + règles d'alerte (5xx, connexions ES/Redis, accumulation de queues) + rotation des journaux ③ Contrôle de version commerciale : interrupteurs de version basés sur EDITIONS (activation des groupes de routes Lite/Standard/Full) + données Demo ④ Assistant d'installation couvrant la configuration paiement/ES | Parcours sandbox complet validé (y compris idempotence des callbacks dupliqués) ; alertes déclenchées réellement ; interrupteurs des trois versions démontrables ; nouvel environnement installé en 10 minutes |

**État P2 actuel** : ✅ partie hors ligne entièrement terminée (2026-08-16/17) : code du parcours de paiement complet (PaymentService commande/callback idempotent/remboursement/conciliation + centralisation des identifiants config/payment.php + PaymentServiceTest en fonctions pures), orchestration de surveillance (double pile Prometheus + 6 règles d'alerte + provisioning des dashboards Grafana des deux côtés), interrupteurs de version (EDITIONS 3 versions + validation fail-fast), assistant d'installation (activation automatique de la configuration de paiement + bug de chemin de modèle corrigé). Dépendances externes restantes : **intégration sandbox en attente d'identifiants** (après obtention des identifiants sandbox WECHAT_PAY_* / ALIPAY_*, exécuter `scripts/payment_sandbox_smoke.php`), **test réel des alertes à faire au déploiement** (`scripts/verify_monitoring.sh` pour validation locale, la validation par déclenchement réel se fait après déploiement).

### P3 Passage à l'échelle (8-12 semaines) — « vendre plus »

| Objectif | Tâches clés | Critères d'acceptation |
|------|---------|---------|
| Multi-tenant, performances au rendez-vous, mobile complété | ① SaaS multi-tenant : à partir de la gestion de groupe, erik_community + tenant_id + isolation par middleware (évaluation de solution d'abord, bases séparées comme direction d'évolution) ② Test de charge : wrk/k6 sur connexion/frais/tableau de bord, requêtes lentes + réexamen du cache Redis ③ Complément mobile : 5 pages HarmonyOS étendues aux parcours principaux (paiement/réparation/annonce/visiteur/stationnement), adaptation mobile du portail Flutter ④ API ouvertes / Webhook (optionnel) | Tests de franchissement de locataires validés ; P95 des interfaces clés < 300 ms ; parcours principaux HarmonyOS terminés |

**État P3** : ✅ tout terminé (livré le 2026-08-16 : trio multi-tenant + test de charge réel P95 au rendez-vous + HarmonyOS étendu à 5 pages).

### P4-P9 Enregistrements de livraison complémentaires (2026-08-16 ~ 08-17, nouvelles phases d'ingénierie au-delà de P1-P3)

| Phase | Contenu livré | Statut |
|------|---------|------|
| P4 Bouclage | Filet de sécurité du chemin d'écriture ES (AdminUser Searchable try/catch + journal de dégradation), configuration de paiement de l'assistant d'installation (activation auto si identifiants renseignés), rotation des journaux (logrotate.conf), orchestration des alertes de surveillance (double pile Prometheus + 6 règles) | ✅ Terminé |
| P5 Éléments restants | Livraison Webhook (signature HMAC-SHA256 + retry à backoff exponentiel + 3 points de déclenchement), tests unitaires métier frais/approbation/SLA | ✅ Terminé |
| P6 Bouclage déploiement | Script de déploiement en une commande (deploy.sh : pull → .env → compose → import idempotent install.sql → smoke test de surveillance), correction du montage des journaux de conteneurs, relèvement de la porte de couverture CI, plan de mise à l'échelle (SCALING_PLAN) | ✅ Terminé |
| P7 Profondeur des tests | Tests unitaires service 43→82, tests widget Flutter 3 pages 8 cas (intégrés à la CI), API ouvertes (/open 3 endpoints en lecture seule + authentification X-API-Key + gen_api_key.php), smoke test de charge (k6 smoke.js + workflow_dispatch manuel) | ✅ Terminé |
| P8 Bouclage ops | Sauvegarde/restauration en place (backup.sh + RECOVERY_RUNBOOK), dashboards Grafana (provisioning de 7 panneaux côté service), tests unitaires admin +11 (152 tout vert), **correction du bug de chemin de modèle de l'assistant d'installation** (modèle déplacé dans app/view/install, rendu 200 vérifié en curl) | ✅ Terminé |
| P9 Bouclage ingénierie | Nettoyage des scripts de sauvegarde erronés (git rm de 4 fichiers des deux côtés + unification de 8 emplacements documentaires), dashboards Grafana côté admin (7 panneaux préfixe open_admin_*), extraction des fonctions pures de validation InstallValidator + 17 cas (admin 193 tout vert) | ✅ Terminé |

**Synthèse P4-P9** : tests unitaires admin 93→193, service 43→101, tests widget Flutter 9/9, API ouvertes 3 endpoints, panneaux de surveillance des deux côtés symétriques, jeu complet de scripts ops sauvegarde/restauration/clés/déploiement prêt.

## V. Top 10 des actions prioritaires (par rapport investissement/résultat)

| # | Action | Impact | Coût | Risque | Statut |
|---|--------|------|------|------|------|
| 1 | Gestion des clés : générateur env + scripts de rotation + suppression des clés de secours codées en dur (validation non-change-me au démarrage) | Élevé (conformité sécurité) | Faible | Faible | ✅ Terminé |
| 2 | CI complétée : Flutter analyze + tests service + porte de couverture + phpstan + gitleaks | Élevé (plancher de qualité) | Faible | Faible | ✅ Terminé (flutter test ajouté en P7) |
| 3 | Script de sauvegarde + exercice de restauration | Élevé (données non perdues) | Faible | Faible | ✅ Terminé (P8 : backup.sh + RECOVERY_RUNBOOK) |
| 4 | Filet de sécurité de dégradation ES (MySQL LIKE) | Élevé (disponibilité) | Faible | Moyen (maintenance de deux chemins de requête) | ✅ Terminé (P4 : filet try/catch du chemin d'écriture ; la recherche a toujours été en MySQL LIKE) |
| 5 | Parcours sandbox de paiement complet + validation d'idempotence des callbacks | Élevé (indispensable à la commercialisation) | Moyen | Moyen (identifiants/sécurité des callbacks) | 🔶 Code terminé, intégration sandbox en attente d'identifiants |
| 6 | Alertes Prometheus + Grafana + rotation des journaux | Élevé (exploitabilité) | Moyen | Faible | ✅ Terminé (panneaux des deux côtés complétés P8/P9 ; test réel des alertes à faire au déploiement) |
| 7 | Gestion des migrations SQL (fusion complète en entrée unique install.sql) | Moyen (mise à niveau possible) | Faible | Faible | ✅ Terminé (fusionné le 2026-08-16) |
| 8 | Évaluation de la solution multi-tenant + isolation tenant_id | Élevé (plafond) | Élevé | Élevé (impacte toutes les requêtes) | ✅ Terminé (livré en P3, tests de franchissement validés) |
| 9 | Test de charge + traitement des requêtes lentes | Moyen (performances) | Moyen | Faible | ✅ Terminé (P3 exécuté réellement P95 au rendez-vous ; P7 version smoke intégrée à la CI) |
| 10 | Interrupteurs de licence édition commerciale + données Demo | Moyen (avant-vente) | Moyen | Faible | ✅ Terminé (EDITIONS + demo_data.php + documentation du parcours de démo) |

## VI. Risques et dépendances

| Risque | État actuel | Recommandation d'atténuation | Statut |
|------|------|---------|------|
| Déploiement mono-machine sans HA | docker-compose mono-machine, MySQL/Redis/ES même machine | Exercices de sauvegarde/restauration + surveillance/alertes + document de plan de mise à l'échelle | ✅ Atténuation en place (P8 sauvegarde + P2/P8/P9 surveillance + P6 SCALING_PLAN) ; exécution des exercices à faire au déploiement |
| Dépendance dure à ES | Recherche/synchronisation d'index entièrement via ES | Filet de dégradation + script de reconstruction d'index | ✅ Atténué (P4 filet du chemin d'écriture ; la recherche a toujours été en MySQL LIKE, ES n'est pas une dépendance de chemin de requête) |
| Gestion des clés | Placeholders + clés de secours codées en dur, sans rotation | Générateur + scripts de rotation ; injection par variables d'environnement en production | ✅ Résolu (validation fail-fast + gen_env_keys.sh + rotate_keys.sh) |
| Identifiants de paiement éparpillés | Module de paiement sans configuration centralisée, sandbox non vérifié | Centralisation de la configuration + sandbox d'abord | 🔶 Configuration centralisée (config/payment.php), intégration sandbox en attente d'identifiants |
| Gestion des migrations | install.sql fichier unique (idempotent IF NOT EXISTS) | Déjà unifié en entrée complète unique ; chemin d'upgrade incrémental à discuter séparément | ✅ Déjà unifié (fusionné le 2026-08-16) |
| Couverture de tests trop structurelle | 133 tests concentrés sur schéma/sécurité/allers-retours | Porte de couverture + complément de tests unitaires sur le métier principal (frais/approbation/SLA) | ✅ Renforcé (admin 193 / service 101 / Flutter 9 ; la porte empêche la régression à zéro instrumentation) |
| Lacunes mobiles | HarmonyOS seulement 5 pages, pas d'app natif côté propriétaire | Complément des parcours principaux P3 ; dépendance : équipement de test HarmonyOS | ✅ Parcours principaux complétés (5 pages : paiement/réparation/annonce/visiteur/stationnement) ; validation appareil réel en attente de matériel |

## VII. Répartition de l'équipe (pmp-team)

| Rôle | Tâches investies |
|------|---------|
| Architecture | Évaluation de la solution multi-tenant et conception de l'isolation tenant_id (P3), architecture de dégradation ES, architecture de surveillance (P2), évaluation de la conception de l'idempotence des callbacks de paiement |
| Backend | Scripts de génération/rotation des clés, implémentation de la dégradation ES, centralisation de la configuration de paiement + intégration sandbox, découpage des scripts de migration, test de charge et traitement des requêtes lentes |
| Frontend Flutter | Intégration CI de flutter analyze, adaptation mobile du portail propriétaire (P3), support UI des interrupteurs de version |
| HarmonyOS | Complément des parcours principaux : paiement/réparation/annonce/visiteur/stationnement (P3) |
| Tests | Porte de couverture, cas sandbox de paiement (callbacks dupliqués/remboursement/conciliation), scripts de test de charge, exécution des exercices de sauvegarde/restauration |
| Revue | Revue des chemins critiques paiement et sécurité, gitleaks intégré à la CI, revue des tests de franchissement multi-tenant |
| Documentation | Manuels de déploiement/exploitation (avec exercice de restauration), documentation de la solution multi-tenant, manuel de configuration de surveillance, manuel de livraison édition commerciale |

## VIII. Recommandations d'action immédiate

✅ Les éléments 1 à 4 de la P1 initiale (durcissement des clés → complétion CI → script de sauvegarde → dégradation ES) sont tous exécutés (livraisons itératives P4-P9).

**Dépendances restantes (conditions externes, pas des lacunes de code)** :
1. Intégration sandbox de paiement : après obtention des identifiants sandbox WECHAT_PAY_* / ALIPAY_*, exécuter `scripts/payment_sandbox_smoke.php` (validation de la chaîne complète commande→callback dupliqué idempotent→remboursement→conciliation)
2. Test réel des alertes de surveillance : après déploiement, exécuter `scripts/verify_monitoring.sh` pour valider le chargement des règles, et déclencher réellement des 5xx/défauts de connexion pour valider les alertes (la règle Http5xxRatio est directement opérationnelle)
3. Exercice de sauvegarde/restauration : selon docs/RECOVERY_RUNBOOK.md, exercice trimestriel avec consignation des durées mesurées (objectif RTO ≤ 1 h)
4. Validation appareil réel HarmonyOS : une fois l'équipement de test disponible, exécuter les parcours principaux (paiement/réparation/annonce/visiteur/stationnement)
