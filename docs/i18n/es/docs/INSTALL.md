# Guía de Instalación

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

Este documento le guía para desplegar el sistema de gestión de propiedades desde cero.

---

## Índice

1. [Asistente de instalación Web (recomendado)](#asistente-de-instalación-web-recomendado)
2. [Instalación manual](#instalación-manual)
3. [Despliegue Docker](#despliegue-docker)
4. [Cuenta predeterminada](#cuenta-predeterminada)
5. [Verificación de la instalación](#verificación-de-la-instalación)
6. [Preguntas frecuentes](#preguntas-frecuentes)

---

## Asistente de instalación Web (recomendado)

El proyecto incluye un asistente de instalación Web; tras iniciar el panel de administración, toda la configuración se completa a través del navegador.

### Pasos de uso

```bash
# 1. Entrar al directorio del panel de administración
cd admin

# 2. Crear el archivo de variables de entorno (copiado de la plantilla)
cp .env.example .env

# 3. Instalar dependencias
composer install --no-dev --optimize-autoloader

# 4. Iniciar el servicio
php start.php start -d
```

### 5. Abrir el asistente de instalación

Acceda en el navegador a **`http://localhost:8787/install`** y complete la configuración en tres pasos según las indicaciones:

| Paso | Contenido | Descripción |
|------|------|------|
| Paso 1 | Configuración de base de datos | Completar host, puerto, nombre de base, usuario y contraseña |
| Paso 2 | Cuenta de administrador | Configurar el usuario y la contraseña de inicio de sesión del panel (mínimo 6 caracteres) |
| Paso 3 | Confirmar la instalación | Revisar la información de configuración; al confirmar, la instalación se ejecuta automáticamente |

El proceso de instalación completa automáticamente:
1. Prueba de conexión a la base de datos
2. Escritura del archivo de configuración `.env`
3. Importación de las 65 tablas de datos + semilla de permisos
4. Creación de la cuenta de administrador con rol de superadministrador
5. Creación del archivo de bloqueo de instalación `public/.installed`

### Después de la instalación

- Dirección del panel de administración: `http://localhost:8787/admin`
- El asistente de instalación mostrará la dirección de inicio de sesión y la información de la cuenta
- Se recomienda reiniciar el servicio para que la configuración surta efecto: `php start.php restart -d`
- Si necesita reinstalar, basta con eliminar el archivo `public/.installed`

---

## Instalación manual

### Requisitos del entorno

| Componente | Versión requerida | Descripción |
|------|---------|------|
| PHP | 8.1+ (recomendado 8.3) | Requiere extensiones pcntl, pdo_mysql, redis, gd, mbstring |
| MySQL | 8.0+ | Juego de caracteres utf8mb4 |
| Redis | 6.0+ | Caché, límite de velocidad, Sesión |
| Composer | 2.x | Gestión de dependencias PHP |
| Elasticsearch | 8.x | Búsqueda de texto completo (opcional; si se deshabilita, usa consultas de base de datos) |
| Flutter SDK | 3.x | Solo necesario para desarrollo frontend |

### Verificación de extensiones PHP

```bash
php -m | grep -E "pcntl|pdo_mysql|redis|gd|mbstring|curl|json|xml|dom"
```

---

## Inicialización de la base de datos

### 1. Crear la base de datos

```bash
mysql -u root -p <<SQL
CREATE DATABASE IF NOT EXISTS property_management
  DEFAULT CHARSET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
```

### 2. Importar el script de instalación combinado

```bash
mysql -u root -p property_management < docs/install.sql
```

`docs/install.sql` incluye las 65 tablas + datos semilla de permisos RBAC, y usa `CREATE TABLE IF NOT EXISTS` para garantizar que se puede ejecutar repetidamente.

Verificación después de ejecutar:

```bash
mysql -u root -p property_management -e "SHOW TABLES;" | wc -l
# Debe mostrar: 66 (65 tablas + 1 línea de encabezado)
```

---

## Despliegue del panel de administración

El panel de administración se ejecuta en `http://localhost:8787` y proporciona las API del panel de administración.

```bash
cd admin

# 1. Configurar variables de entorno
cp .env.example .env
# Editar .env, modificar la contraseña de la base de datos, la clave JWT, etc.

# 2. Instalar dependencias
composer install --no-dev --optimize-autoloader

# 3. Iniciar el servicio
php start.php start -d
# -d significa ejecución en segundo plano; sin -d se ejecuta en primer plano para ver los logs

# 4. Verificar
curl http://localhost:8787/health
```

### Elementos de configuración clave (admin/.env)

| Elemento de configuración | Descripción | Requisito de producción |
|--------|------|-------------|
| `JWT_SECRET_KEY` | Clave de firma JWT | Cadena aleatoria de 64+ caracteres |
| `HASHIDS_SALT` | Sal de cifrado de ID | Cadena aleatoria, debe coincidir con service |
| `SNOWFLAKE_DATACENTER_ID` | ID del centro de datos (0-31) | Debe diferenciarse en despliegues multicentro |
| `SNOWFLAKE_WORKER_ID` | ID del nodo de trabajo (0-31) | Diferente en cada máquina del mismo centro |
| `ENCRYPTION_KEY` | Clave de cifrado de transmisión API | Cadena aleatoria de 32 bytes |
| `ENCRYPTABLE_KEY` | Clave de cifrado de campos de base de datos | Cadena aleatoria de 32 bytes |
| `DB_PASSWORD` | Contraseña de la base de datos | Contraseña fuerte |

---

## Despliegue del portal de propietarios

El portal de propietarios se ejecuta en `http://localhost:8788` y proporciona las API del portal de propietarios.

```bash
cd service

# 1. Configurar variables de entorno
cp .env.example .env
# Editar .env, modificar la contraseña de la base de datos, la clave JWT, etc.

# 2. Instalar dependencias
composer install --no-dev --optimize-autoloader

# 3. Iniciar el servicio
php start.php start -d

# 4. Verificar
curl http://localhost:8788/health
```

> **Nota:** admin y service comparten la misma base de datos. `HASHIDS_SALT` debe coincidir con admin; de lo contrario, los ID cifrados generados por admin no se pueden descifrar en service.

---

## Despliegue Docker

### Panel de administración

```bash
cd admin
cp .env.docker .env
# Editar .env para modificar las claves de producción

docker compose up -d
# Incluye: Nginx + PHP + MySQL + Redis + Elasticsearch
```

### Portal de propietarios

```bash
cd service
cp .env.docker .env
# Editar .env para modificar las claves de producción

docker compose up -d
```

### Planificación de puertos de servicios

| Servicio | admin | service | Descripción |
|------|-------|---------|------|
| Aplicación | 8787 | 8788 | HTTP de webman |
| MySQL | 3306 | 3307 | Mapeo de puertos de contenedor |
| Redis | 6379 | 6380 | Mapeo de puertos de contenedor |
| Elasticsearch | 9200 | 9201 | Mapeo de puertos de contenedor |
| Nginx | 80/443 | 80/443 | Requiere despliegue escalonado |

> Al desplegar dos docker-compose en el mismo host, los puertos de service tienen desplazamiento preestablecido para evitar conflictos.

---

## Cuenta predeterminada

| Usuario | Contraseña | Rol | Descripción |
|--------|------|------|------|
| admin | admin123 | Superadministrador | Tiene todos los permisos |

> **Cambie inmediatamente la contraseña predeterminada en el entorno de producción.**

---

## Verificación de la instalación

### 1. Verificación de salud

```bash
# Panel de administración
curl http://localhost:8787/health

# Portal de propietarios
curl http://localhost:8788/health
```

### 2. Documentación de API

Todos los endpoints de API y descripciones de parámetros se encuentran en el documento independiente [API.md](API.md). Tras iniciar el servicio también se puede acceder a la documentación interactiva generada automáticamente:

| Extremo | Dirección |
|----|------|
| Panel de administración | http://localhost:8787/apidoc |
| Portal de propietarios | http://localhost:8788/apidoc |

### 3. Prueba de inicio de sesión

```bash
curl -X POST http://localhost:8787/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### 4. Ejecutar las pruebas

```bash
# Panel de administración
cd admin && php vendor/bin/phpunit

# Portal de propietarios
cd service && php vendor/bin/phpunit
```

---

## Preguntas frecuentes

### P: Error al iniciar `Call to undefined function pcntl_fork()`

A PHP le falta la extensión pcntl.

```bash
# Ubuntu/Debian
apt install php-pcntl

# Docker
docker-php-ext-install pcntl
```

### P: Después de iniciar sesión indica Token no válido

Verifique que las siguientes configuraciones de `.env` de admin y service coincidan:
- `JWT_SECRET_KEY`
- `JWT_ALGORITHM`

### P: Los ID cifrados no coinciden entre ambos extremos

Asegúrese de que el valor de `HASHIDS_SALT` de admin y service sea exactamente igual.

### P: Los contenedores Docker no se comunican en la red

Use el nombre del contenedor en lugar de la IP para conectarse (por ejemplo, `DB_HOST=mysql`).

### P: Cómo restablecer la base de datos

```bash
mysql -u root -p -e "DROP DATABASE IF EXISTS property_management;"
mysql -u root -p -e "CREATE DATABASE property_management DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p property_management < docs/install.sql
```

### P: Cómo configurar HTTPS

En producción se recomienda usar un proxy inverso de Nginx para terminar TLS. Consulte la configuración de referencia en `admin/docs/nginx-security.conf`.

---

## Siguientes pasos

- [Documento de diseño de arquitectura](ARCHITECTURE_DESIGN.md) — Arquitectura por capas del sistema y cadena de ejecución de middleware
- [Documentación de API](API.md) — Referencia completa de interfaces
- [Documento de diseño de funciones](FEATURE_DESIGN.md) — Especificaciones funcionales de 34 módulos
- [Comparación de versiones](EDITIONS.md) — Diferencias entre versiones Lite / Standard / Full
