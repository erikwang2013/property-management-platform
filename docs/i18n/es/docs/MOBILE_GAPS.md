# Lista de Brechas de la Versión Móvil

> Fecha de generación: 2026-08-16 · Fuente: pmp-team ci-agent (P3-③ inventario del estado actual, solo lectura)
> Hoja de ruta correspondiente: docs/PROJECT_PLAN.md P3 — "Ampliar las 7 páginas de HarmonyOS a rutas principales (pagos/reparaciones/avisos/visitantes/estacionamiento), adaptación móvil del portal Flutter de propietarios"

## 1. Estado actual del portal HarmonyOS de propietarios (apps/harmonyos, 7 páginas)

| Página | Ruta (registrada en main_pages.json) | API llamada |
|------|------------------------------|---------|
| LoginPage | pages/LoginPage | Inicio de sesión (AuthService) |
| HomePage | pages/HomePage | GET /service/v1/home (panel: pendientes/órdenes/propiedades + lista de avisos) |
| FeeBillsPage | pages/FeeBillsPage | GET /service/v1/fees/bills?page=1&per_page=50 |
| RepairListPage | pages/RepairListPage | GET /service/v1/repairs |
| RepairSubmitPage | pages/RepairSubmitPage | POST /service/v1/repair |
| AnnouncementPage | pages/AnnouncementPage | GET /service/v1/announcements?page=1&per_page=50 |
| ProfilePage | pages/ProfilePage | GET /service/v1/profile、POST /service/v1/profile/logout |

**Estado de navegación** (solo 4 saltos en toda la app): Login→Home, Home→Login (salir), Profile→Login, RepairList→RepairSubmit. HomePage solo tiene tarjetas de estadísticas + lista de avisos, sin cuadrícula de entradas de funciones; las páginas FeeBills/Announcement/Profile existen pero **no tienen entrada, son inalcanzables**.

## 2. Comparación de rutas principales de HarmonyOS

| Ruta principal | Estado actual | Tipo de brecha |
|---------|------|---------|
| Pagos | Página existe, API funciona | Solo frontend: Home sin entrada (inalcanzable) |
| Reparaciones | Páginas de lista+envío existen, API funciona | Solo frontend: Home sin entrada (inalcanzable) |
| Avisos | Página existe, API funciona | Solo frontend: Home sin entrada (inalcanzable) |
| Visitantes | Falta la página | Necesita nueva página (API ya existe: GET/POST/PUT/DELETE /visitor*) |
| Estacionamiento | Faltan las páginas | Necesita nuevas páginas (API ya existe: /parking/vehicles、/parking/spaces、/parking/records) |

Sin brechas en backend: las API de service de las 5 rutas principales están todas listas (fees/repairs/announcements son rutas permanentes; parking/visitors dentro del control de acceso de la edición Standard). ApiService.ets ya tiene get/post/put/delete genéricos, las nuevas páginas pueden reutilizarlos directamente.

## 3. Estado actual del portal Flutter de propietarios (apps/flutter, 13 módulos)

**Lista de páginas**: login, home, fee, repair, parking×3, visitor×2, activity, notification, vote, mall×3, chat, face, profile — todas registradas en rutas (app.dart getPages), las 5 rutas principales están todas implementadas.

**Problemas de adaptación móvil**: solo home_page / login_page usan LayoutBuilder/MediaQuery con puntos de ruptura responsivos; **10 páginas tienen ancho de escritorio codificado**, con ancho de teléfono (<400px) inevitablemente habrá desbordamiento RenderFlex:

| Página | Codificación fija |
|------|--------|
| chat_page | SizedBox(width: 600) |
| mall_products_page | width: 800 |
| mall_product_detail / mall_orders | SizedBox(width: 600) |
| notification_list | width: 480 + SizedBox(width: 600) |
| vote_list / vote_detail | SizedBox(width: 600) |
| activity_detail、parking_records/vehicles、visitor_list、face_register | Sin manejo de puntos de ruptura (se esperan problemas similares, no verificado línea por línea) |

Además: no hay barra de navegación inferior (BottomNavigationBar); la entrada depende de AppBar + cuadrícula; el padding de página de 24 es más estilo escritorio. El i18n bilingüe ya está disponible.

## 4. Lista de brechas (clasificación + carga de trabajo)

### Depende del backend (ninguna)

### Solo frontend

| # | Elemento | Carga de trabajo |
|---|----|--------|
| 1 | Añadir cuadrícula de entradas de funciones a HomePage de HarmonyOS (comparando las 12 entradas de la versión Flutter), conectando pagos/reparaciones/avisos/visitantes/estacionamiento/centro personal | M |
| 2 | Nueva VisitorPage en HarmonyOS (lista + crear, reutilizando VisitorController) | M |
| 3 | Nueva ParkingPage en HarmonyOS (vehículos/espacios/registros, reutilizando ParkingController) | M |
| 4 | Eliminar anchos codificados en el portal Flutter de propietarios (600/800/480 → restringir dentro de maxWidth o cambiar a ConstrainedBox) | S |
| 5 | Añadir barra de navegación inferior + padding compacto en el portal Flutter de propietarios (si el móvil es el objetivo de aceptación) | M |

### Requiere integración conjunta

| # | Elemento | Carga de trabajo |
|---|----|--------|
| 6 | Verificación en dispositivo real/emulador de HarmonyOS de la cadena completa pago→pago, envío de reparación, registro de visitante | S (limitado por el dispositivo de prueba, PROJECT_PLAN ya enumera este riesgo) |

## 5. Orden de implementación sugerido

1. Brecha 1 (mejor relación costo-beneficio: reutiliza las 3 páginas existentes, cero páginas nuevas)
2. Brecha 4 (el desbordamiento de Flutter es un defecto grave, el móvil se bloqueará)
3. Brechas 2, 3 (páginas nuevas)
4. Brecha 5 (optimización de experiencia)
5. Brecha 6 (requiere dispositivo, avanzar de forma independiente)
