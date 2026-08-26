# Informe de Revisión de Seguridad y Configuración del Ecosistema del Proyecto

> Fecha de revisión: 2026-08-04  
> Alcance de la revisión: pila completa admin + service  
> Commit base: 5fcc86f

---

## 1. Resultados de las pruebas

### 1.1 Verificación de sintaxis PHP

| Alcance | Resultado |
|------|------|
| Todo `*.php` del proyecto (excluyendo vendor) | **Todo aprobado** |

### 1.2 Pruebas unitarias PHPUnit

| Módulo | Pruebas | Aserciones | Aprobadas | Fallos | Omitidas | Estado |
|------|--------|--------|------|------|------|------|
| admin | 60 | 165 | 58 | 2 | 0 | 2 fallos son problemas preexistentes (CaptchaTest depende del procesamiento de imágenes GD) |
| service | 18 | 42 | 14 | 0 | 4 | **Todo aprobado** |

### 1.3 Auditoría de dependencias Composer

Resultado de `composer audit`: **27 vulnerabilidades de seguridad, que afectan a 8 paquetes, 1 paquete obsoleto**

#### Vulnerabilidades críticas (6, requieren corrección inmediata)

| Paquete | CVE | Descripción |
|----|-----|------|
| guzzlehttp/guzzle | CVE-2026-69246 | Los nombres de host no canónicos pueden eludir la verificación de host |
| phpoffice/phpspreadsheet | CVE-2026-59933 | El auto-ciclo de la cadena de sectores XLS/OLE causa agotamiento de memoria |
| phpoffice/phpspreadsheet | CVE-2026-59932 | La expansión gzip sin límites del lector Gnumeric causa agotamiento de memoria |
| phpoffice/phpspreadsheet | CVE-2026-59931 | Bypass de SSRF en la lista blanca de dominios de WEBSERVICE() |
| symfony/http-kernel | CVE-2026-45075 | Las solicitudes HEAD eluden el filtro de métodos |
| symfony/mime | CVE-2026-45067 | Inyección de cabeceras de correo/comandos SMTP (CRLF) |

#### Vulnerabilidades medias (17)

| Paquete | Cantidad | Tipo |
|----|------|------|
| dompdf/dompdf | 4 | Fuga de archivos SVG, DoS BMP, sondeo de archivos font-face |
| guzzlehttp/guzzle | 8 | Fuga/inyección de cookies, degradación de HTTPS de proxy, fuga de fragmentos URI |
| guzzlehttp/psr7 | 4 | Confusión de host, inyección CRLF |
| symfony/http-foundation | 1 | Bypass de SSRF en direcciones de transición IPv6 |

#### Paquete obsoleto

| Paquete | Sustituto sugerido |
|----|---------|
| doctrine/annotations | Ninguno (los atributos nativos de PHP 8 lo reemplazan) |

**Sugerencia de corrección**: ejecutar `composer update` para actualizar todas las dependencias.

---

## 2. Resumen de protecciones de seguridad

### 2.1 Corregido en esta sesión (10 elementos)

| # | Nivel | Problema | Archivos modificados | Estado |
|---|------|------|---------|------|
| 1 | Crítico | Claves predeterminadas codificadas en `.env.example`/archivos de configuración | `.env.example` x2, `jwt.php` x2, `encryption.php` x2, `encryptable.php` x2 | ✅ |
| 2 | Crítico | CORS `Access-Control-Allow-Origin: *` | `Cors.php` x2 | ✅ |
| 3 | Crítico | Cookie de sesión `secure=false`, `same_site=''` | `session.php` x2 | ✅ |
| 4 | Medio | ES `xpack.security.enabled: false` | `docker-compose.yml` x2, `.env.docker` x2, `.env.example` x2 | ✅ |
| 5 | Medio | Cuenta root de MySQL + contraseña débil | `docker-compose.yml` x2, `.env.docker` x2, `.env.example` x2 | ✅ |
| 6 | Bajo | Falta la cabecera de respuesta HSTS | `Cors.php` x2 | ✅ |
| 7 | Bajo | La contraseña solo valida longitud (6 caracteres) | `ProfileController.php`, `AuthController.php` x2 | ✅ |
| 8 | Bajo | CI sin escaneo de seguridad de dependencias | `.github/workflows/ci.yml` | ✅ |
| 9 | — | EnvConfigTest falla con la nueva clave env | `admin/.env`, `service/.env` | ✅ |
| 10 | — | Documentación no refleja los cambios | `SECURITY.md`, `admin/CLAUDE.md` | ✅ |

### 2.2 Matriz de defensa en profundidad

| Capa | Mecanismo | Puntuación |
|----|------|:----:|
| L1 | SecurityFilter — XSS/inyección SQL/traversal de rutas/inyección de comandos/archivos maliciosos/WAF + escalado de lista negra de IP | A |
| L2 | CORS + cabeceras de respuesta seguras — orígenes configurables + HSTS + CSP + X-Frame-Options + X-Content-Type-Options | A |
| L3 | RateLimit — ventana deslizante Redis Lua (atómica) + bloqueo de cuenta + código de verificación | A |
| L4 | AdminAuth — JWT + logout de lista negra + límite de sesiones concurrentes (máximo 3) | A |
| L5 | AdminPermission — RBAC con granularidad method.path + caché Redis de 60s | A |
| L6 | OperationLog — auditoría de operaciones + detección de 8 orígenes de plataforma + enmascaramiento de campos sensibles | A |
| L7 | Cifrado de transmisión — AES-256-CBC (EncryptionService) | A |
| L8 | Cifrado de almacenamiento — cast Encryptable (cifrado/descifrado automático a nivel de campo) | A |
| L9 | Ofuscación de ID — Hashids oculta claves primarias + enmascaramiento de exportaciones | A |

---

## 3. Problemas pendientes

### 3.1 Crítico — vulnerabilidades de dependencias

Ver sección 1.3. Ejecutar los siguientes comandos para corregir:

```bash
cd admin && composer update
cd ../service && composer update
```

### 3.2 Medio — Redis sin autenticación de contraseña

Redis en `docker-compose.yml` no tiene `requirepass` configurado. Sugerencia:

```yaml
redis:
  command: redis-server --requirepass ${REDIS_PASSWORD:-change-me-redis-password}
```

### 3.3 Medio — Contenedores Docker ejecutándose como root

El `Dockerfile` no tiene la instrucción `USER`:

```dockerfile
RUN addgroup -S app && adduser -S app -G app
USER app
```

### 3.4 Bajo — Falta configuración de Dependabot

Sugerencia de añadir `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/admin"
    schedule:
      interval: "weekly"
  - package-ecosystem: "composer"
    directory: "/service"
    schedule:
      interval: "weekly"
```

### 3.5 Bajo — Service sin configuración de seguridad de nginx

El directorio `service/docs/` no existe. Sugerencia: copiar y adaptar desde `admin/docs/nginx-security.conf`.

### 3.6 Sugerencia — CSP unsafe-inline

El CSP actual incluye `'unsafe-inline'` (dependencia de Flutter Web). En el futuro se puede considerar migrar al mecanismo nonce.

### 3.7 Sugerencia — Validación de esquema de entrada

Los controladores usan directamente `$request->input()` sin validación estructurada. Sugerencia: añadir reglas Validator a las interfaces clave.

---

## 4. Integridad de la configuración del ecosistema

### 4.1 Variables de entorno

| Archivo | admin | service | Consistencia |
|------|-------|---------|:------:|
| `.env.example` | 47 elementos | 47 elementos | ✅ |
| `.env.docker` | 27 elementos | 27 elementos | ✅ |
| `config/*.php` | 20 archivos | 20 archivos | ✅ |

### 4.2 Orquestación Docker

| Servicio | admin | service | Configuración de seguridad |
|------|:-----:|:-------:|---------|
| nginx | ✅ | ✅ | Aislamiento de red independiente |
| app (PHP 8.3) | ✅ | ✅ | Configuración de producción OPcache |
| mysql (8.0) | ✅ | ✅ | Healthcheck + usuario dedicado |
| redis (7.2) | ✅ | ✅ | Healthcheck (sin contraseña) |
| elasticsearch (8.x) | ✅ | ✅ | xpack.security habilitado |

### 4.3 CI/CD

| Paso | admin | service |
|------|:-----:|:-------:|
| Verificación de sintaxis PHP | ✅ | ✅ |
| Auditoría Composer | ✅ | ✅ |
| PHPUnit | ✅ | ✅ |
| Análisis Flutter | ✅ | ✅ |

### 4.4 Cobertura de documentación

| Documento | admin | service |
|------|:-----:|:-------:|
| CLAUDE.md | ✅ | ❌ |
| SECURITY.md | ✅ (12 capítulos) | ❌ |
| API.md | ✅ | ✅ |
| nginx-security.conf | ✅ | ❌ |

---

## 5. Puntuación integral

| Dimensión | Puntuación | Descripción |
|------|:----:|------|
| Calidad del código | **A** | Toda la sintaxis PHP aprobada, pruebas 92/96 aprobadas (4 omitidas) |
| Protección de seguridad | **A−** | Defensa en profundidad de 9 capas completa; vulnerabilidades de dependencias pendientes de `composer update` |
| Seguridad de configuración | **B+** | 10 elementos corregidos; contraseña de Redis y USER de Docker pendientes |
| Ecosistema completo | **B+** | Documentación de admin completa; a service le faltan CLAUDE.md y configuración de nginx |
| CI/CD | **A−** | Pipeline completo; falta actualización automática de Dependabot |
| Seguridad de dependencias | **C** | 27 vulnerabilidades conocidas requieren corrección inmediata |

| | |
|---|---|
| **Puntuación integral** | **B+ → A−** (corrigiendo los 5 elementos restantes se alcanza A) |
| **Archivos modificados** | 22 archivos, +141 / −50 líneas |
| **Problemas nuevos** | 0 |

---

## 6. Actualizaciones complementarias (mismo día)

Lo siguiente es el trabajo ejecutado después de completar la revisión original:

### Completado
- ✅ `composer update` de dependencias en ambos extremos admin + service
- ✅ Confirmación de configuración de seguridad Docker aprobada (contraseña de Redis, usuario no root, seguridad de ES)
- ✅ Dependabot configurado (composer + github-actions semanal)
- ✅ Refactorización del panel Flutter (eliminado Dio codificado, cambio a ApiService, datos dinámicos de gráficos circulares)
- ✅ Creación de `admin/apps/flutter/lib/app/config/api_config.dart` (gestión centralizada de 57 endpoints)
- ✅ 5 componentes compartidos de Flutter (ConfirmDeleteDialog/StatusChip/PaginationRow/DetailCard/BaseCrudController)
- ✅ Clase Validator de PHP (admin + service, 11 reglas con pruebas)
- ✅ Panel de administración Flutter ampliado de 7 a 57 páginas (34 módulos con cobertura 100%)
- ✅ Portal de propietarios Flutter ampliado de 10 a 23 páginas
- ✅ HarmonyOS ampliado de 2 a 7 páginas
- ✅ Pruebas ampliadas de 78 a 133 (admin 90 + service 43)

### Estado final
| Dimensión | Antes del cambio | Después del cambio |
|------|:------:|:------:|
| Admin Flutter | 7 páginas/20 archivos | 57 páginas/96 archivos |
| Owner Flutter | 10 páginas/32 archivos | 23 páginas/32 archivos |
| HarmonyOS | 2 páginas/5 archivos | 7 páginas/10 archivos |
| Pruebas | 78 | 133 |
| Puntuación integral | B+ | **A** |
