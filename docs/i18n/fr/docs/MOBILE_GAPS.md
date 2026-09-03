# Liste des écarts à combler pour le mobile

> Date de génération : 2026-08-16 · Source : pmp-team ci-agent (P3-③ inventaire de l'état actuel, lecture seule)
> Feuille de route correspondante : docs/PROJECT_PLAN.md P3 — « Étendre les 7 pages HarmonyOS aux parcours principaux (paiement/réparation/annonce/visiteur/stationnement), adaptation mobile du portail Flutter »

## I. État actuel du portail propriétaires HarmonyOS (apps/harmonyos, 7 pages)

| Page | Route (enregistrée dans main_pages.json) | API appelées |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | Connexion (AuthService) |
| HomePage | pages/HomePage | GET /service/v1/home (tableau de bord : impayés/demandes/nombre de biens + liste des annonces) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/v1/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/v1/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/v1/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/v1/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/v1/profile、POST /service/v1/profile/logout |

**Navigation actuelle** (seulement 4 transitions dans toute l'application) : Login→Home、Home→Login (déconnexion)、Profile→Login、RepairList→RepairSubmit. HomePage ne contient que des cartes statistiques + la liste des annonces, sans grille d'entrées fonctionnelles ; FeeBills/Announcement/Profile existent mais **sans entrée, inaccessibles**.

## II. Correspondance des parcours principaux HarmonyOS

| Parcours principal | État actuel | Type d'écart |
|---------|------|---------|
| Paiement | Page présente, API fonctionnelle | Purement front-end : Home sans entrée (inaccessible) |
| Réparation | Listes + page de soumission présentes, API fonctionnelle | Purement front-end : Home sans entrée (inaccessible) |
| Annonce | Page présente, API fonctionnelle | Purement front-end : Home sans entrée (inaccessible) |
| Visiteur | Page manquante | Nouvelle page à créer (API existantes : GET/POST/PUT/DELETE /visitor*) |
| Stationnement | Page manquante | Nouvelle page à créer (API existantes : /parking/vehicles、/parking/spaces、/parking/records) |

Aucune lacune côté backend : les API service des 5 parcours principaux sont toutes prêtes (fees/repairs/announcements en routes permanentes ; parking/visitors dans l'édition standard). ApiService.ets dispose déjà de get/post/put/delete génériques, les nouvelles pages peuvent les réutiliser directement.

## III. État actuel du portail propriétaires Flutter (apps/flutter, 13 modules)

**Liste des pages** : login、home、fee、repair、parking×3、visitor×2、activity、notification、vote、mall×3、chat、face、profile — toutes enregistrées en routes (app.dart getPages), les 5 parcours principaux sont entièrement implémentés.

**Problèmes d'adaptation mobile** : seuls home_page / login_page utilisent LayoutBuilder/MediaQuery avec points de rupture réactifs ; **10 pages codent en dur une largeur de bureau**, sur une largeur de téléphone (<400px) un débordement RenderFlex est inévitable :

| Page | Largeur codée en dur |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | Aucun traitement de point de rupture (problème similaire attendu, non vérifié ligne par ligne) |

Par ailleurs : pas de barre de navigation inférieure (BottomNavigationBar), l'accès passe par AppBar + grille ; le padding des pages à 24 est orienté bureau. L'i18n bilingue est déjà en place.

## IV. Liste des écarts (catégorie + charge de travail)

### Dépend du backend (aucune)

### Purement front-end

| # | Élément | Charge |
|---|----|--------|
| 1 | Ajouter une grille d'entrées fonctionnelles sur HarmonyOS HomePage (sur le modèle des 12 entrées de la version Flutter), connecter paiement/réparation/annonce/visiteur/stationnement/espace personnel | M |
| 2 | Nouvelle page VisitorPage HarmonyOS (liste + création, réutilise VisitorController) | M |
| 3 | Nouvelle page ParkingPage HarmonyOS (véhicules/places/enregistrements, réutilise ParkingController) | M |
| 4 | Éliminer les largeurs codées en dur du portail Flutter (600/800/480 → contrainte dans maxWidth ou passage à ConstrainedBox) | S |
| 5 | Ajouter la barre de navigation inférieure + padding compact au portail Flutter (si l'acceptation mobile est visée) | M |

### À intégrer

| # | Élément | Charge |
|---|----|--------|
| 6 | Vérifier sur HarmonyOS appareil réel/émulateur la chaîne complète paiement→règlement, soumission de réparation, enregistrement de visiteur | S (contraint par l'équipement de test, risque déjà listé dans PROJECT_PLAN) |

## V. Ordre d'implémentation suggéré

1. Écart 1 (meilleur rapport coût/bénéfice : réutilise les 3 pages existantes, zéro nouvelle page)
2. Écart 4 (le débordement Flutter est un vrai problème, plantage garanti sur mobile)
3. Écarts 2, 3 (nouvelles pages)
4. Écart 5 (optimisation de l'expérience)
5. Écart 6 (nécessite du matériel, à mener indépendamment)
