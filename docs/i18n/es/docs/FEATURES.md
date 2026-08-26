# Documento de Funciones (Features)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Lista de funciones

| N.º | Módulo | Lote | Panel de administración | Portal de propietarios | Tablas de datos |
|------|------|---------|---------|--------|--------|
| 1 | Gestión de comunidades | Lote 1 | CRUD + búsqueda con paginación | Ver comunidad vinculada | erik_community |
| 2 | Gestión de edificios | Lote 1 | CRUD + filtro por comunidad | - | erik_building |
| 3 | Gestión de unidades | Lote 1 | CRUD + filtro por edificio | - | erik_unit |
| 4 | Gestión de tipos de vivienda | Lote 1 | CRUD | - | erik_room_type |
| 5 | Gestión de propiedades | Lote 1 | CRUD + árbol de viviendas + vinculación masiva de propietarios | Mi lista de propiedades/detalles | erik_room |
| 6 | Gestión de propietarios | Lote 1 | CRUD + importación masiva/habilitar-deshabilitar/eliminar | Registro/inicio de sesión/información personal | erik_owner, erik_room_owner |
| 7 | Gestión de inquilinos | Lote 1 | CRUD + filtro por propiedad | - | erik_tenant |
| 8 | Gestión de cargos | Lote 1 | CRUD de tipos de cargo + gestión de facturas + generación masiva + cobro offline | Consulta de facturas + pago en línea + estadísticas de cargos | erik_fee_type, erik_fee_bill, erik_fee_payment |
| 9 | Gestión de reparaciones | Lote 1 | Lista de reparaciones + asignación + actualización de progreso | Enviar reparación + ver progreso + evaluar | erik_repair_order, erik_repair_progress |
| 10 | Avisos y notificaciones | Lote 1 | CRUD + publicar/fijar | Lista/detalles de avisos | erik_announcement |
| 11 | Gestión de estacionamiento | Lote 2 | Gestión de espacios/vehículos + registros de estacionamiento | Mis espacios/vehículos + registros de estacionamiento | erik_parking_space, erik_parking_vehicle, erik_parking_record |
| 12 | Gestión de equipos | Lote 2 | Registro de equipos + registros de mantenimiento | - | erik_equipment, erik_equipment_maintenance |
| 13 | Quejas y sugerencias | Lote 2 | Lista de quejas + gestión + seguimiento | Enviar queja + ver progreso + evaluar | erik_complaint |
| 14 | Gestión de visitantes | Lote 2 | Aprobación de visitantes + consulta de registros | Reserva de visitante + código de paso | erik_visitor |
| 15 | Gestión de contratos | Lote 2 | CRUD + gestión de estado | - | erik_contract |
| 16 | Gestión financiera | Lote 2 | Gestión de ingresos/gastos + informes estadísticos | - | erik_finance_income, erik_finance_expense |
| 17 | Patrullaje de seguridad | Lote 3 | Rutas de patrullaje + registros de patrullaje | - | erik_security_patrol, erik_patrol_record |
| 18 | Gestión de limpieza | Lote 3 | Zonas de limpieza + registros de limpieza | - | erik_cleaning_area, erik_cleaning_record |
| 19 | Gestión de jardinería | Lote 3 | Zonas verdes + registros de mantenimiento | - | erik_green_area, erik_green_maintenance |
| 20 | Actividades comunitarias | Lote 3 | Gestión de actividades + ver inscripciones | Lista de actividades + inscripción | erik_community_activity, erik_activity_signup |
| 21 | Gestión de energía | Lote 3 | Gestión de medidores + registros de lectura | - | erik_energy_meter, erik_energy_record |
| 22 | Gestión de empleados | Lote 3 | CRUD + gestión de estado | - | erik_staff |

## Funciones extendidas (Lote 4 — 12 módulos)

| N.º | Módulo | Panel de administración | Portal de propietarios | Tablas de datos |
|------|------|---------|--------|--------|
| 23 | Notificaciones de mensajes | CRUD de plantillas + envío manual + lista | Mis mensajes + marcar como leído | erik_notification_template, erik_notification |
| 24 | Flujo de aprobación | Tipos de aprobación + instancias + flujo de pasos | - | erik_approval_type, erik_approval, erik_approval_record |
| 25 | Integración de pagos | Gestión de órdenes + reembolsos + callbacks de WeChat/Alipay | - | erik_payment_order |
| 26 | Votaciones de propietarios | CRUD de votaciones + opciones + estadísticas ponderadas por área | Lista de votaciones + votar + ponderación por área | erik_vote, erik_vote_option, erik_vote_record |
| 27 | Escalado automático SLA | Configuración de reglas + verificación de timeout + multas | - | erik_sla_rule, erik_sla_record |
| 28 | Cobros inteligentes | Configuración de estrategias + coincidencia de morosidad + recargos | - | erik_collection_strategy, erik_collection_record |
| 29 | Inspección móvil | Asignación de tareas + registro GPS + fotos | - | erik_inspection_task, erik_inspection_checkpoint |
| 30 | Tienda comunitaria | Gestión de categorías/productos/órdenes/envíos | Ver productos + realizar pedidos + mis órdenes | erik_mall_category, erik_mall_product, erik_mall_order |
| 31 | Reconocimiento facial | Gestión de revisión | Registro facial + estado de autenticación | erik_face_info |
| 32 | Gestión de grupos | CRUD de grupos + asociación de comunidades + resumen multicomunidad | - | erik_group, erik_group_community |
| 33 | Q&A inteligente | Base de conocimiento + historial de conversaciones + estadísticas | Preguntar + coincidencia de palabras clave | erik_knowledge_base, erik_chat_record |
| - | Pantalla de datos | Visualización en pantalla completa de datos de propiedades en tiempo real | - | (reutiliza interfaces de datos existentes) |

## Módulos del panel de administración (ya existentes en admin)

| Módulo | Función |
|------|------|
| Panel | Estadísticas en tiempo real/tendencias/distribución/logs (caché Redis de 5m) |
| Gestión de usuarios | CRUD de usuarios administradores + eliminación masiva/habilitar-deshabilitar + importación Excel |
| Roles y permisos | CRUD + árbol de permisos + autorización RBAC method.path |
| Configuración del sistema | CRUD de pares clave-valor |
| Auditoría de operaciones | Consulta de logs + detección automática de 8 orígenes de plataforma |
| Gestión de archivos | Carga + exportación Excel/PDF (enmascaramiento de datos sensibles) |
| Gestión de seguridad | Defensa en profundidad de 18 capas + security.txt |
| Monitoreo operativo | Verificación de salud + métricas Prometheus + documentación de API |
| Internacionalización | Bilingüe chino/inglés, PHP symfony/translation + Flutter GetX Translations + calificadores de recursos HarmonyOS |
| Documentación de API | Generada automáticamente por `hg/apidoc`, admin 10 grupos + service 9 grupos, organizada por módulo funcional |

## Funciones transversales

### Cifrado de ID en transmisión
Los campos ID en todas las solicitudes y respuestas de API se codifican/decodifican con `erikwang2013/hashids`. El cliente recibe cadenas hashid (por ejemplo, `aB3xK9mW2pQ7rT5v`), el backend las decodifica a BIGINT para operar.

### Protección de datos sensibles
- Capa de transmisión API: `erikwang2013/encryption` — AES-256-CBC
- Capa de almacenamiento en base de datos: `erikwang2013/encryptable` — cifrado/descifrado automático con Eloquent Model casts
- Capa de presentación del frontend: teléfono 138****1234, correo a***@e.com

### Auditoría de operaciones
Todas las operaciones POST/PUT/DELETE del panel de administración se registran automáticamente, incluyendo usuario operador, IP, ruta, parámetros (enmascarados), hora de operación y origen (web/ios/android/harmonyos/windows/macos/linux/ipados).

### Control de permisos
- Panel de administración: autorización RBAC con granularidad method.path; el superadministrador `*` omite la verificación
- Portal de propietarios: autenticación JWT Bearer Token; el propietario solo puede operar sus propios datos

### Protección de seguridad
Defensa en profundidad de 18 capas: código de verificación → confirmación de contraseña → verificación aleatoria → escaneo de seguridad → intercepción de ataques → cifrado de transmisión → JWT → control de sesión → bloqueo de cuenta → RBAC → límite de velocidad → protección de ID → cifrado de solicitud → cifrado de almacenamiento → enmascaramiento de presentación → auditoría → CSP → marca de agua de copyright

### Funciones de exportación
- Excel: PhpSpreadsheet, encabezado azul con texto blanco + primera fila congelada + filtro automático + enmascaramiento de datos sensibles
- PDF: Dompdf A4 horizontal, copyright en el encabezado + marca de agua de copyright irremovible en el pie
- Exportación de visualización de panel en PDF

### Motor de búsqueda
- Impulsado por `erikwang2013/webman-scout` sobre Elasticsearch
- Sincronización automática de índices (los cambios CRUD se envían automáticamente)
- Prefijo de índice `erik_`, consistente con el prefijo de tablas de base de datos

### Internacionalización (i18n)
- **Backend PHP**: symfony/translation — `resource/translations/{zh_CN,en}/messages.php`, 42 claves de traducción, los controladores obtienen traducciones mediante `__()`
- **Flutter Web**: GetX `Translations` — `lib/i18n/messages.dart`, 101 claves de traducción, las páginas usan la extensión `.tr`
- **HarmonyOS**: calificadores de recursos `resources/{base,en_US}/element/string.json`
- **Idioma predeterminado**: chino simplificado (zh_CN), idioma de respaldo inglés (en)
- **Encabezado de solicitud**: admite `Accept-Language` para controlar el idioma de respuesta

### Cobertura de pruebas
- **Framework de pruebas**: PHPUnit 12.x
- **Proceso TDD**: rojo→verde→refactorizar, primero la prueba, luego el código
- **Panel de administración**: 60 pruebas, 164 aserciones, cubre servicios base, configuración de entorno, verificación de seguridad
- **Portal de propietarios**: 18 pruebas, 45 aserciones, 100% de aprobación
- **Total**: 78 pruebas, 209 aserciones
- **Alcance de cobertura**: unicidad de generación de ID Snowflake, codificación/decodificación Hashids de ida y vuelta, formato de respuesta unificado, verificación del esquema de 64 tablas, consistencia de claves de traducción chino/inglés
- **Flutter**: flutter analyze con cero problemas
- **Documentación de API**: generada automáticamente por `hg/apidoc`, admin (10 grupos) + service (9 grupos), documentación de interfaces organizada por módulo funcional
