# Documentation fonctionnelle (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Liste des fonctionnalités

| N° | Module | Lot | Panneau d'administration | Portail des propriétaires | Tables |
|------|------|---------|---------|--------|--------|
| 1 | Gestion des résidences | Lot 1 | CRUD + recherche paginée | Consultation liée à la résidence | management_community |
| 2 | Gestion des bâtiments | Lot 1 | CRUD + filtre par résidence | - | management_building |
| 3 | Gestion des unités | Lot 1 | CRUD + filtre par bâtiment | - | management_unit |
| 4 | Gestion des types de logement | Lot 1 | CRUD | - | management_room_type |
| 5 | Gestion des biens immobiliers | Lot 1 | CRUD + arborescence des logements + liaison en masse des propriétaires | Liste/détail de mes biens | management_room |
| 6 | Gestion des propriétaires | Lot 1 | CRUD + import en masse/activation-désactivation/suppression | Inscription/connexion/informations personnelles | management_owner, management_room_owner |
| 7 | Gestion des locataires | Lot 1 | CRUD + filtre par bien | - | management_tenant |
| 8 | Gestion des frais | Lot 1 | CRUD des types de frais + gestion des factures + génération en masse + encaissement hors ligne | Consultation des factures + paiement en ligne + statistiques des frais | management_fee_type, management_fee_bill, management_fee_payment |
| 9 | Gestion des demandes de réparation | Lot 1 | Liste des demandes + affectation + mise à jour de la progression | Soumettre une demande + consulter la progression + évaluer | management_repair_order, management_repair_progress |
| 10 | Annonces et notifications | Lot 1 | CRUD + publication/épinglage | Liste/détail des annonces | management_announcement |
| 11 | Gestion du stationnement | Lot 2 | Gestion des places/véhicules + historique de stationnement | Mes places/véhicules + historique | management_parking_space, management_parking_vehicle, management_parking_record |
| 12 | Gestion des équipements | Lot 2 | Registre des équipements + historique de maintenance | - | management_equipment, management_equipment_maintenance |
| 13 | Réclamations et suggestions | Lot 2 | Liste des réclamations + traitement + suivi | Soumettre une réclamation + consulter la progression + évaluer | management_complaint |
| 14 | Gestion des visiteurs | Lot 2 | Approbation des visiteurs + consultation des enregistrements | Réservation de visiteur + code de passage | management_visitor |
| 15 | Gestion des contrats | Lot 2 | CRUD + gestion des statuts | - | management_contract |
| 16 | Gestion financière | Lot 2 | Gestion des recettes/dépenses + rapports statistiques | - | management_finance_income, management_finance_expense |
| 17 | Patrouille de sécurité | Lot 3 | Itinéraires de patrouille + enregistrements de patrouille | - | management_security_patrol, management_patrol_record |
| 18 | Gestion du nettoyage | Lot 3 | Zones de nettoyage + enregistrements de nettoyage | - | management_cleaning_area, management_cleaning_record |
| 19 | Gestion des espaces verts | Lot 3 | Zones vertes + enregistrements d'entretien | - | management_green_area, management_green_maintenance |
| 20 | Activités communautaires | Lot 3 | Gestion des activités + consultation des inscriptions | Liste des activités + inscription | management_community_activity, management_activity_signup |
| 21 | Gestion de la consommation d'énergie | Lot 3 | Gestion des compteurs + relevés | - | management_energy_meter, management_energy_record |
| 22 | Gestion des employés | Lot 3 | CRUD + gestion des statuts | - | management_staff |

## Fonctions étendues (Lot 4 — 12 modules)

| N° | Module | Panneau d'administration | Portail des propriétaires | Tables |
|------|------|---------|--------|--------|
| 23 | Notifications | CRUD des modèles + envoi manuel + liste | Mes messages + marquer comme lu | management_notification_template, management_notification |
| 24 | Workflow d'approbation | Types d'approbation + instances + progression des étapes | - | management_approval_type, management_approval, management_approval_record |
| 25 | Intégration de paiement | Gestion des commandes + remboursement + callbacks WeChat/Alipay | - | management_payment_order |
| 26 | Vote des propriétaires | CRUD des votes + options + statistiques pondérées par surface | Liste des votes + vote + pondération par surface | management_vote, management_vote_option, management_vote_record |
| 27 | Escalade automatique SLA | Configuration des règles + contrôle des délais + pénalités | - | management_sla_rule, management_sla_record |
| 28 | Relance intelligente | Configuration des stratégies + correspondance des retards + pénalités | - | management_collection_strategy, management_collection_record |
| 29 | Application mobile d'inspection | Attribution des tâches + pointage GPS + photos | - | management_inspection_task, management_inspection_checkpoint |
| 30 | Boutique communautaire | Gestion des catégories/produits/commandes/expéditions | Parcourir les produits + commander + mes commandes | management_mall_category, management_mall_product, management_mall_order |
| 31 | Reconnaissance faciale | Gestion des validations | Enregistrement du visage + statut d'authentification | management_face_info |
| 32 | Gestion de groupe | CRUD des groupes + association de résidences + synthèse inter-résidences | - | management_group, management_group_community |
| 33 | Q&A intelligent | Base de connaissances + historique des conversations + statistiques | Poser une question + correspondance par mots-clés | management_knowledge_base, management_chat_record |
| - | Grand écran de données | Visualisation en temps réel plein écran des données immobilières | - | (réutilise les interfaces de données existantes) |

## Modules du panneau d'administration (admin existant)

| Module | Fonctions |
|------|------|
| Tableau de bord | Statistiques en temps réel/tendances/répartition/journaux (cache Redis 5 min) |
| Gestion des utilisateurs | CRUD des administrateurs + suppression en masse/activation-désactivation + import Excel |
| Rôles et permissions | CRUD + arborescence des permissions + autorisation RBAC method.path |
| Configuration système | CRUD clé-valeur |
| Audit des opérations | Consultation des journaux + détection automatique des 8 sources de plateforme |
| Gestion des fichiers | Téléversement + export Excel/PDF (masquage des données sensibles) |
| Gestion de la sécurité | 18 couches de défense en profondeur + security.txt |
| Supervision des opérations | Contrôle de santé + métriques Prometheus + documentation API |
| Internationalisation | Bilingue chinois/anglais : PHP symfony/translation + Flutter GetX Translations + qualificatifs de ressources HarmonyOS |
| Documentation API | Générée automatiquement par `hg/apidoc`, admin 10 groupes + service 9 groupes, organisée par module fonctionnel |

## Fonctionnalités transverses

### Chiffrement des ID en transmission
Les champs ID de toutes les requêtes et réponses API sont encodés/décodés avec `erikwang2013/hashids`. Le client reçoit des chaînes hashid (ex. `aB3xK9mW2pQ7rT5v`), le backend les décode en BIGINT pour les opérations.

### Protection des données sensibles
- Couche de transmission API : `erikwang2013/encryption` — AES-256-CBC
- Couche de stockage en base : `erikwang2013/encryptable` — chiffrement/déchiffrement automatique via les casts Eloquent Model
- Couche d'affichage front-end : téléphone 138****1234, e-mail a***@e.com

### Audit des opérations
Toutes les opérations POST/PUT/DELETE du panneau d'administration sont enregistrées automatiquement, incluant l'utilisateur, l'IP, le chemin, les paramètres (masqués), l'heure de l'opération et la source (web/ios/android/harmonyos/windows/macos/linux/ipados).

### Contrôle des permissions
- Panneau d'administration : autorisation RBAC au niveau method.path, le super administrateur `*` contourne la vérification
- Portail des propriétaires : authentification JWT Bearer Token, le propriétaire ne peut opérer que sur ses propres données

### Protection de sécurité
18 couches de défense en profondeur : code de vérification → confirmation du mot de passe → vérification aléatoire → analyse de sécurité → interception des attaques → chiffrement du transport → JWT → contrôle des sessions → verrouillage du compte → RBAC → limitation de débit → protection des ID → chiffrement des requêtes → chiffrement du stockage → masquage à l'affichage → audit → CSP → filigrane de droit d'auteur

### Fonctionnalités d'export
- Excel : PhpSpreadsheet, en-tête bleu à texte blanc + première ligne figée + filtre automatique + masquage des données sensibles
- PDF : Dompdf A4 paysage, copyright en en-tête + filigrane de droit d'auteur non amovible en pied de page
- Export PDF des données de visualisation du panneau

### Moteur de recherche
- `erikwang2013/webman-scout` pilote Elasticsearch
- Synchronisation automatique des index (push automatique à chaque ajout/modification/suppression)
- Préfixe d'index `management_`, cohérent avec le préfixe des tables

### Internationalisation (i18n)
- **Backend PHP** : symfony/translation — `resource/translations/{zh_CN,en}/messages.php`, 42 clés de traduction, obtenues dans les contrôleurs via `__()`
- **Flutter Web** : GetX `Translations` — `lib/i18n/messages.dart`, 101 clés de traduction, utilisées via l'extension `.tr` dans les pages
- **HarmonyOS** : qualificatifs de ressources `resources/{base,en_US}/element/string.json`
- **Langue par défaut** : chinois simplifié (zh_CN), langue de repli anglais (en)
- **En-tête de requête** : prise en charge d'`Accept-Language` pour contrôler la langue de la réponse

### Couverture des tests
- **Framework de test** : PHPUnit 12.x
- **Processus TDD** : rouge→vert→refactorisation, les tests d'abord
- **Panneau d'administration** : 60 tests, 164 assertions, couvrant services de base, configuration d'environnement, validation de sécurité
- **Service métier** : 18 tests, 45 assertions, 100 % de réussite
- **Total** : 78 tests, 209 assertions
- **Couverture** : unicité de la génération d'ID Snowflake, aller-retour de codage/décodage Hashids, format de réponse unifié, validation du schéma des 64 tables, cohérence des clés de traduction chinois/anglais
- **Flutter** : flutter analyze zéro problème
- **Documentation API** : générée automatiquement par `hg/apidoc`, admin (10 groupes) + service (9 groupes), organisée par module fonctionnel
