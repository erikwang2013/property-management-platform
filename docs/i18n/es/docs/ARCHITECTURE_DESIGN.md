# Documento de Diseño de Arquitectura (Architecture Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Resumen de la arquitectura del sistema

El sistema de gestión de propiedades adopta una arquitectura por capas de «doble backend + múltiples frontends». El panel de administración (admin) y el portal de propietarios (service) son dos proyectos independientes de webman v2 que trabajan en conjunto compartiendo la base de datos MySQL. El frontend cubre Flutter Web (estilo de panel de administración de PC) y la app móvil HarmonyOS.

### Objetivos de diseño

- **Despliegue independiente**: admin y service se inician/detienen, escalan y gestionan claves de forma independiente
- **Datos compartidos**: comparten la misma base de datos MySQL, evitando problemas de sincronización de datos
- **Normas unificadas**: ambos proyectos siguen las mismas normas de código, estilo de configuración y políticas de seguridad
- **Web con prioridad de PC**: Flutter Web está diseñado con estilo de panel de administración de escritorio (barra lateral + barra superior + área de contenido)

## 2. Arquitectura por capas

```
┌─────────────────────────────────────────────────────────────┐
│                        路由层 (Route Layer)                   │
│   config/route.php — URL → Controller 映射 + 中间件绑定       │
├─────────────────────────────────────────────────────────────┤
│                       中间件层 (Middleware Layer)              │
│   SecurityFilter → RateLimit → ApiVersion → Auth → Permission │
├─────────────────────────────────────────────────────────────┤
│                      控制器层 (Controller Layer)               │
│   BaseController → 请求验证 → ID编解码 → 业务逻辑 → 响应格式化  │
├─────────────────────────────────────────────────────────────┤
│                        服务层 (Service Layer)                  │
│   HashidsService | SnowflakeService | EncryptionService       │
├─────────────────────────────────────────────────────────────┤
│                        模型层 (Model Layer)                    │
│   Eloquent ORM + encryptable 自动加解密 + scout ES 同步        │
├─────────────────────────────────────────────────────────────┤
│                        驱动层 (Driver Layer)                   │
│   MySQL PDO | Elasticsearch HTTP | Redis                      │
└─────────────────────────────────────────────────────────────┘
```

## 3. Cadena de ejecución de middleware

### Panel de administración (admin)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流) 
  → AdminAuth(JWT验证) → AdminPermission(RBAC鉴权)
    → OperationLog(操作记录) → Controller
```

### Portal de propietarios (service)
```
Cors → SecurityFilter(方法检查→405) → RateLimit(限流)
  → ApiVersion(版本校验) → Controller           # /api/* 公开接口
  → ServiceAuth(JWT业主认证) → Controller       # /service/* 认证接口
```

### Explicación del middleware global

| Middleware | Ubicación | Responsabilidad |
|--------|------|------|
| Cors | Primera posición global | Manejo de cabeceras de intercambio de recursos entre orígenes |
| SecurityFilter | Global | Lista blanca de métodos HTTP, intercepción de XSS/inyección SQL/traversal de rutas/inyección de comandos/CSRF, lista negra de IP |
| RateLimit | Global | Límite de velocidad de ventana deslizante Redis (Lua atómico), 60 veces/minuto por defecto |
| ApiVersion | Rutas /api | Validación del encabezado de solicitud API-Version, inyección del número de versión |
| AdminAuth | Rutas /admin | Validación de Token JWT, inyección de adminId |
| AdminPermission | Rutas /admin | Validación de permisos RBAC method.path (caché Redis de 60s) |
| OperationLog | Rutas /admin | Registro automático de operaciones POST/PUT/DELETE (incluye detección de origen) |
| ServiceAuth | Rutas /service | Validación de Token JWT, inyección de ownerId |

## 4. Ciclo de vida completo del ID

```
Generación: SnowflakeService::generate()
      datacenter_id(5bit) + worker_id(5bit) + timestamp(41bit) + sequence(12bit)
      → BIGINT(18) 例: 1750123456789

Almacenamiento: tablas MySQL erik_*
      id BIGINT UNSIGNED NOT NULL（非自增）
      campos sensibles con cast encryptable → almacenamiento cifrado AES-256-CBC

Transmisión: HashidsService::encode(bigint) → cadena hashid 例: aB3xK9mW2pQ7rT5v
      todos los campos ID en solicitudes/respuestas de API usan hashid de forma uniforme

Decodificación: HashidsService::decode(hashid) → BIGINT
      un hashid inválido lanza InvalidArgumentException
```

## 5. Capas de cifrado de datos

### Capa de transmisión (encryption)
- Cifrado AES-256-CBC
- El cliente cifra los datos sensibles antes de enviarlos; el servidor los descifra al recibirlos
- Clave independiente `ENCRYPTION_KEY`

### Capa de almacenamiento (encryptable)
- El mecanismo de `$casts` del modelo cifra/descifra automáticamente
- Campos sensibles: phone, email, id_card, emergency_contact, emergency_phone
- Clave independiente `ENCRYPTABLE_KEY`
- Al escribir se cifra automáticamente a texto cifrado; al leer se descifra automáticamente a texto plano

### Capa de presentación (enmascaramiento)
- Teléfono: `138****1234`
- Correo: `a***@example.com`
- Documento de identidad: `********`
- Enmascaramiento automático en exportaciones Excel/PDF

## 6. Autenticación y permisos

### Autenticación JWT
- Algoritmo: HS256
- access_token: validez de 2 horas
- refresh_token: validez de 14 días
- Límite de concurrencia: máximo 3 Tokens válidos por usuario; al superar, el Token más antiguo se añade a la lista negra
- Bloqueo de cuenta: 5 intentos de inicio de sesión fallidos consecutivos bloquean durante 15 minutos

### Modelo de permisos RBAC
- Usuario → Rol → Permiso (muchos a muchos)
- Tipos de permiso: type=1 (menú) / type=2 (botón) / type=3 (API)
- Formato del identificador de permiso: `{method}.{path}` 例: `get.admin/user`
- Identificador de superadministrador: `*` (omite todas las verificaciones de permisos)
- Árbol de permisos: parent_id auto-referenciado, soporta niveles ilimitados

## 7. Defensa en profundidad de seguridad (18 capas)

```
第1层  点击验证码      → 登录/注册强制人机验证
第2层  密码二次确认    → 敏感操作（删除/缴费/合同终止）必须输入密码
第3层  poster随机验证  → 高频敏感操作随机弹出验证码
第4层  security-php    → 请求周期内自动安全扫描
第5层  SecurityFilter  → XSS/SQL注入/路径遍历/命令注入/CSRF 攻击拦截
第6层  传输安全        → HTTPS + AES-256-CBC
第7层  JWT 认证        → HS256，2h过期 + refresh token
第8层  并发控制        → 同一用户最多3个Token，超出黑名单
第9层  账号锁定        → 连续5次失败锁定15分钟
第10层 RBAC 鉴权       → method.path 粒度权限控制
第11层 限流保护        → Redis 滑动窗口 Lua原子化
第12层 ID 保护         → Hashids 编码，不可逆推真实ID
第13层 请求体加密      → AES-256-CBC 敏感字段
第14层 存储加密        → encryptable DB字段加密
第15层 展示脱敏        → 手机号/邮箱/身份证脱敏
第16层 审计追溯        → OperationLog 全量记录（含来源端 source 自动检测）
第17层 HTTP 头防护     → CSP + X-Permitted-Cross-Domain-Policies
第18层 出口保护        → PDF 版权水印（不可移除）+ Excel 敏感数据脱敏
```

## 8. Política de límite de velocidad

Basada en el algoritmo de ventana deslizante con Redis Sorted Set, ejecución atómica con script Lua:

| Interfaz | Límite |
|------|------|
| Por defecto | 60 veces/minuto/IP/ruta |
| POST /api/auth/login | 10 veces/minuto |
| POST /api/auth/register | 5 veces/minuto |

Al superar el límite se devuelve 429 + cabeceras de respuesta `X-RateLimit-Limit/Remaining/Reset/Retry-After`.

## 9. Política de versiones de API

- La versión se controla mediante el encabezado de solicitud `API-Version` (por defecto `v1`), no aparece en la URL
- Una versión no soportada devuelve 400
- Los controladores se organizan por versión: `app/api/{version}/controller/`
- Añadir una versión nueva solo requiere crear el directorio y registrarlo en el middleware `ApiVersion`

## 10. Arquitectura de despliegue

```
┌─────────────────────────────────────┐
│            CloudFlare DNS + CDN      │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│          Nginx (:443)                │
│   反向代理 + Gzip + SSL 终结         │
│   静态文件: Flutter Web build/       │
└──────┬──────────────────┬───────────┘
       │                  │
┌──────▼──────┐    ┌──────▼──────┐
│ admin webman│    │service webman│
│ :8787       │    │ :8788       │
│ 管理后台API │    │ 业主端API    │
└──────┬──────┘    └──────┬──────┘
       │                  │
       └────────┬─────────┘
                │
┌───────────────┼───────────────────┐
│               │                   │
┌▼──────┐  ┌────▼───┐  ┌──────────▼┐
│MySQL  │  │ Redis  │  │Elasticsearch│
│:3306  │  │ :6379  │  │ :9200      │
└───────┘  └────────┘  └────────────┘
```

### Servicios de Docker Compose

| Servicio | Imagen | Descripción |
|------|------|------|
| nginx | nginx:alpine | Proxy inverso + archivos estáticos |
| admin | Construcción con Dockerfile | PHP 8.3 + OPcache |
| service | Construcción con Dockerfile | PHP 8.3 + OPcache |
| mysql | mysql:8.0 | Persistencia de datos en volumen |
| redis | redis:7-alpine | Caché/límite de velocidad/Sesión |
| elasticsearch | elasticsearch:8.x | Búsqueda de texto completo |

## 11. Diseño de internacionalización (i18n)

### Estructura de archivos de idioma

El sistema soporta chino simplificado (zh_CN) e inglés (en), chino por defecto.

**Backend PHP:**
```
resource/translations/
├── zh_CN/
│   └── messages.php    # Paquete de idioma chino (42+ claves de traducción)
└── en/
    └── messages.php    # Paquete de idioma inglés
```

Impulsado por symfony/translation, configuración en `config/translation.php`:
- `locale`: `zh_CN`
- `fallback_locale`: `['zh_CN', 'en']`
- `path`: `resource/translations`

Los controladores obtienen traducciones mediante `$this->__('key')`:
```php
return $this->success([], $this->__('create_success'));
return $this->fail($this->__('community.name_required'), 422);
```

El método `__()` internamente llama a la función global `trans()` de webman; si la traducción no existe, degrada devolviendo la propia clave.

**Flutter Web:**
```
apps/flutter/lib/i18n/
└── messages.dart       # AppTranslations extends GetX Translations
```

Usa GetX `Translations`, 101 claves de traducción. Se usa mediante la extensión `.tr`:
```dart
Text('login_btn'.tr)   // 中文: "登 录", 英文: "Login"
Text('phone_hint'.tr)  // "请输入手机号" / "Enter phone number"
```

Cambio de idioma:
```dart
Get.updateLocale(Locale('zh', 'CN'));  // Cambiar a chino
Get.updateLocale(Locale('en', 'US'));  // Cambiar a inglés
```

### Clasificación de claves de traducción

| Categoría | Ejemplos de claves PHP | Ejemplos de claves Flutter |
|------|-----------|---------------|
| General | `success`, `fail`, `not_found` | `confirm`, `cancel`, `save` |
| Autenticación | `auth.login_success`, `auth.*` | `login_btn`, `phone_hint` |
| Comunidad | `community.name_required` | - |
| Cargos | `fee.bill_not_found`, `fee.*` | `fee_management`, `bill_status` |
| Reparación | `repair.not_found`, `repair.*` | `repair_submit`, `urgency_normal` |
| Quejas | `complaint.submit_success` | `complaint_type`, `type_complaint` |
| Personal | - | `profile`, `change_password` |

**HarmonyOS:** usa los calificadores de recursos `resources/base/element/string.json` + `resources/en_US/element/string.json` (implementados al crear el proyecto HarmonyOS).

## 12. Estrategia de pruebas

### Proceso de pruebas TDD

El proyecto sigue el proceso TDD (desarrollo dirigido por pruebas): rojo→verde→refactorizar.

```
RED: escribir primero la prueba, observar el fallo
  ↓
GREEN: escribir el código mínimo para que la prueba pase
  ↓
REFACTOR: limpiar el código, mantener las pruebas en verde
```

### Cobertura de pruebas

| Capa | Framework de pruebas | Contenido de las pruebas |
|----|---------|---------|
| Servicios base | PHPUnit | Generación de ID Snowflake, codificación/decodificación Hashids, formato de respuesta |
| Base de datos | PHPUnit + PDO | Verificación de estructura de tablas (clave primaria BIGINT, no autoincremental, prefijo erik_) |
| Internacionalización | PHPUnit | Existencia de archivos de traducción, consistencia de claves chino/inglés |
| Endpoints de API | PHPUnit | Verificación de salud, formato de respuesta |
| Middleware | Pruebas de integración | Autenticación JWT, límite de velocidad, permisos |

### Ejecutar las pruebas

```bash
cd admin && php vendor/bin/phpunit    # Panel de administración: 60 tests, 164 assertions
cd service && php vendor/bin/phpunit  # Portal de propietarios: 18 tests, 45 assertions, 100% pass
```

## 13. Arquitectura del frontend

### Flutter Web (estilo escritorio PC)

```
apps/flutter/lib/
├── main.dart                    # Entrada, inicializa ApiService + AuthService
├── app.dart                     # GetMaterialApp, tabla de rutas + tema + i18n
├── config/
│   ├── api_config.dart          # Constantes de endpoints de API (apunta a service :8788)
│   └── theme.dart               # Tema Material 3 (esquema de colores Ant Design)
├── services/
│   ├── api_service.dart         # Singleton Dio + interceptor JWT + refresco automático 401
│   ├── auth_service.dart        # Login/logout/persistencia de Token
│   └── storage_service.dart     # Envoltorio de shared_preferences
├── i18n/
│   └── messages.dart            # GetX Translations (101 claves, zh_CN/en)
├── pages/
│   ├── login/                   # Página de login estilo PC (Card centrada + validación de formulario)
│   ├── home/                    # Panel (4 StatCard + lista de avisos)
│   ├── fee/                     # Lista de facturas / detalle / diálogo de pago
│   ├── repair/                  # Lista de reparaciones / envío / detalle + evaluación
│   └── profile/                 # Información personal / cambio de contraseña / salir
└── widgets/
    └── stat_card.dart           # Componente de tarjeta de estadísticas (icono + título + valor)
```

### App móvil HarmonyOS

```
apps/harmonyos/entry/src/main/ets/
├── services/
│   ├── ApiService.ets           # Envoltorio de @ohos.net.http, Bearer Token
│   └── AuthService.ets          # Login/logout (persistencia con Preference)
├── model/
│   └── Models.ets               # Definiciones de interfaces TypeScript
├── pages/
│   ├── LoginPage.ets            # Login con teléfono + contraseña
│   └── HomePage.ets             # Panel (tarjetas de estadísticas + lista de avisos)
└── resources/
    ├── base/element/string.json # Recursos en chino
    └── en_US/element/string.json# Recursos en inglés
```

### Selección tecnológica

| Capa | Flutter Web | HarmonyOS |
|----|------------|-----------|
| Gestión de estado | GetX | @State + @Prop |
| HTTP | Dio + interceptor JWT | @ohos.net.http |
| Persistencia | shared_preferences | @ohos.data.preferences |
| Gráficos | fl_chart | Componentes Web + ECharts |
| Internacionalización | GetX Translations | Calificadores de recursos |
| Rutas | GetX named routes | router.pushUrl/replaceUrl |

## 14. Arquitectura de funciones extendidas

### Centro de notificaciones de mensajes
Plantilla de mensaje → generación de notificación → envío multicanal (dentro de App/SMS/correo/push)

### Flujo de aprobación
Configuración del tipo de aprobación → envío de instancia → flujo de pasos (aprobar/rechazar) → notificar al siguiente aprobador

### Flujo de pago
Crear orden de pago → pago de terceros → callback asíncrono → actualizar estado de factura → registrar log de pago

### Votaciones de propietarios
Publicar votación → votación de propietarios (ponderada por área) → recuento en tiempo real → estadísticas de resultados

### Escalado automático SLA
Coincidencia de reglas SLA → verificación periódica de timeout → escalado automático → registro de multas

### Cobros inteligentes
Coincidencia de estrategia de cobro → detección de morosidad → generación automática de tareas de cobro → ejecución de acciones de cobro

### Gestión de inspección
Asignación de tareas → registro GPS móvil → carga de fotos → marcado de anomalías → estadísticas de finalización

### Gestión de grupos
Grupo → asociación de comunidades → resumen de datos entre comunidades (propiedades/propietarios/cobros/reparaciones)

## 15. Documentación de API

Usa `hg/apidoc` para generar automáticamente documentación de interfaces a partir de las anotaciones de controladores, agrupada por función.

**Panel de administración** (`http://localhost:8787/apidoc`): 10 grupos — 57 controladores con anotaciones inyectadas (Base/Docs/Install sin agrupar)

| Grupo | Cantidad | Controladores |
|------|------|--------|
| `common` | 2 | Auth, Captcha |
| `dashboard` | 3 | Dashboard, Metrics, Health |
| `export` | 1 | Export |
| `import` | 1 | Import |
| `upload` | 1 | Upload |
| `system` | 6 | User, Role, Permission, Config, Log, Profile |
| `property-core` | 12 | Community, Building, Unit, RoomType, Room, Owner, Tenant, FeeType, FeeBill, FeePayment, Repair, Announcement |
| `property-aux` | 9 | Parking(3), Equipment(2), Complaint, Visitor, Contract, Finance |
| `property-adv` | 11 | Activity(2), Patrol(2), Cleaning(2), Green(2), Energy(2), Staff |
| `extensions` | 11 | Notification, Approval, Payment, Vote, Sla, Collection, Inspection, Mall, Face, Group, Knowledge |

**Portal de propietarios** (`http://localhost:8788/apidoc`): 9 grupos — 17 controladores con anotaciones inyectadas

| Grupo | Cantidad | Controladores |
|------|------|--------|
| `public` | 2 | Auth, Captcha |
| `home` | 2 | Home, Room |
| `fee` | 1 | Fee |
| `repair` | 1 | Repair |
| `feedback` | 2 | Complaint, Announcement |
| `parking` | 2 | Parking, Visitor |
| `activity` | 1 | Activity |
| `profile` | 1 | Profile |
| `extensions` | 5 | Notification, Vote, Mall, Knowledge, Face |

### Normas de anotación

```php
/**
 * 小区列表
 * @Apidoc\Method("GET")
 * @Apidoc\Url("/admin/community")
 * @Apidoc\Group("property-core")
 * @Apidoc\Sort(1)
 * @Apidoc\Param("keyword", type="string", require=false, desc="搜索关键词")
 * @Apidoc\Param(ref="pagination")
 * @Apidoc\Returned("id", type="string", desc="hashid")
 */
```

### Bloques de definición comunes

| Nombre del bloque | Contenido |
|------|------|
| `pagination` | Parámetros de paginación page/page_size |
| `searchParams` | Filtros de búsqueda keyword/status |
| `dateRange` | Rango de fechas start_date/end_date |
| `passwordConfirm` | Confirmación de contraseña password |

## 16. Formato de respuesta unificado

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

| code | Significado |
|------|------|
| 0 | Éxito |
| 400 | Error de parámetros |
| 401 | No autenticado |
| 403 | Sin permisos |
| 404 | No existe |
| 422 | Fallo de validación |
| 429 | Demasiadas solicitudes |
| 500 | Error del servidor |
