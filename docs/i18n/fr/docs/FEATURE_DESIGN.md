# Document de conception fonctionnelle (Feature Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Aperçu

Le système de gestion immobilière se divise en **panneau d'administration** (usage interne de la société de gestion immobilière) et **portail des propriétaires** (usage des propriétaires/locataires de la résidence), couvrant 15 modules métier, livrés en 3 lots.

---

## Lot 1 : cœur de métier

### 1. Gestion des résidences/communautés (Community)

**Panneau d'administration :**
- Liste des résidences (recherche, pagination, filtrage par statut)
- Créer/consulter/modifier/supprimer une résidence
- Informations de la résidence : nom, adresse (province/ville/district), surface construite, nombre de bâtiments, nombre de logements, promoteur, société de gestion immobilière, téléphone de contact
- La suppression nécessite une double confirmation du mot de passe, avec suppression douce

**Portail des propriétaires :** aucune permission d'administration requise ; la page d'accueil affiche les informations de la résidence liée.

### 2. Gestion des bâtiments (Building)

**Panneau d'administration :**
- Liste des bâtiments filtrés par résidence
- Créer/consulter/modifier/supprimer un bâtiment
- Informations du bâtiment : nom, type (tour/barre/villa/commercial), nombre d'étages, nombre d'unités, nombre d'ascenseurs, année de construction, type de structure
- Tri pris en charge

### 3. Gestion des unités (Unit)

**Panneau d'administration :**
- Liste des unités filtrées par bâtiment
- Créer/consulter/modifier/supprimer une unité
- Informations de l'unité : nom, nombre de logements par étage

### 4. Gestion des types de logement (RoomType)

**Panneau d'administration :**
- CRUD des types de logement
- Informations : nom (trois chambres deux salons), nombre de chambres/salons/salles de bain, plan du logement

### 5. Gestion des biens (Room)

**Panneau d'administration :**
- Vue en arbre des biens (résidence→bâtiment→unité→bien)
- Créer/consulter/modifier/supprimer un bien
- Informations du bien : numéro de logement, étage, type de logement, surface (privative/commune/totale), orientation, décoration, usage (résidentiel/commercial/bureaux), statut (vacant/vendu/loué/occupé par le propriétaire)
- Lier/délier les propriétaires en masse

**Portail des propriétaires :**
- Consulter la liste de mes biens liés
- Consulter les détails du bien (surface, orientation, type de logement, informations de propriété)

### 6. Gestion des propriétaires (Owner)

**Panneau d'administration :**
- Liste des propriétaires (recherche, pagination, filtrage par statut)
- Créer/consulter/modifier/supprimer un propriétaire
- Informations du propriétaire : nom, numéro de mobile (chiffré), e-mail (chiffré), carte d'identité (chiffrée), sexe, date de naissance, contact d'urgence, date d'emménagement
- Import en masse (Excel), activation/désactivation en masse, suppression en masse
- Liaison/déliaison des biens

**Portail des propriétaires :**
- Inscription (mobile + mot de passe + captcha, vérification possible par liaison de bien)
- Connexion (mobile + mot de passe + captcha cliquable, protection par verrouillage du compte)
- Consultation/modification des informations personnelles
- Modification du mot de passe, déconnexion

### 7. Gestion des locataires (Tenant)

**Panneau d'administration :**
- Liste des locataires filtrés par bien/bailleur
- Créer/consulter/modifier/supprimer un locataire
- Informations du locataire : nom, numéro de mobile (chiffré), carte d'identité (chiffrée), dates de début/fin du bail, loyer mensuel, statut

### 8. Gestion des frais (Fee)

**Types de frais (panneau d'administration) :**
- CRUD des types de frais : charges de copropriété, eau, électricité, gaz, chauffage, stationnement, fonds de réparation, autres
- Prix unitaire, unité de facturation (元/m²/mois, 元/tonne, 元/kWh, etc.), période de facturation (mensuelle/trimestrielle/annuelle), caractère obligatoire

**Gestion des factures (panneau d'administration) :**
- Consultation des factures par résidence/bâtiment/bien
- Création/édition manuelle des factures
- Génération en masse (sélection de la résidence + type de frais + période, génération automatique pour tous les logements)
- Informations de la facture : type de frais, montant, pénalités de retard, période de facturation, date limite
- Statut : non payée/partiellement payée/payée/en retard/exonérée
- Notification de relance en masse

**Factures (portail des propriétaires) :**
- Liste de mes factures (filtre par statut : non payée/payée/en retard)
- Détails de la facture
- Paiement en ligne (WeChat/Alipay, double confirmation du mot de passe requise)
- Consultation de l'historique de paiement
- Statistiques des frais (tendance mensuelle/annuelle, répartition par catégorie)

**Historique de paiement (panneau d'administration) :**
- Consultation de l'historique de paiement
- Enregistrement des encaissements hors ligne (espèces/carte bancaire/virement)

### 9. Gestion des réparations (Repair)

**Panneau d'administration :**
- Liste des réparations (filtre par statut/catégorie)
- Consultation des détails de la réparation
- Dispatch (affectation d'un technicien)
- Mise à jour de la progression de la réparation

**Portail des propriétaires :**
- Liste de mes réparations
- Soumettre une réparation (sélection du bien, catégorie, degré d'urgence, description, téléversement d'images, heure de rendez-vous)
- Consulter les détails et la progression de la réparation
- Annuler une réparation (uniquement en statut « en attente de dispatch », confirmation du mot de passe requise)
- Évaluer la réparation (1-5 étoiles + commentaire écrit)

### 10. Annonces et notifications (Announcement)

**Panneau d'administration :**
- CRUD des annonces
- Publication des annonces par résidence
- Catégories : notification/annonce/rappel/activité
- Épinglage, statut brouillon/publié

**Portail des propriétaires :**
- Consulter la liste des annonces publiées (filtre par catégorie)
- Détails de l'annonce

---

## Lot 2 : activités auxiliaires

### 11. Gestion du stationnement (Parking)

**Panneau d'administration :**
- Gestion des places (numéro, aérien/souterrain, surface, statut : libre/vendue/louée/en maintenance)
- Gestion des véhicules (plaque chiffrée, marque, couleur, type, liaison place/propriétaire)
- Consultation de l'historique de stationnement (heures d'entrée/sortie, durée de stationnement, frais)

**Portail des propriétaires :**
- Liste de mes véhicules
- Liste de mes places
- Consultation de l'historique de stationnement

### 12. Gestion des équipements (Equipment)

**Panneau d'administration :**
- Registre des équipements (nom, numéro, catégorie : ascenseur/incendie/contrôle d'accès/vidéosurveillance/alimentation en eau et drainage/alimentation électrique/CVC)
- Informations de l'équipement : marque, modèle, emplacement d'installation, date d'installation, expiration de la garantie, durée de vie prévue
- Historique de maintenance : inspection quotidienne/entretien périodique/réparation de panne/grosse révision/remplacement
- Technicien, coût, société de maintenance, prochaine date de maintenance

### 13. Réclamations et suggestions (Complaint)

**Panneau d'administration :**
- Liste des réclamations (filtre par type/statut)
- Traitement des réclamations (affectation d'un responsable, saisie des remarques de traitement)
- Enregistrement des visites de suivi (remarques de suivi, enregistrement de la satisfaction)

**Portail des propriétaires :**
- Liste de mes réclamations/suggestions
- Soumettre une réclamation/suggestion (type : réclamation/suggestion/éloge, catégorie : service/environnement/sécurité/installations/bruit/construction illégale)
- Soumission anonyme et téléversement d'images pris en charge
- Consulter la progression du traitement
- Évaluation de satisfaction

### 14. Gestion des visiteurs (Visitor)

**Panneau d'administration :**
- Approbation des réservations de visiteurs
- Consultation de l'historique des visiteurs

**Portail des propriétaires :**
- Réservation de visiteur (nom du visiteur, téléphone, carte d'identité, plaque d'immatriculation, nombre d'accompagnants, motif de la visite, heure prévue)
- Génération d'un code de passage
- Modification/annulation de la réservation

### 15. Gestion des contrats (Contract)

**Panneau d'administration :**
- Liste des contrats (filtre par type/statut)
- Types de contrats : contrat de copropriété/contrat de location/contrat de maintenance/contrat de service/contrat d'achat
- Informations du contrat : numéro, parties A et B, montant, dates de début/fin, date de signature, pièces jointes
- Statut : brouillon/en cours d'exécution/expiré/résilié/renouvelé

### 16. Gestion financière (Finance)

**Panneau d'administration :**
- Gestion des revenus (charges de copropriété/frais de stationnement/loyers/frais publicitaires/fonds de réparation/autres)
- Gestion des dépenses (personnel/achat d'équipements/maintenance/énergie/nettoyage et espaces verts/bureautique/taxes/autres)
- Rapports de statistiques des revenus/dépenses (mensuel/trimestriel/annuel)

---

## Lot 3 : fonctions avancées

### 17. Patrouilles de sécurité (Security Patrol)

**Panneau d'administration :**
- Gestion des itinéraires de patrouille (coordonnées de l'itinéraire, points de pointage)
- Enregistrements de patrouille (heures de début/fin, durée, remarques d'anomalie)
- Statistiques du taux d'achèvement des patrouilles

### 18. Gestion du nettoyage (Cleaning)

**Panneau d'administration :**
- Gestion des zones de nettoyage (emplacement, surface, fréquence : quotidienne/hebdomadaire/bimensuelle/mensuelle)
- Enregistrements de nettoyage (heure de nettoyage, inspecteur, remarques d'inspection, photos sur site)
- Statistiques du taux d'achèvement du nettoyage

### 19. Gestion des espaces verts (Green)

**Panneau d'administration :**
- Gestion des zones vertes (emplacement, surface, plantes principales)
- Enregistrements d'entretien (arrosage/taille/fertilisation/désinsectisation/replantation, coûts)

### 20. Activités communautaires (Activity)

**Panneau d'administration :**
- Gestion des activités (titre, contenu, catégorie : culture et sport/fêtes/bienfaisance/conférences/familles)
- Image de couverture, lieu, nombre maximal de participants, horaires, frais
- Statut : inscriptions ouvertes/en cours/terminée/annulée
- Consultation de la liste des inscriptions

**Portail des propriétaires :**
- Liste des activités (filtre : inscriptions ouvertes/en cours)
- Détails de l'activité
- S'inscrire/annuler l'inscription

### 21. Gestion de l'énergie (Energy)

**Panneau d'administration :**
- Gestion des compteurs (compteur électrique/d'eau/gaz/chauffage, numéro)
- Relevés (lecture actuelle, consommation, prix unitaire, montant)
- Génération automatique des factures liées

### 22. Gestion des employés (Staff)

**Panneau d'administration :**
- Informations des employés (nom, numéro de mobile chiffré, carte d'identité chiffrée, poste, service, date d'entrée)
- Services : direction/service client/technique/sécurité/nettoyage/espaces verts/finances
- Statut : en poste/départ/congé

---

## Visualisation en panneaux et export

### Panneau de bord

**Tableau de bord du panneau d'administration :**
- Cartes d'indicateurs clés : montant total à recevoir, montant total encaissé, taux d'impayés, taux d'occupation
- Graphique en courbes de la tendance des frais (mensuel/trimestriel)
- Graphique en camembert par catégorie de frais
- Statistiques des réparations (par catégorie, par statut)
- Statistiques des réclamations
- Derniers journaux d'opérations

**Accueil du portail des propriétaires :**
- Nombre de mes biens, montant des frais à payer, nombre de réparations en cours, dernières annonces

### Export Excel

- Export de la liste des propriétaires
- Export du rapport des factures
- Export de l'historique de paiement
- Export du rapport financier
- Masquage automatique des données sensibles à l'export

### Export PDF

- Export de la visualisation du panneau de bord
- Rapport financier PDF (copyright en en-tête + filigrane de copyright inamovible en pied de page)
- Mise en page A4 paysage

---

## Fonctionnalités transverses

| Fonctionnalité | Description |
|------|------|
| Protection des ID | Tous les ID d'interface sont encodés en hashids pour la transmission |
| Chiffrement des données | Champs sensibles (mobile/e-mail/carte d'identité) : AES-256-CBC au niveau API, encryptable au niveau DB |
| Audit des opérations | Toutes les opérations POST/PUT/DELETE des administrateurs sont enregistrées automatiquement, avec détection automatique de la source |
| Contrôle des permissions | RBAC granularité method.path, identifiant super administrateur `*` |
| Limitation de débit | Fenêtre glissante Redis, connexion 10 fois/minute, inscription 5 fois/minute |
| Captcha | Captcha cliquable en chinois, obligatoire à la connexion/inscription |
| Suppression douce | Propriétaires, résidences, biens, annonces pris en charge |
| Internationalisation | Bilingue chinois/anglais, symfony/translation PHP + GetX Translations Flutter, chinois par défaut, repli anglais |
| Documentation API | Générée par `hg/apidoc`, annotations de 57 des 58 contrôleurs regroupées en 10 groupes (Base/Docs/Install non groupés), `/apidoc/config` fournit l'API de configuration |
| Tests | Processus TDD, 133 tests/465 assertions, service 100 % réussi, flutter analyze zéro problème |
| Flutter Web | 13 pages (connexion/accueil/frais/réparation/espace personnel, etc.), style desktop PC, gestion d'état GetX |
| HarmonyOS | Squelette de projet complet, couche de services ArkTS + authentification + connexion/accueil, @ohos.net.http |

## Fonctions étendues (lot 4)

### Centre de notifications
- Modèles de notification configurables (push App/SMS/e-mail)
- Rappels de facture, progression de réparation, publication d'annonce notifiés automatiquement
- Liste de messages côté propriétaire + gestion des lus

### Moteur de workflow d'approbation
- Types et étapes d'approbation configurables (supérieur→manager→directeur)
- Dispatch de réparation/approbation de visiteur/approbation de contrat via un processus standardisé
- Historique d'approbation traçable

### Intégration des paiements
- Gestion des commandes de paiement WeChat/Alipay
- Traitement des callbacks de paiement, remboursements, statistiques de rapprochement
- Mise à jour automatique des factures liées

### Vote/délibération des propriétaires
- Vote ordinaire + délibération de l'assemblée des propriétaires (pondérée par surface)
- Gestion des options, enregistrement des votes, dépouillement automatique
- Statistiques du taux de participation

### Escalade automatique SLA des réparations
- Délais de réponse/résolution configurables par catégorie + degré d'urgence
- Escalade automatique au rôle supérieur en cas de dépassement
- Enregistrement automatique des pénalités de retard

### Relance intelligente
- Configuration de stratégies de relance par paliers (jours de retard → action)
- Correspondance automatique des factures en retard pour exécuter la relance (App/SMS/téléphone/visite à domicile)
- Calcul automatique des pénalités de retard

### Inspection mobile
- Dispatch des tâches d'inspection (itinéraire GPS + points de contrôle)
- Pointage mobile (géolocalisation + photo + marquage des anomalies)
- Statistiques du taux d'achèvement des inspections

### Boutique communautaire
- Gestion des catégories de produits/mise en ligne/retrait
- Navigation des propriétaires + commande + suivi des commandes
- Gestion de l'expédition/des remboursements

### Reconnaissance faciale
- Enregistrement facial des propriétaires (intégration d'un service de reconnaissance tiers)
- Vérification et certification côté panneau d'administration
- Association au passage du contrôle d'accès

### Gestion multi-résidences (groupe)
- Association plusieurs-à-plusieurs groupe→résidence
- Agrégation des données inter-résidences (vue unifiée des biens/propriétaires/facturation)

### Q&A intelligent
- Gestion de la base de connaissances (catégories/articles/mots-clés)
- Correspondance automatique des questions des propriétaires
- Historique des conversations + statistiques du taux de résolution

### Écran de données
- Visualisation en plein écran en temps réel des données immobilières
- Quatre panneaux : facturation/réparations/équipements/énergie
- Actualisation automatique en carrousel
