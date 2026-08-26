# Documentation des interfaces (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Aperçu

- Les API du panneau d'administration tournent sur `http://localhost:8787`
- Les API du portail des propriétaires tournent sur `http://localhost:8788`
- Format de réponse unifié : `{"code": 0, "message": "success", "data": {...}}`
- Tous les champs ID sont encodés en hashids pour la transmission
- La version de l'API est contrôlée par l'en-tête de requête `API-Version` (défaut `v1`)
- La langue est contrôlée par l'en-tête de requête `Accept-Language` (`zh-CN` / `en-US`, défaut `zh-CN`)

### Documentation API en ligne

Après démarrage du service, accéder à la documentation interactive générée automatiquement par `hg/apidoc` :

| Extrémité | Adresse | Nombre de groupes |
|----|------|--------|
| Panneau d'administration | `http://localhost:8787/apidoc` | 10 groupes (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| Portail des propriétaires | `http://localhost:8788/apidoc` | 9 groupes (interfaces publiques/accueil/frais/réparation/retour/stationnement/activité/personnel/extensions) |

---

## API du panneau d'administration (admin :8787)

### Interfaces publiques — sans authentification

#### POST /api/captcha/generate
Obtenir un captcha cliquable.

Paramètres de requête : aucun

Réponse :
```json
{
  "code": 0,
  "data": {
    "key": "captcha_key_string",
    "image": "base64_encoded_png",
    "extra": { "targets": ["树", "鸟", "花"] }
  }
}
```

#### POST /api/captcha/verify
Vérifier le captcha cliquable.

Paramètres de requête :
| Paramètre | Type | Description |
|------|------|------|
| key | string | Clé du captcha, renvoyée par generate |
| clicks | array | Coordonnées de clic [{x, y}, ...] |

Réponse :
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

En cas d'échec de vérification, `code` vaut 422 et `data.valid` vaut `false`.

#### POST /api/auth/login
Connexion administrateur.

Paramètres de requête :
| Paramètre | Type | Description |
|------|------|------|
| username | string | Nom d'utilisateur |
| password | string | Mot de passe |
| captcha_key | string | Clé du captcha |
| clicks | array | Coordonnées de clic [{x, y}, ...] |

Réponse :
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "user": { "id": "aB3xK9mW...", "username": "admin", "real_name": "管理员" }
  }
}
```

#### POST /api/auth/refresh
Rafraîchir le Token.

Paramètres de requête :
| Paramètre | Type | Description |
|------|------|------|
| refresh_token | string | Jeton de rafraîchissement |

Réponse :
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
Contrôle de santé.

#### GET /metrics
Métriques de monitoring Prometheus.

#### GET /api/docs
Documentation OpenAPI.

---

### Interfaces du panneau d'administration — authentification requise (Bearer Token)

Toutes les interfaces sont préfixées `/admin` et nécessitent l'en-tête `Authorization: Bearer {access_token}`.

#### Tableau de bord

**GET /admin/dashboard**
Obtenir les statistiques du tableau de bord.

#### Gestion des utilisateurs administrateurs

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/user | Liste des utilisateurs (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | Créer un utilisateur |
| GET | /admin/user/{hashid} | Détails de l'utilisateur |
| PUT | /admin/user/{hashid} | Mettre à jour l'utilisateur |
| DELETE | /admin/user/{hashid} | Supprimer l'utilisateur (confirmation du mot de passe requise) |
| POST | /admin/user/batch/destroy | Suppression en masse |
| POST | /admin/user/batch/status | Activer/désactiver en masse |
| POST | /admin/import/users | Import Excel des utilisateurs |

#### Gestion des rôles et permissions

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/role | Liste des rôles |
| POST | /admin/role | Créer un rôle |
| GET | /admin/role/{hashid} | Détails du rôle |
| PUT | /admin/role/{hashid} | Mettre à jour le rôle |
| DELETE | /admin/role/{hashid} | Supprimer le rôle |
| GET | /admin/permission | Liste des permissions (arborescente) |
| POST | /admin/permission | Créer une permission |
| PUT | /admin/permission/{hashid} | Mettre à jour la permission |
| DELETE | /admin/permission/{hashid} | Supprimer la permission |

#### Configuration système

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/config | Liste des configurations (?group=) |
| POST | /admin/config | Créer une configuration |
| PUT | /admin/config/{hashid} | Mettre à jour la configuration |
| DELETE | /admin/config/{hashid} | Supprimer la configuration |

#### Journaux d'opérations

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/log | Liste des journaux (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### Espace personnel

| Méthode | Chemin | Description |
|------|------|------|
| PUT | /admin/profile | Modifier les informations personnelles |
| PUT | /admin/profile/password | Modifier le mot de passe |
| POST | /admin/profile/logout | Se déconnecter |

#### Export

| Méthode | Chemin | Description |
|------|------|------|
| POST | /admin/export/excel | Export Excel ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | Export PDF ({ type, title, data }) |

---

### Gestion immobilière — interfaces du panneau d'administration

#### Gestion des résidences

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/community | Liste (?keyword=&status=) |
| POST | /admin/community | Créer |
| GET | /admin/community/{hashid} | Détails |
| PUT | /admin/community/{hashid} | Mettre à jour |
| DELETE | /admin/community/{hashid} | Supprimer (mot de passe requis) |

#### Gestion des bâtiments

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/building | Liste (?community_id=&keyword=) |
| POST | /admin/building | Créer |
| GET | /admin/building/{hashid} | Détails |
| PUT | /admin/building/{hashid} | Mettre à jour |
| DELETE | /admin/building/{hashid} | Supprimer |

#### Gestion des unités

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/unit | Liste (?building_id=) |
| POST | /admin/unit | Créer |
| GET | /admin/unit/{hashid} | Détails |
| PUT | /admin/unit/{hashid} | Mettre à jour |
| DELETE | /admin/unit/{hashid} | Supprimer |

#### Gestion des types de logement

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/room-type | Liste |
| POST | /admin/room-type | Créer |
| GET | /admin/room-type/{hashid} | Détails |
| PUT | /admin/room-type/{hashid} | Mettre à jour |
| DELETE | /admin/room-type/{hashid} | Supprimer |

#### Gestion des biens

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/room | Liste (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | Créer |
| GET | /admin/room/{hashid} | Détails |
| PUT | /admin/room/{hashid} | Mettre à jour |
| DELETE | /admin/room/{hashid} | Supprimer |
| GET | /admin/room/tree | Arbre des biens (résidence→bâtiment→unité→bien) |

#### Gestion des propriétaires

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/owner | Liste (?keyword=&status=) |
| POST | /admin/owner | Créer |
| GET | /admin/owner/{hashid} | Détails (avec biens liés) |
| PUT | /admin/owner/{hashid} | Mettre à jour |
| DELETE | /admin/owner/{hashid} | Supprimer (mot de passe requis) |
| POST | /admin/owner/batch/import | Import Excel en masse |
| POST | /admin/owner/batch/destroy | Suppression en masse |

#### Gestion des locataires

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/tenant | Liste (?room_id=&status=) |
| POST | /admin/tenant | Créer |
| GET | /admin/tenant/{hashid} | Détails |
| PUT | /admin/tenant/{hashid} | Mettre à jour |
| DELETE | /admin/tenant/{hashid} | Supprimer |

#### Types de frais

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/fee-type | Liste |
| POST | /admin/fee-type | Créer |
| GET | /admin/fee-type/{hashid} | Détails |
| PUT | /admin/fee-type/{hashid} | Mettre à jour |
| DELETE | /admin/fee-type/{hashid} | Supprimer |

#### Gestion des factures

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/fee-bill | Liste (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | Créer une facture |
| GET | /admin/fee-bill/{hashid} | Détails |
| PUT | /admin/fee-bill/{hashid} | Mettre à jour |
| DELETE | /admin/fee-bill/{hashid} | Supprimer |
| POST | /admin/fee-bill/batch/generate | Génération en masse des factures |

#### Historique des paiements

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/fee-payment | Liste (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | Enregistrement d'un encaissement hors ligne |

#### Gestion des réparations

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/repair | Liste (?status=&category=) |
| POST | /admin/repair | Créer |
| GET | /admin/repair/{hashid} | Détails (avec historique de progression) |
| PUT | /admin/repair/{hashid} | Mettre à jour |
| DELETE | /admin/repair/{hashid} | Supprimer |
| PUT | /admin/repair/{id}/assign | Dispatch ( { staff_id } ) |
| POST | /admin/repair/{id}/progress | Mettre à jour la progression ({ status_to, remark }) |

#### Gestion des annonces

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/announcement | Liste (?community_id=&category=&is_published=) |
| POST | /admin/announcement | Créer |
| GET | /admin/announcement/{hashid} | Détails |
| PUT | /admin/announcement/{hashid} | Mettre à jour |
| DELETE | /admin/announcement/{hashid} | Supprimer |

#### Gestion du stationnement

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/parking-space | Liste (?community_id=) |
| POST | /admin/parking-space | Créer une place |
| PUT | /admin/parking-space/{hashid} | Mettre à jour |
| DELETE | /admin/parking-space/{hashid} | Supprimer |
| GET | /admin/parking-vehicle | Liste (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | Créer un véhicule |
| PUT | /admin/parking-vehicle/{hashid} | Mettre à jour |
| DELETE | /admin/parking-vehicle/{hashid} | Supprimer |
| GET | /admin/parking-record | Historique de stationnement (?vehicle_id=&date_start=&date_end=) |

#### Gestion des équipements

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/equipment | Liste (?community_id=&category=&status=) |
| POST | /admin/equipment | Créer |
| PUT | /admin/equipment/{hashid} | Mettre à jour |
| DELETE | /admin/equipment/{hashid} | Supprimer |
| GET | /admin/equipment-maintenance | Historique de maintenance (?equipment_id=) |
| POST | /admin/equipment-maintenance | Créer une maintenance |

#### Traitement des réclamations

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/complaint | Liste (?type=&status=) |
| GET | /admin/complaint/{hashid} | Détails |
| PUT | /admin/complaint/{id}/handle | Traiter ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | Visite de suivi ({ visitor_remark }) |

#### Approbation des visiteurs

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/visitor | Liste (?status=) |
| PUT | /admin/visitor/{id}/approve | Approuver |

#### Gestion des contrats

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/contract | Liste (?contract_type=&status=) |
| POST | /admin/contract | Créer |
| PUT | /admin/contract/{hashid} | Mettre à jour |
| DELETE | /admin/contract/{hashid} | Supprimer |

#### Gestion financière

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/finance-income | Liste des revenus (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | Enregistrer un revenu |
| GET | /admin/finance-expense | Liste des dépenses |
| POST | /admin/finance-expense | Enregistrer une dépense |
| GET | /admin/finance/statistics | Statistiques mensuelles des revenus/dépenses (?year=) |

#### Panneau immobilier

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/dashboard/property | Statistiques immobilières (à recevoir/taux d'occupation/réparations/réclamations/tendance des revenus-dépenses) |
| POST | /admin/export/property-excel | Export Excel des données immobilières ({ type: owners\|bills }) |

#### Patrouilles de sécurité

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/security-patrol | Liste (?community_id=) |
| POST | /admin/security-patrol | Créer un itinéraire |
| GET | /admin/patrol-record | Enregistrements (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | Créer un enregistrement |

#### Gestion du nettoyage

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/cleaning-area | Liste des zones |
| POST | /admin/cleaning-area | Créer une zone |
| GET | /admin/cleaning-record | Enregistrements (?area_id=) |
| POST | /admin/cleaning-record | Créer un enregistrement |

#### Gestion des espaces verts

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/green-area | Liste des zones |
| POST | /admin/green-area | Créer une zone |
| GET | /admin/green-maintenance | Enregistrements d'entretien (?area_id=) |
| POST | /admin/green-maintenance | Créer un enregistrement |

#### Activités communautaires

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/activity | Liste (?status=) |
| POST | /admin/activity | Créer une activité |
| PUT | /admin/activity/{hashid} | Mettre à jour |
| DELETE | /admin/activity/{hashid} | Supprimer |
| GET | /admin/activity-signup | Liste des inscriptions (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | Pointage |

#### Gestion de l'énergie

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/energy-meter | Liste des compteurs (?room_id=&meter_type=) |
| POST | /admin/energy-meter | Créer un compteur |
| GET | /admin/energy-record | Relevés (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | Créer un relevé |

#### Gestion des employés

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/staff | Liste (?community_id=&status=) |
| POST | /admin/staff | Créer |
| PUT | /admin/staff/{hashid} | Mettre à jour |
| DELETE | /admin/staff/{hashid} | Supprimer |
| POST | /admin/staff/batch/status | Activer/désactiver en masse |

#### Notifications

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/notification-template | Liste des modèles |
| POST | /admin/notification-template | Créer un modèle |
| PUT | /admin/notification-template/{hashid} | Mettre à jour le modèle |
| DELETE | /admin/notification-template/{hashid} | Supprimer le modèle |
| GET | /admin/notification | Liste des messages (?type=&is_read=) |
| POST | /admin/notification/send | Envoi manuel d'une notification |

#### Workflow d'approbation

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/approval-type | Liste des types d'approbation |
| POST | /admin/approval-type | Créer un type d'approbation |
| GET | /admin/approval | Liste des approbations (?status=) |
| GET | /admin/approval/{hashid} | Détails de l'approbation |
| POST | /admin/approval | Soumettre une approbation |
| PUT | /admin/approval/{hashid}/approve | Approuver (approbation/rejet) |

#### Gestion des paiements

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/payment-order | Liste des commandes |
| GET | /admin/payment-order/{hashid} | Détails de la commande |
| POST | /admin/payment-order/{hashid}/refund | Remboursement |
| GET | /admin/payment/statistics | Statistiques de paiement |

#### Vote des propriétaires

| Méthode | Chemin | Description |
|------|------|------|
| GET | /admin/vote | Liste des votes (?status=) |
| POST | /admin/vote | Créer un vote |
| GET | /admin/vote/{hashid}/statistics | Statistiques de dépouillement |
| PUT | /admin/vote/{hashid}/publish | Publier le vote |
| PUT | /admin/vote/{hashid}/end | Clôturer le vote |

#### Gestion SLA · relance intelligente · inspections · boutique · visage · groupe · base de connaissances

（完整端点参见 `docs/API.md` 文件）

---

## API du portail des propriétaires (service :8788)

### Interfaces publiques — sans authentification

#### POST /api/captcha/generate
Obtenir un captcha cliquable. (Identique au panneau d'administration)

#### POST /api/captcha/verify
Vérifier le captcha cliquable. (Requête/réponse identiques au panneau d'administration)

#### POST /api/auth/login
Connexion propriétaire.

Paramètres de requête :
| Paramètre | Type | Description |
|------|------|------|
| phone | string | Numéro de mobile |
| password | string | Mot de passe |
| captcha_key | string | Clé du captcha |
| clicks | array | Coordonnées de clic |

Réponse :
```json
{
  "code": 0,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "eyJ...",
    "owner": { "id": "xB9k...", "name": "张三", "phone": "138****1234" }
  }
}
```

#### POST /api/auth/register
Inscription propriétaire.

Paramètres de requête :
| Paramètre | Type | Description |
|------|------|------|
| phone | string | Numéro de mobile |
| password | string | Mot de passe (6 caractères minimum) |
| name | string | Nom |
| captcha_key | string | Clé du captcha |
| clicks | array | Coordonnées de clic |
| room_id | string | (Optionnel) hashid du bien à lier |
| id_card_last4 | string | (Optionnel) 4 derniers chiffres de la carte d'identité |

#### POST /api/auth/refresh
Rafraîchir le Token.

---

### Interfaces du portail des propriétaires — authentification requise (Bearer Token)

Toutes les interfaces sont préfixées `/service` et nécessitent l'en-tête `Authorization: Bearer {access_token}`.

#### Accueil

**GET /service/home**

Réponse :
```json
{
  "code": 0,
  "data": {
    "room_count": 2,
    "pending_amount": "1250.00",
    "pending_bill_count": 3,
    "repairing_count": 1,
    "announcements": [{ "id": "xB9k...", "title": "停水通知", "published_at": "2026-05-20 09:00" }]
  }
}
```

#### Mes biens

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/rooms | Liste de mes biens |
| GET | /service/room/{hashid} | Détails du bien (surface, orientation, propriété, informations de la résidence) |

#### Gestion des frais

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/fees/bills | Liste des factures (?status=0非缴/1部分缴/2已缴/3逾期) |
| GET | /service/fees/bill/{hashid} | Détails de la facture (type de frais, historique de paiement) |
| GET | /service/fees/payments | Historique des paiements |
| POST | /service/fees/pay | Paiement en ligne ({ bill_id, payment_method, password }) |
| GET | /service/fees/statistics | Statistiques des frais (?year=2026) |

#### Réparations

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/repairs | Liste des réparations (?status=) |
| GET | /service/repair/{hashid} | Détails de la réparation (avec chronologie de progression) |
| POST | /service/repair | Soumettre une réparation ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/repair/{hashid} | Annuler (mot de passe requis, { password }) |
| POST | /service/repair/{hashid}/rate | Évaluer ({ rating: 1-5, feedback }) |

#### Réclamations et suggestions

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/complaints | Liste des réclamations |
| GET | /service/complaint/{hashid} | Détails de la réclamation (avec progression du traitement) |
| POST | /service/complaint | Soumettre une réclamation ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/complaint/{hashid}/satisfaction | Évaluation de satisfaction ({ satisfaction: 1-5 }) |

#### Annonces

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/announcements | Liste des annonces (?category=) |
| GET | /service/announcement/{hashid} | Détails de l'annonce |

#### Stationnement

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/parking/vehicles | Mes véhicules |
| GET | /service/parking/spaces | Mes places |
| GET | /service/parking/records | Historique de stationnement |

#### Visiteurs

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/visitors | Mes réservations de visiteurs |
| POST | /service/visitor | Créer une réservation (génère un code de passage) |
| PUT | /service/visitor/{hashid} | Modifier la réservation |
| DELETE | /service/visitor/{hashid} | Annuler la réservation |

#### Activités communautaires

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/activities | Liste des activités (?status=) |
| GET | /service/activity/{hashid} | Détails de l'activité |
| POST | /service/activity/{hashid}/signup | S'inscrire |
| POST | /service/activity/{hashid}/cancel | Annuler l'inscription |

#### Informations personnelles

| Méthode | Chemin | Description |
|------|------|------|
| GET | /service/profile | Informations personnelles |
| PUT | /service/profile | Modifier ({ name, email, gender, birthday }) |
| PUT | /service/profile/password | Changer le mot de passe ({ old_password, new_password }) |
| POST | /service/profile/logout | Se déconnecter |

---

## API ouvertes — authentification par API Key

Interfaces entrantes en lecture seule, destinées aux systèmes tiers (intégration de plateformes immobilières, écrans de données, etc.). Préfixe `/open`, toutes en lecture seule.

### Mode d'authentification

Chaque requête doit porter l'en-tête `X-API-Key`, dont la valeur est la clé générée par `scripts/gen_api_key.php` (hexadécimal 64 bits, seule l'empreinte SHA-256 est stockée en base) :

```bash
curl -H "X-API-Key: <你的Key>" http://localhost:8788/open/announcements
```

- Clé manquante ou erronée → `401`（`{"code":401,"message":"无效的API Key","data":[]}`）
- Gestion des clés : `php scripts/gen_api_key.php [--name=用途]` pour générer ; désactivation/suppression directement via la table `erik_api_key`（`status=0` désactive, la clé devient immédiatement invalide）

### Points de terminaison

#### GET /open/announcements — liste des annonces

Paramètres : `page` (défaut 1), `category` (optionnel). Structure de réponse identique à `/service/announcements`.

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — consultation des factures

Paramètres : `bill_number` (obligatoire, numéro de facture). Renvoie le détail d'une facture (type de frais, numéro de bien, montant impayé). 404 si inexistante.

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — consultation du statut des réparations

Paramètres : `order_number` (obligatoire, numéro de bon de réparation). Renvoie le statut actuel et la chronologie de progression (tableau `progress`). 404 si inexistante.

```bash
curl -H "X-API-Key: <你的Key>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## Codes d'erreur

| code | Signification | Description |
|------|------|------|
| 0 | Succès | Réponse normale |
| 400 | Erreur de requête | Format de paramètres incorrect |
| 401 | Non authentifié | Token manquant/expiré/invalide/mis en liste noire |
| 403 | Sans permission | Le rôle de l'utilisateur ne contient pas la permission requise / compte désactivé |
| 404 | Introuvable | Ressource non trouvée |
| 405 | Méthode non autorisée | Méthode HTTP autre que GET/POST/PUT/DELETE/OPTIONS |
| 413 | Corps de requête trop grand | Dépassement de 10 Mo |
| 415 | Type de média non pris en charge | Content-Type n'est ni JSON ni form-urlencoded |
| 422 | Échec de validation | Paramètres de formulaire non conformes / échec de confirmation du mot de passe / captcha erroné |
| 429 | Trop de requêtes | Limitation de débit déclenchée / compte verrouillé |
| 500 | Erreur serveur | Exception inattendue |

## En-têtes de réponse de limitation de débit

Quand la limitation est déclenchée, 429 est renvoyé et la réponse contient les en-têtes suivants :

| En-tête de réponse | Description |
|--------|------|
| X-RateLimit-Limit | Limite de requêtes |
| X-RateLimit-Remaining | Requêtes restantes |
| X-RateLimit-Reset | Heure de réinitialisation (timestamp Unix) |
| Retry-After | Nombre de secondes d'attente recommandé |
