# Comparaison des versions (Editions Comparison)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Le système de gestion immobilière se décline en trois versions : basique (Lite), standard (Standard), complète (Full), progressives par cumul.

---

## Vue d'ensemble

| Indicateur | Basique (Lite) | Standard | Complète (Full) |
|------|:-----------:|:---------------:|:-----------:|
| Tables de base de données | **21** | **31** | **65** |
| Modèles Eloquent | 19 | 30 | 58 |
| Contrôleurs admin | 17 | 28 | 47 |
| Contrôleurs service (propriétaires) | 9 | 12 | 17 |
| Routes API | 35 | 70 | 178 |
| Modules métier | 10 | 18 | 34 |
| Couches de sécurité | 18 | 18 | 18 |

---

## Comparaison des modules fonctionnels

### Basique (Lite)

Gestion immobilière de base : système général du panneau d'administration + 10 modules métier principaux.

**Panneau d'administration** : tableau de bord, CRUD utilisateurs/rôles/permissions/configurations/journaux, CRUD résidences/bâtiments/unités/types de logement/biens/propriétaires/locataires/frais/réparations/annonces

**Portail des propriétaires** : inscription/connexion, accueil, mes biens, paiement des factures, soumission de réparation/évaluation, consultation des annonces, informations personnelles

---

### Standard

Ajoute à la basique 6 modules métier auxiliaires + visualisation de panneaux + export de données.

**Ajouts panneau d'administration** : CRUD places de stationnement/véhicules, registre des équipements + maintenance, traitement des réclamations + suivi, approbation des visiteurs, gestion des contrats, gestion des recettes/dépenses + statistiques

**Ajouts portail des propriétaires** : mes véhicules/places, historique de stationnement, réservation de visiteur/code de passage

---

### Complète (Full)

Ajoute à la standard les modules avancés + 12 fonctions étendues.

**Ajouts panneau d'administration** : itinéraires de patrouille + enregistrements, zones de nettoyage + enregistrements, zones vertes + entretien, gestion des activités communautaires, compteurs d'énergie + relevés, gestion des employés, modèles de notification + envoi, moteur d'approbation, commandes de paiement + remboursement, gestion des votes + règles SLA + stratégies de relance + tâches d'inspection + gestion de la boutique + validation faciale + gestion de groupe + base de connaissances

**Ajouts portail des propriétaires** : inscription aux activités communautaires, réservation stationnement/visiteur, notifications, vote + dépouillement, parcours des produits + commande, Q&A intelligent, enregistrement facial

---

## Comparaison des indicateurs techniques

| Indicateur | Basique | Standard | Complète |
|------|:------:|:------:|:------:|
| Tables de base de données | 21 | 31 | 65 |
| Fichiers de modèles | 19 | 30 | 58 |
| Contrôleurs admin | 17 | 28 | 47 |
| Contrôleurs service | 9 | 12 | 17 |
| Routes admin | 45 | 80 | 123 |
| Routes service | 20 | 35 | 55 |
| Pages Flutter Admin | 4 | 7 | 57 |
| Pages HarmonyOS | 2 | 3 | 7 |
| Middlewares | 7 | 8 | 9 |
| Tests PHP | 18 | 18 | 133 |

---

## Système de sécurité (commun aux trois versions)

18 couches de défense en profondeur : code de vérification → confirmation du mot de passe → vérification aléatoire → analyse de sécurité → interception des attaques → HTTPS + AES-256-CBC → JWT → contrôle des sessions → verrouillage du compte → RBAC → limitation de débit → protection des ID → chiffrement des requêtes → chiffrement du stockage → masquage à l'affichage → audit → CSP → filigrane de droit d'auteur

---

## Parcours de migration

```
Basique (Lite)
  │
  │  + 6 modules auxiliaires + panneaux + export
  ▼
Standard
  │
  │  + 6 modules avancés + 12 fonctions étendues
  ▼
Complète (Full)
```

La mise à niveau nécessite seulement d'exécuter les fichiers de migration SQL du lot correspondant, sans migration de données ni changement destructif.

---

## Parcours de démonstration

**Préparation** : `docs/install.sql` exécuté (structure complète de toutes les tables, incluant les tables de toutes les versions) ; `admin/.env` configure la connexion à la base. Les différences de version portent sur l'enregistrement des routes et la visibilité des fonctions, la structure des tables est unifiée au complet.

### Basique (Lite)

1. Exécuter les données de démonstration : `cd admin && php ../scripts/demo_data.php` (idempotent, ré-exécutable)
2. Périmètre des données de démo : résidences/bâtiments/unités/types de logement/biens/propriétaires/locataires/frais/factures/annonces + comptes de démo, couvrant les modules principaux Lite
3. Quoi regarder : tableau de bord du panneau + CRUD utilisateurs/rôles/permissions/configurations/journaux + CRUD biens/propriétaires/locataires/frais/réparations/annonces ; côté propriétaire : inscription/connexion, accueil, mes biens, paiement des factures, réparation, annonces
4. Différence de routes : seul le groupe Lite est enregistré, les blocs enveloppés dans `edition_supports('standard'/'full')` ne sont pas enregistrés (`admin/config/route.php`)

### Standard

1. Exécuter les données de démonstration : `cd admin && php ../scripts/demo_data.php` (idempotent, la ré-exécution ne complète que les manquants, ne recrée pas les doublons)
2. Les données des modules auxiliaires sont peu nombreuses : stationnement/équipements/réclamations/visiteurs/contrats/recettes-dépenses peuvent être saisis en petite quantité pour la démo
3. Quoi regarder : ajouts panneau — places de stationnement/véhicules, registre des équipements + maintenance, traitement des réclamations + suivi, approbation des visiteurs, gestion des contrats, gestion des recettes/dépenses + statistiques ; ajouts propriétaire — mes véhicules/places, historique de stationnement, réservation de visiteur/code de passage
4. Différence de routes : ajout du groupe `edition_supports('standard')`, le groupe Lite est conservé

### Complète (Full)

1. Exécuter les données de démonstration : `cd admin && php ../scripts/demo_data.php` (idempotent)
2. Les données de démo des modules avancés (paiement/approbation/vote/boutique/inspection/visage/groupe/base de connaissances) sont saisies au besoin, ou créées directement avec les comptes de démo
3. Quoi regarder : au-delà de Standard — patrouille/nettoyage/espaces verts/énergie/employés/modèles de notification/moteur d'approbation/commandes de paiement/vote/SLA/relance/inspection/boutique/visage/groupe/base de connaissances ; côté propriétaire — inscription aux activités, notifications, vote, commandes en boutique, Q&A intelligent, enregistrement facial
4. Différence de routes : enregistrement complet, le groupe `edition_supports('full')` est effectif (`admin/config/route.php`)

### Changer de version

```bash
# Définir la version cible dans admin/.env (progressive, full inclut toutes les fonctions)
EDITIONS=lite|standard|full

# Redémarrer webman pour prise d'effet (déploiement conteneur : docker compose restart app ; bare metal : php start.php restart)
```

- Configuration fail-fast : une valeur `EDITIONS` invalide lève directement une erreur (`admin/config/edition.php`), pas de repli silencieux sur une mauvaise version.
- Le script de données de démo est idempotent, aucun vidage de base nécessaire pour changer de version ; les données des modules Standard/Full sont peu nombreuses, saisies par la vraie activité suffit.
