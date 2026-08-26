# Documentación de API (API Reference)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## Resumen

- Las API del panel de administración se ejecutan en `http://localhost:8787`
- Las API del portal de propietarios se ejecutan en `http://localhost:8788`
- Formato de respuesta unificado: `{"code": 0, "message": "success", "data": {...}}`
- Todos los campos ID se transmiten codificados con hashids
- La versión de API se controla mediante el encabezado de solicitud `API-Version` (por defecto `v1`)
- El idioma se controla mediante el encabezado de solicitud `Accept-Language` (`zh-CN` / `en-US`, por defecto `zh-CN`)

### Documentación de API en línea

Tras iniciar el servicio, acceda a la documentación interactiva generada automáticamente por `hg/apidoc`:

| Extremo | Dirección | Número de grupos |
|----|------|--------|
| Panel de administración | `http://localhost:8787/apidoc` | 10 grupos (common/dashboard/system/property-core/property-aux/property-adv/extensions/export/import/upload) |
| Portal de propietarios | `http://localhost:8788/apidoc` | 9 grupos (interfaces públicas/inicio/cargos/reparaciones/comentarios/estacionamiento/actividades/personal/extensiones) |

---

## API del panel de administración (admin :8787)

### Interfaces públicas — sin autenticación

#### POST /api/captcha/generate
Obtener el código de verificación de clic.

Parámetros de solicitud: ninguno

Respuesta:
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
Validar el código de verificación de clic.

Parámetros de solicitud:
| Parámetro | Tipo | Descripción |
|------|------|------|
| key | string | Clave del código de verificación, devuelta por generate |
| clicks | array | Coordenadas de clic [{x, y}, ...] |

Respuesta:
```json
{
  "code": 0,
  "data": { "valid": true }
}
```

Cuando la validación falla, `code` es 422 y `data.valid` es `false`.

#### POST /api/auth/login
Inicio de sesión de administrador.

Parámetros de solicitud:
| Parámetro | Tipo | Descripción |
|------|------|------|
| username | string | Nombre de usuario |
| password | string | Contraseña |
| captcha_key | string | Clave del código de verificación |
| clicks | array | Coordenadas de clic [{x, y}, ...] |

Respuesta:
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
Refrescar el Token.

Parámetros de solicitud:
| Parámetro | Tipo | Descripción |
|------|------|------|
| refresh_token | string | Token de refresco |

Respuesta:
```json
{
  "code": 0,
  "data": { "access_token": "eyJ..." }
}
```

#### GET /health
Verificación de salud.

#### GET /metrics
Métricas de monitoreo Prometheus.

#### GET /api/docs
Documentación OpenAPI.

---

### Interfaces del panel de administración — requieren autenticación (Bearer Token)

Todas las interfaces tienen prefijo `/admin` y requieren el encabezado `Authorization: Bearer {access_token}`.

#### Panel

**GET /admin/dashboard**
Obtener los datos estadísticos del panel.

#### Gestión de usuarios administradores

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/user | Lista de usuarios (?keyword=&status=&page=&page_size=) |
| POST | /admin/user | Crear usuario |
| GET | /admin/user/{hashid} | Detalle de usuario |
| PUT | /admin/user/{hashid} | Actualizar usuario |
| DELETE | /admin/user/{hashid} | Eliminar usuario (requiere confirmación de contraseña) |
| POST | /admin/user/batch/destroy | Eliminación masiva |
| POST | /admin/user/batch/status | Habilitar/deshabilitar masivo |
| POST | /admin/import/users | Importación de usuarios desde Excel |

#### Gestión de roles y permisos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/role | Lista de roles |
| POST | /admin/role | Crear rol |
| GET | /admin/role/{hashid} | Detalle de rol |
| PUT | /admin/role/{hashid} | Actualizar rol |
| DELETE | /admin/role/{hashid} | Eliminar rol |
| GET | /admin/permission | Lista de permisos (árbol) |
| POST | /admin/permission | Crear permiso |
| PUT | /admin/permission/{hashid} | Actualizar permiso |
| DELETE | /admin/permission/{hashid} | Eliminar permiso |

#### Configuración del sistema

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/config | Lista de configuración (?group=) |
| POST | /admin/config | Crear configuración |
| PUT | /admin/config/{hashid} | Actualizar configuración |
| DELETE | /admin/config/{hashid} | Eliminar configuración |

#### Logs de operaciones

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/log | Lista de logs (?user_id=&action=&method=&source=&start_date=&end_date=) |

#### Centro personal

| Método | Ruta | Descripción |
|------|------|------|
| PUT | /admin/profile | Modificar información personal |
| PUT | /admin/profile/password | Cambiar contraseña |
| POST | /admin/profile/logout | Cerrar sesión |

#### Exportación

| Método | Ruta | Descripción |
|------|------|------|
| POST | /admin/export/excel | Exportar Excel ({ table, columns, conditions, title }) |
| POST | /admin/export/pdf | Exportar PDF ({ type, title, data }) |

---

### Gestión de propiedades — interfaces del panel de administración

#### Gestión de comunidades

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/community | Lista (?keyword=&status=) |
| POST | /admin/community | Crear |
| GET | /admin/community/{hashid} | Detalle |
| PUT | /admin/community/{hashid} | Actualizar |
| DELETE | /admin/community/{hashid} | Eliminar (requiere contraseña) |

#### Gestión de edificios

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/building | Lista (?community_id=&keyword=) |
| POST | /admin/building | Crear |
| GET | /admin/building/{hashid} | Detalle |
| PUT | /admin/building/{hashid} | Actualizar |
| DELETE | /admin/building/{hashid} | Eliminar |

#### Gestión de unidades

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/unit | Lista (?building_id=) |
| POST | /admin/unit | Crear |
| GET | /admin/unit/{hashid} | Detalle |
| PUT | /admin/unit/{hashid} | Actualizar |
| DELETE | /admin/unit/{hashid} | Eliminar |

#### Gestión de tipos de vivienda

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/room-type | Lista |
| POST | /admin/room-type | Crear |
| GET | /admin/room-type/{hashid} | Detalle |
| PUT | /admin/room-type/{hashid} | Actualizar |
| DELETE | /admin/room-type/{hashid} | Eliminar |

#### Gestión de propiedades

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/room | Lista (?community_id=&building_id=&unit_id=&status=) |
| POST | /admin/room | Crear |
| GET | /admin/room/{hashid} | Detalle |
| PUT | /admin/room/{hashid} | Actualizar |
| DELETE | /admin/room/{hashid} | Eliminar |
| GET | /admin/room/tree | Árbol de viviendas (comunidad→edificio→unidad→vivienda) |

#### Gestión de propietarios

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/owner | Lista (?keyword=&status=) |
| POST | /admin/owner | Crear |
| GET | /admin/owner/{hashid} | Detalle (incluye propiedades vinculadas) |
| PUT | /admin/owner/{hashid} | Actualizar |
| DELETE | /admin/owner/{hashid} | Eliminar (requiere contraseña) |
| POST | /admin/owner/batch/import | Importación masiva desde Excel |
| POST | /admin/owner/batch/destroy | Eliminación masiva |

#### Gestión de inquilinos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/tenant | Lista (?room_id=&status=) |
| POST | /admin/tenant | Crear |
| GET | /admin/tenant/{hashid} | Detalle |
| PUT | /admin/tenant/{hashid} | Actualizar |
| DELETE | /admin/tenant/{hashid} | Eliminar |

#### Tipos de cargo

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/fee-type | Lista |
| POST | /admin/fee-type | Crear |
| GET | /admin/fee-type/{hashid} | Detalle |
| PUT | /admin/fee-type/{hashid} | Actualizar |
| DELETE | /admin/fee-type/{hashid} | Eliminar |

#### Gestión de facturas

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/fee-bill | Lista (?community_id=&status=&due_date_start=&due_date_end=) |
| POST | /admin/fee-bill | Crear factura |
| GET | /admin/fee-bill/{hashid} | Detalle |
| PUT | /admin/fee-bill/{hashid} | Actualizar |
| DELETE | /admin/fee-bill/{hashid} | Eliminar |
| POST | /admin/fee-bill/batch/generate | Generación masiva de facturas |

#### Registros de pago

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/fee-payment | Lista (?bill_id=&payment_method=&date_start=&date_end=) |
| POST | /admin/fee-payment/offline | Registro de cobro offline |

#### Gestión de reparaciones

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/repair | Lista (?status=&category=) |
| POST | /admin/repair | Crear |
| GET | /admin/repair/{hashid} | Detalle (incluye registros de progreso) |
| PUT | /admin/repair/{hashid} | Actualizar |
| DELETE | /admin/repair/{hashid} | Eliminar |
| PUT | /admin/repair/{id}/assign | Asignación ({ staff_id }) |
| POST | /admin/repair/{id}/progress | Actualizar progreso ({ status_to, remark }) |

#### Gestión de avisos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/announcement | Lista (?community_id=&category=&is_published=) |
| POST | /admin/announcement | Crear |
| GET | /admin/announcement/{hashid} | Detalle |
| PUT | /admin/announcement/{hashid} | Actualizar |
| DELETE | /admin/announcement/{hashid} | Eliminar |

#### Gestión de estacionamiento

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/parking-space | Lista (?community_id=) |
| POST | /admin/parking-space | Crear espacio |
| PUT | /admin/parking-space/{hashid} | Actualizar |
| DELETE | /admin/parking-space/{hashid} | Eliminar |
| GET | /admin/parking-vehicle | Lista (?owner_id=&space_id=) |
| POST | /admin/parking-vehicle | Crear vehículo |
| PUT | /admin/parking-vehicle/{hashid} | Actualizar |
| DELETE | /admin/parking-vehicle/{hashid} | Eliminar |
| GET | /admin/parking-record | Registros de estacionamiento (?vehicle_id=&date_start=&date_end=) |

#### Gestión de equipos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/equipment | Lista (?community_id=&category=&status=) |
| POST | /admin/equipment | Crear |
| PUT | /admin/equipment/{hashid} | Actualizar |
| DELETE | /admin/equipment/{hashid} | Eliminar |
| GET | /admin/equipment-maintenance | Registros de mantenimiento (?equipment_id=) |
| POST | /admin/equipment-maintenance | Crear mantenimiento |

#### Gestión de quejas

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/complaint | Lista (?type=&status=) |
| GET | /admin/complaint/{hashid} | Detalle |
| PUT | /admin/complaint/{id}/handle | Gestionar ({ handler_remark }) |
| POST | /admin/complaint/{id}/visit | Seguimiento ({ visitor_remark }) |

#### Aprobación de visitantes

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/visitor | Lista (?status=) |
| PUT | /admin/visitor/{id}/approve | Aprobar |

#### Gestión de contratos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/contract | Lista (?contract_type=&status=) |
| POST | /admin/contract | Crear |
| PUT | /admin/contract/{hashid} | Actualizar |
| DELETE | /admin/contract/{hashid} | Eliminar |

#### Gestión financiera

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/finance-income | Lista de ingresos (?income_type=&date_start=&date_end=) |
| POST | /admin/finance-income | Registrar ingreso |
| GET | /admin/finance-expense | Lista de gastos |
| POST | /admin/finance-expense | Registrar gasto |
| GET | /admin/finance/statistics | Estadísticas de ingresos/gastos mensuales (?year=) |

#### Panel de propiedades

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/dashboard/property | Estadísticas de propiedades (por cobrar/tasa de ocupación/reparaciones/quejas/tendencias de ingresos y gastos) |
| POST | /admin/export/property-excel | Exportación de datos de propiedades a Excel ({ type: owners|bills }) |

#### Patrullaje de seguridad

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/security-patrol | Lista (?community_id=) |
| POST | /admin/security-patrol | Crear ruta |
| GET | /admin/patrol-record | Registros (?patrol_id=&staff_id=) |
| POST | /admin/patrol-record | Crear registro |

#### Gestión de limpieza

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/cleaning-area | Lista de zonas |
| POST | /admin/cleaning-area | Crear zona |
| GET | /admin/cleaning-record | Registros (?area_id=) |
| POST | /admin/cleaning-record | Crear registro |

#### Gestión de jardinería

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/green-area | Lista de zonas |
| POST | /admin/green-area | Crear zona |
| GET | /admin/green-maintenance | Registros de mantenimiento (?area_id=) |
| POST | /admin/green-maintenance | Crear registro |

#### Actividades comunitarias

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/activity | Lista (?status=) |
| POST | /admin/activity | Crear actividad |
| PUT | /admin/activity/{hashid} | Actualizar |
| DELETE | /admin/activity/{hashid} | Eliminar |
| GET | /admin/activity-signup | Lista de inscripciones (?activity_id=) |
| PUT | /admin/activity-signup/{id}/checkin | Registro de asistencia |

#### Gestión de energía

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/energy-meter | Lista de medidores (?room_id=&meter_type=) |
| POST | /admin/energy-meter | Crear medidor |
| GET | /admin/energy-record | Registros de lectura (?meter_id=&date_start=&date_end=) |
| POST | /admin/energy-record | Crear registro |

#### Gestión de empleados

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/staff | Lista (?community_id=&status=) |
| POST | /admin/staff | Crear |
| PUT | /admin/staff/{hashid} | Actualizar |
| DELETE | /admin/staff/{hashid} | Eliminar |
| POST | /admin/staff/batch/status | Habilitar/deshabilitar masivo |

#### Notificaciones de mensajes

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/notification-template | Lista de plantillas |
| POST | /admin/notification-template | Crear plantilla |
| PUT | /admin/notification-template/{hashid} | Actualizar plantilla |
| DELETE | /admin/notification-template/{hashid} | Eliminar plantilla |
| GET | /admin/notification | Lista de mensajes (?type=&is_read=) |
| POST | /admin/notification/send | Envío manual de notificaciones |

#### Flujo de aprobación

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/approval-type | Lista de tipos de aprobación |
| POST | /admin/approval-type | Crear tipo de aprobación |
| GET | /admin/approval | Lista de aprobaciones (?status=) |
| GET | /admin/approval/{hashid} | Detalle de aprobación |
| POST | /admin/approval | Enviar aprobación |
| PUT | /admin/approval/{hashid}/approve | Aprobar (aprobar/rechazar) |

#### Gestión de pagos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/payment-order | Lista de órdenes |
| GET | /admin/payment-order/{hashid} | Detalle de orden |
| POST | /admin/payment-order/{hashid}/refund | Reembolso |
| GET | /admin/payment/statistics | Estadísticas de pagos |

#### Votaciones de propietarios

| Método | Ruta | Descripción |
|------|------|------|
| GET | /admin/vote | Lista de votaciones (?status=) |
| POST | /admin/vote | Crear votación |
| GET | /admin/vote/{hashid}/statistics | Estadísticas de recuento |
| PUT | /admin/vote/{hashid}/publish | Publicar votación |
| PUT | /admin/vote/{hashid}/end | Finalizar votación |

#### Gestión SLA · Cobros inteligentes · Gestión de inspección · Gestión de tienda · Gestión facial · Gestión de grupos · Base de conocimiento

(Los endpoints completos se encuentran en el archivo `docs/API.md`)

---

## API del portal de propietarios (service :8788)

### Interfaces públicas — sin autenticación

#### POST /api/captcha/generate
Obtener el código de verificación de clic. (Igual que en el panel de administración)

#### POST /api/captcha/verify
Validar el código de verificación de clic. (Solicitud/respuesta igual que en el panel de administración)

#### POST /api/auth/login
Inicio de sesión de propietario.

Parámetros de solicitud:
| Parámetro | Tipo | Descripción |
|------|------|------|
| phone | string | Teléfono |
| password | string | Contraseña |
| captcha_key | string | Clave del código de verificación |
| clicks | array | Coordenadas de clic |

Respuesta:
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
Registro de propietario.

Parámetros de solicitud:
| Parámetro | Tipo | Descripción |
|------|------|------|
| phone | string | Teléfono |
| password | string | Contraseña (mínimo 6 caracteres) |
| name | string | Nombre |
| captcha_key | string | Clave del código de verificación |
| clicks | array | Coordenadas de clic |
| room_id | string | (Opcional) hashid de la vivienda a vincular |
| id_card_last4 | string | (Opcional) últimos 4 dígitos del documento de identidad |

#### POST /api/auth/refresh
Refrescar el Token.

---

### Interfaces del portal de propietarios — requieren autenticación (Bearer Token)

Todas las interfaces tienen prefijo `/service` y requieren el encabezado `Authorization: Bearer {access_token}`.

#### Inicio

**GET /service/home**

Respuesta:
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

#### Mis propiedades

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/rooms | Lista de mis propiedades |
| GET | /service/room/{hashid} | Detalle de propiedad (incluye área, orientación, titularidad, información de comunidad) |

#### Gestión de cargos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/fees/bills | Lista de facturas (?status=0 sin pagar/1 parcial/2 pagada/3 vencida) |
| GET | /service/fees/bill/{hashid} | Detalle de factura (incluye tipo de cargo, registros de pago) |
| GET | /service/fees/payments | Registros de pago |
| POST | /service/fees/pay | Pago en línea ({ bill_id, payment_method, password }) |
| GET | /service/fees/statistics | Estadísticas de cargos (?year=2026) |

#### Reparaciones

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/repairs | Lista de reparaciones (?status=) |
| GET | /service/repair/{hashid} | Detalle de reparación (incluye línea de tiempo de progreso) |
| POST | /service/repair | Enviar reparación ({ room_id, category, urgency, description, images[], scheduled_at }) |
| DELETE | /service/repair/{hashid} | Cancelar (requiere contraseña, { password }) |
| POST | /service/repair/{hashid}/rate | Evaluar ({ rating: 1-5, feedback }) |

#### Quejas y sugerencias

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/complaints | Lista de quejas |
| GET | /service/complaint/{hashid} | Detalle de queja (incluye progreso del tratamiento) |
| POST | /service/complaint | Enviar queja ({ type, category, title, content, is_anonymous, images[] }) |
| POST | /service/complaint/{hashid}/satisfaction | Evaluación de satisfacción ({ satisfaction: 1-5 }) |

#### Avisos

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/announcements | Lista de avisos (?category=) |
| GET | /service/announcement/{hashid} | Detalle de aviso |

#### Estacionamiento

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/parking/vehicles | Mis vehículos |
| GET | /service/parking/spaces | Mis espacios |
| GET | /service/parking/records | Registros de estacionamiento |

#### Visitantes

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/visitors | Mis reservas de visitantes |
| POST | /service/visitor | Crear reserva (genera código de paso) |
| PUT | /service/visitor/{hashid} | Modificar reserva |
| DELETE | /service/visitor/{hashid} | Cancelar reserva |

#### Actividades comunitarias

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/activities | Lista de actividades (?status=) |
| GET | /service/activity/{hashid} | Detalle de actividad |
| POST | /service/activity/{hashid}/signup | Inscribirse |
| POST | /service/activity/{hashid}/cancel | Cancelar inscripción |

#### Información personal

| Método | Ruta | Descripción |
|------|------|------|
| GET | /service/profile | Información personal |
| PUT | /service/profile | Modificar ({ name, email, gender, birthday }) |
| PUT | /service/profile/password | Cambiar contraseña ({ old_password, new_password }) |
| POST | /service/profile/logout | Cerrar sesión |

---

## API abierta — autenticación con API Key

Interfaces de entrada de solo lectura para sistemas externos (integración de plataformas de propiedades, pantalla de datos, etc.). Prefijo `/open`, todas de solo lectura.

### Método de autenticación

Cada solicitud debe incluir el encabezado `X-API-Key` con el valor de la Key generada por `scripts/gen_api_key.php` (hex de 64 bits; en la base solo se almacena el resumen SHA-256):

```bash
curl -H "X-API-Key: <su Key>" http://localhost:8788/open/announcements
```

- Key faltante o incorrecta devuelve `401` (`{"code":401,"message":"无效的API Key","data":[]}`)
- Gestión de Keys: generar con `php scripts/gen_api_key.php [--name=uso]`; para deshabilitar/eliminar operar directamente en la tabla `erik_api_key` (`status=0` deshabilita, la Key deja de ser válida inmediatamente)

### Endpoints

#### GET /open/announcements — lista de avisos

Parámetros: `page` (por defecto 1), `category` (opcional). La estructura de respuesta es idéntica a `/service/announcements`.

```bash
curl -H "X-API-Key: <su Key>" "http://localhost:8788/open/announcements?page=1"
```

#### GET /open/bills — consulta de facturas

Parámetros: `bill_number` (obligatorio, número de factura). Devuelve el detalle de una sola factura (incluye tipo de cargo, número de vivienda, monto adeudado). Si no existe, devuelve 404.

```bash
curl -H "X-API-Key: <su Key>" "http://localhost:8788/open/bills?bill_number=B202608160001"
```

#### GET /open/repairs — consulta de estado de reparación

Parámetros: `order_number` (obligatorio, número de orden de reparación). Devuelve el estado actual de la orden de reparación y la línea de tiempo de progreso (matriz `progress`). Si no existe, devuelve 404.

```bash
curl -H "X-API-Key: <su Key>" "http://localhost:8788/open/repairs?order_number=R202608160001"
```

---

## Códigos de error

| code | Significado | Descripción |
|------|------|------|
| 0 | Éxito | Respuesta normal |
| 400 | Error de solicitud | Formato de parámetros incorrecto |
| 401 | No autenticado | Token faltante/expirado/inválido/añadido a la lista negra |
| 403 | Sin permisos | El rol del usuario no incluye el permiso requerido / cuenta deshabilitada |
| 404 | No existe | Recurso no encontrado |
| 405 | Método no permitido | Método HTTP distinto de GET/POST/PUT/DELETE/OPTIONS |
| 413 | Cuerpo de solicitud demasiado grande | Supera 10MB |
| 415 | Tipo de medio no soportado | Content-Type no es JSON ni form-urlencoded |
| 422 | Fallo de validación | Los parámetros del formulario no cumplen las reglas / fallo de confirmación de contraseña / error de código de verificación |
| 429 | Demasiadas solicitudes | Límite de velocidad activado / cuenta bloqueada |
| 500 | Error del servidor | Excepción inesperada |

## Cabeceras de respuesta de límite de velocidad

Al activarse el límite de velocidad se devuelve 429 y las cabeceras de respuesta incluyen:

| Cabecera de respuesta | Descripción |
|--------|------|
| X-RateLimit-Limit | Límite de veces |
| X-RateLimit-Remaining | Veces restantes |
| X-RateLimit-Reset | Hora de reinicio (marca de tiempo Unix) |
| Retry-After | Segundos de espera sugeridos para reintentar |
