# Évaluation du plan SaaS multi-tenant (Multi-Tenant Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Statut : brouillon d'évaluation (P3-① tâche préalable) | Date : 2026-08-16

## 1. Inventaire de l'état actuel

### 1.1 Classification des structures de tables (65 tables, vérifiées dans docs/install.sql)

| Catégorie | Tables | Description |
|------|-----|------|
| Tables globales/plateforme | management_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、management_system_config、management_operation_log | Authentification, configuration, audit : naturellement au niveau plateforme, non rattachées à un locataire |
| Tables de dimension résidence | management_community et les 40+ tables métier rattachées via community_id (building/unit/room/owner/fee_*/repair_order/parking_*/announcement, etc.) | Rattachement indirect au locataire via community_id |
| Tables d'association de groupe | management_group (groupe)、management_group_community (groupe↔résidence) | Actuellement **association facultative**, sans sémantique de locataire, la synthèse inter-résidences passe par des joins |
| Tables d'extension plateforme | management_notification_template、management_knowledge_base、management_mall_*、management_face_info, etc. | Certaines au niveau plateforme, d'autres au niveau résidence, à confirmer au cas par cas |
| Tables ambiguës | **management_tenant (table des locataires)** | ⚠️ Conflit sémantique : ce sont les « locataires de logement » (dimension room_id/owner_id), **pas** des locataires SaaS |

### 1.2 Chaîne d'authentification (côté admin, vérifié dans le code)

```
Middlewares globaux : Cors → SecurityFilter → RateLimit
Middlewares du groupe de routes : AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` a déjà établi le modèle d'injection dans la requête (`$request->adminId`), le contexte de locataire peut être entièrement répliqué
- `AdminPermission` est un RBAC au niveau plateforme, **orthogonal** à l'isolation des locataires, empilable
- Côté service (portail propriétaires) : le JWT porte owner_id, les données sont naturellement limitées via room_owner → room.community_id, risque inter-locataires faible

### 1.3 Conclusions clés

- Aucun modèle de locataire SaaS existant ; le nom `management_tenant` est déjà pris par les locataires de logement, le nouveau concept doit éviter ce nom
- Tous les contrôleurs font des requêtes Eloquent directes, sans couche repository, sans portée globale — la refonte de l'isolation doit se faire au niveau des modèles
- config/database.php a une connexion unique, mais illuminate/database supporte nativement plusieurs connexions (réserve pour une évolution vers des bases séparées)

## 2. Comparaison des solutions et recommandation

| Solution | Mécanisme | Volume de refonte | Coût d'exploitation | Adaptée à |
|------|------|--------|----------|------|
| **A. Base partagée + isolation par lignes tenant_id (recommandée)** | Table de locataires + colonne tenant_id sur les tables métier + portée globale Eloquent | Moyen (colonne sur 2 tables + middleware + portée globale + remplissage des données existantes) | Faible (sauvegarde/migration d'une seule base inchangées) | PME immobilières, < 5 millions de lignes par locataire |
| B. Bases séparées (une base par locataire) | Routage de connexions + agrégation inter-bases | Élevé (gestion des connexions/rapports inter-bases/migrations×N/sauvegardes×N) | Élevé | Grands groupes, exigences d'isolation réglementaires |
| C. Hybride (bases sensibles séparées + partagée) | Combinaison A+B | Élevé | Élevé | Scénarios à forte isolation : paiement/visage, etc. |

**A recommandée, B comme direction d'évolution.** Raisons :

1. Les 65 tables actuelles sont unifiées dans une base unique ; le modèle de données tenant_id de A n'empêche pas un futur découpage de base (le filtre passe des lignes à la base ; sous A, l'ID de locataire est déjà modélisé globalement)
2. Les données métier sont toutes rattachées via community_id ; tenant_id ne doit être ajouté qu'aux **tables de tête**, les 40 tables métier intermédiaires sont garanties par le chemin d'accès, évitant d'ajouter la colonne table par table
3. Les deux extrémités (admin/service) partagent le même modèle de données, la refonte de A se concentre sur la couche d'exécution côté admin
4. En déploiement mono-machine actuel, la complexité de sauvegarde/migration de B est insoutenable

## 3. Conception des points d'isolation

### 3.1 Modèle de données (ensemble minimal)

- Nouvelle table `management_platform_tenant` (pour éviter le conflit avec la table des locataires management_tenant) : id/name/status/created_at, etc.
- `management_community` + colonne `tenant_id BIGINT NOT NULL DEFAULT 0`, index `(tenant_id, community_id)`
- `management_admin_user` + colonne `tenant_id BIGINT NOT NULL DEFAULT 0` (0 = super administrateur plateforme)
- Les tables métier intermédiaires (building/room/fee_bill, etc., 40 tables) **sans colonne ajoutée**, rattachées via community_id

### 3.2 Le trio de la couche d'exécution

1. **Middleware TenantContext** : le payload JWT gagne la déclaration `tenant_id` → `$request->tenantId` (réplique du modèle d'injection d'AdminAuth) ; liste blanche pour la connexion/installation/les routes plateforme (user/role/permission/config)
2. **Portée globale TenantScope** : portée globale Eloquent sur Community et les modèles métier plateforme, filtrage automatique par `$request->tenantId` ; `find()` est également contraint par la portée, empêchant naturellement les requêtes directes inter-locataires
3. **Contexte explicite Tenant::for()** : les tâches planifiées/queues/imports n'ont pas de requête HTTP, on utilise une fermeture pour spécifier explicitement le locataire ; en l'absence de contexte, **fail-closed** (refus de la requête), pas de passage silencieux sans filtre

### 3.3 Points clés de test anti-franchissement (matrice d'acceptation)

| Cas | Attendu |
|------|------|
| Un admin du locataire A liste les community/building/fee_bill du locataire B | Retour vide ou données A uniquement |
| Un admin du locataire A fait find/update/delete sur un enregistrement du locataire B (requête directe par id) | 403 / données vides / refus |
| L'admin plateforme (tenant_id=0) opère en inter-locataires | Autorisé (capacité plateforme) |
| Un propriétaire service opère en inter-résidences (paiement/réparation) | Refus (validation d'appartenance community) |
| Tâche planifiée/queue sans contexte de locataire | Erreur fail-closed plutôt que requête sans filtre |

## 4. Feuille de route d'évolution (migration par étapes)

| Étape | Contenu | Acceptation |
|------|------|------|
| 1. Couche de données | Créer la table platform_tenant + colonnes sur community/admin_user + migration idempotente + initialisation du locataire par défaut et remplissage des données existantes | Chaque community a obligatoirement un locataire, rapport des données orphelines à zéro |
| 2. Couche d'exécution | Middleware TenantContext + TenantScope + outil Tenant::for() + liste blanche de routes | Régression mono-locataire : les 133 tests passent |
| 3. Modules pilotes | Activer l'isolation d'abord sur : gestion de groupe → résidence → propriétaire → frais (factures) | Matrice de test anti-franchissement validée |
| 4. Déploiement complet | Par lots (lot 1 principal → lot 2 auxiliaire → modules d'extension), module par module | Matrice anti-franchissement validée sur tous les modules |
| 5. Évolution | Évaluer le découpage de base (solution B) quand un locataire dépasse 5 millions de lignes ou exigence réglementaire ; le modèle de données de A ne bloque pas | Évaluation du découpage |

Stratégie de migration des données : toutes les données existantes sont rattachées au « locataire par défaut » (créé par le script de migration), sans suppression ni modification des données métier ; le script de migration est idempotent et ré-exécutable.

## 5. Liste des risques

| Risque | Périmètre d'impact | Atténuation / Retour arrière |
|------|--------|-------------|
| Refonte des chemins de requête des 58+17 contrôleurs | Toutes les interfaces métier | La portée globale couvre ~80 % des listes/détails ; les requêtes brutes et les imports en masse passent par Tenant::for() ; déploiement progressif par lots |
| La portée globale blesse les requêtes niveau plateforme (synthèse inter-résidences du tableau de bord) | Tableau de bord/rapports | Les interfaces plateforme utilisent explicitement Tenant::without() ou la dérivation tenant_id=0 |
| Tâches planifiées/queues sans contexte de requête | Tâches de fond : relance/SLA/notifications, etc. | Encapsulation explicite Tenant::for() + fail-closed |
| Erreur de remplissage des données existantes | Toutes les données existantes | Script idempotent + validation du remplissage + mode à blanc |
| Impact index/performance | Tables à haute fréquence (fee_bill/room/owner) | Index conjoint (tenant_id, community_id) ; réexamen du journal des requêtes lentes |
| Régression des 133 tests | Tout | Après injection de la portée, lancer d'abord la régression complète avant le pilote |
| Confusion de noms (management_tenant locataire vs locataire SaaS) | Cognition des développeurs | Nouvelle table nommée platform_tenant, déclaration explicite dans la documentation |
| **Plan de retour arrière** | — | La portée globale peut être désactivée d'un interrupteur de configuration (retour à la sémantique mono-locataire), les colonnes de données sont conservées sans suppression, aucun changement destructif |

## 6. Conclusion de l'évaluation

**À faire immédiatement** :
- Base partagée + isolation par lignes tenant_id (solution A), nouvelle table `management_platform_tenant`, colonnes sur community/admin_user
- Middleware TenantContext + portée globale TenantScope + outil Tenant::for()
- Ordre du pilote : groupe → résidence → propriétaire → frais
- Dépendance préalable : déjà réalisée — les tables/colonnes/remplissage multi-tenant sont intégrés dans docs/install.sql (fusionné le 2026-08-16, point d'entrée unique de création de base)

**À faire plus tard** :
- Isolation par bases séparées (B) : uniquement si un locataire dépasse 5 millions de lignes ou exigence réglementaire, le modèle de données est déjà réservé
- Solution hybride (C) : à réévaluer si un client exige explicitement une forte isolation (paiement/visage, etc.)

**À ne pas faire** :
- Isolation au niveau schéma (MySQL n'a pas de sémantique de schéma indépendante, coût équivalent à une base séparée)
- Routage multi-bases dynamique (aucun bénéfice en déploiement mono-machine)
- Schéma/champs personnalisés par locataire (YAGNI)
- Réutiliser/adapter la table des locataires management_tenant comme locataire SaaS (conflit sémantique, casse le métier des locataires)
