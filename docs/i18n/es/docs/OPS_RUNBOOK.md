# Manual de Operaciones (OPS Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Aplica a: property-management-platform (extremo admin + extremo service, PHP 8.3 webman)

## 1. Respaldo y restauración de base de datos

El extremo admin y el extremo service comparten la misma instancia de MySQL y la misma base `property_management`; un solo respaldo es suficiente. Entrada unificada:

| Base | Script de respaldo | Descripción |
|---|---|---|
| `property_management` | `scripts/backup.sh` | Lee la conexión de `admin/.env` (se puede sobrescribir con `--container=`), mysqldump dentro del contenedor por defecto |

Genera `backups/backup_YYYYMMDD_HHMMSS.sql.gz`, retiene los últimos 7 días por defecto (`--keep-days=` ajustable).

### 1.1 Respaldo completo

```bash
cd /path/to/property-management-platform
bash scripts/backup.sh
```

### 1.2 Tarea programada (crontab)

```cron
# Respaldo completo diario a las 02:00
0 2 * * * cd /path/to/property-management-platform && bash scripts/backup.sh >> /var/log/pmp-backup.log 2>&1
```

Recomendación de producción: montar el directorio de respaldos en un disco independiente/almacenamiento remoto y verificar periódicamente la integridad de los archivos de respaldo (validación `gzip -t`).

### 1.3 Proceso de simulacro de restauración (al menos una vez por trimestre)

1. Seleccionar el respaldo más reciente: `ls -t backups/backup_*.sql.gz`
2. Ejecutar la restauración en un **entorno independiente** (o base temporal): ver [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md) escenario A (restauración a base vacía) y escenario B (restauración a punto en el tiempo).
3. Verificar:
   - Comparación de conteos: `SELECT COUNT(*) FROM erik_user;` consistente con lo registrado antes del respaldo
   - Los campos cifrados se descifran correctamente: consultar un registro con campos encryptable; valores correctos, sin errores de decrypt en logs
   - Smoke de negocio: inicio de sesión y consulta de listas de interfaces normales
4. Registrar el tiempo y resultado del simulacro (para la evaluación de RTO).

> El manual completo de simulacro (restauración a base vacía / restauración a punto en el tiempo / verificación de consistencia / cronograma de simulacro de 30 minutos) se encuentra en [RECOVERY_RUNBOOK.md](RECOVERY_RUNBOOK.md).

### 1.4 Explicación de RPO / RTO

- **RPO (cantidad de datos que se pueden perder)**: determinada por la frecuencia de respaldo. Respaldo completo diario → RPO ≤ 24 horas, es decir, se pueden perder como máximo los datos del último día. Para un RPO menor, aumentar la frecuencia de respaldo (por ejemplo, 2 veces al día) o habilitar respaldo incremental con binlog.
- **RTO (tiempo requerido para restaurar)**: depende del tamaño de la base y la velocidad de restauración; objetivo ≤ 1 hora (restauración + verificación + reinicio del servicio). Actualizar el valor medido después de cada simulacro.
- Emergencia por fallo de restauración: primero revertir el código de la aplicación, luego reintentar con el respaldo disponible más reciente; si el respaldo está dañado, usar uno más antiguo y aceptar un RPO mayor.

## 2. Gestión de claves

El proyecto depende de 5 claves, todas en `.env` (admin y service son independientes entre sí, no comparta el mismo conjunto):

| Variable | Longitud | Uso |
|---|---|---|
| `ENCRYPTION_KEY` | 32 bytes | Cifrado de transmisión API (config/encryption.php) |
| `ENCRYPTABLE_KEY` | 32 bytes | Cifrado de campos sensibles de base de datos (plugin encryptable, **no compartir con ENCRYPTION_KEY**) |
| `JWT_SECRET_KEY` | 64+ bits | Firma JWT |
| `HASHIDS_SALT` | — | Cifrado/descifrado de ID |
| `HASHIDS_ALT_SALT` | — | Respaldo de cifrado/descifrado de ID |

### 2.1 Generar claves

```bash
# Imprime 5 KEY=VALUE en stdout, se puede añadir directamente a .env
php scripts/gen_env_keys.php

# Escribir directamente en .env: no sobrescribe las claves existentes, solo añade las que faltan
php scripts/gen_env_keys.php --file=.env
```

> Si alguna clave en .env sigue siendo el marcador de posición `change-me`, elimine esa línea primero antes de ejecutar (el marcador se considera «ya existente» y no se sobrescribe).

### 2.2 Rotación de claves (encryptable)

```bash
bash scripts/rotate_keys.sh            # Opera por defecto en .env del directorio actual
bash scripts/rotate_keys.sh /path/to/service/.env
```

El script completa automáticamente: respaldar .env → generar nueva `ENCRYPTABLE_KEY` → añadir la clave antigua a `ENCRYPTION_PREVIOUS_KEYS` (separada por comas, la rotada más reciente primero) → escribir la nueva clave. Luego, manualmente según las indicaciones: reiniciar el servicio → verificar el descifrado → confirmar y eliminar el respaldo.

**Explicación de `ENCRYPTION_PREVIOUS_KEYS`**: encryptable primero usa la `ENCRYPTABLE_KEY` actual al descifrar; si falla, prueba las claves históricas una por una en orden de lista. Por lo tanto, **al rotar, la clave antigua debe añadirse a la lista antes de que la nueva clave surta efecto**; de lo contrario, tras el reinicio los datos antiguos no se pueden descifrar (los datos no se pierden; basta con revertir .env para recuperarlos). La lista solo crece; antes de eliminar claves históricas debe confirmarse que todos los datos antiguos fueron re-cifrados.

**Sin migración automática de datos**: tras la rotación, los datos antiguos siguen cifrados con la clave antigua y se pueden leer/escribir normalmente. Si se necesita reescribir los datos existentes con la nueva clave, ejecutar por separado una tarea de migración de datos (leer tabla por tabla → escribir para disparar el re-cifrado).

### 2.3 Validación de inicio fail-fast

Las siguientes configuraciones se validan al iniciar el servicio; si una clave **falta o sigue siendo el marcador de posición `change-me`**, se lanza una `RuntimeException` que rechaza el inicio (para evitar salir a producción con claves de marcador):

| Configuración | Clave validada |
|---|---|
| `service/config/encryption.php` | `ENCRYPTION_KEY` |
| `service/config/encryptable.php`、`service/config/plugin/erikwang2013/encryptable/app.php` | `ENCRYPTABLE_KEY` |
| `service/config/jwt.php`、`service/config/plugin/erikwang2013/jwt/jwt.php` | `JWT_SECRET_KEY` |

Ejemplo de error de inicio: `ENCRYPTABLE_KEY no configurada o sigue siendo un marcador de posición; configure una clave aleatoria de 32 bytes en .env`.

**Lista de verificación de operaciones diarias**:

1. Desplegar entorno nuevo: `cp .env.example .env` → eliminar las líneas de marcador `change-me` → `php scripts/gen_env_keys.php --file=.env` → iniciar el servicio y confirmar que no hay errores de claves.
2. Rotación rutinaria: ejecutar según 2.2, una vez por trimestre es suficiente (sin período obligatorio; rotar inmediatamente ante una fuga).
3. Los `.env.bak.*` de respaldo contienen claves en texto plano; tratarlos igual que los respaldos de base de datos (permisos 600, almacenamiento remoto).

## 3. Monitoreo de alertas (Prometheus + Grafana)

Orquestado en `admin/docker-compose.yml` (servicios nuevos prometheus / grafana / redis-exporter), toda la configuración en `admin/deploy/monitoring/`:

```bash
cd admin
docker compose up -d prometheus grafana redis-exporter
# Prometheus: http://host:9090   Grafana: http://host:3000
# Primer inicio de sesión de Grafana: admin / ${GRAFANA_ADMIN_PASSWORD} (por defecto change-me-grafana-password)
```

- **Fuente de datos**: Grafana configura automáticamente la fuente de datos Prometheus al iniciar (provisioning), los paneles se crean en la UI.
- **Reglas de alerta**: `deploy/monitoring/alerts.yml`, cubre:
  - `AppDown` (aplicación inalcanzable, equivalente a 5xx en todo el sitio) — critical
  - `MysqlDown` / `RedisDown` (fallo de sondeo en el lado de la aplicación) — critical
  - `ElasticsearchDown` (fallo de captura nativa de ES `/_prometheus/metrics`) + `ElasticsearchHealthYellow` (clúster no verde) — critical/warning
  - `QueueBacklog` (cola de búsqueda scout `queues:scout_*` acumulada >100 elementos durante 10 minutos) — warning
- **Inyección de contraseña de ES**: prometheus lee `ELASTIC_PASSWORD` mediante `secrets` de compose (requiere Docker Compose ≥ 2.24); el archivo de configuración no fija la contraseña; si no se establece, usa marcador change-me y la captura de ES con 401 disparará ElasticsearchDown.
- **Recarga de reglas**: tras modificar alerts.yml, `curl -X POST localhost:9090/-/reload` (prometheus necesita `--web.enable-lifecycle`; si no está por defecto, reiniciar el contenedor).
- **Verificación local**: `bash scripts/verify_monitoring.sh` — valida la sintaxis YAML de las reglas de alerta de ambos lados admin/service, hace curl de `/metrics` en ambos extremos (admin:8787 / service:8788) para verificar la salida de métricas, y la carga de reglas de Prometheus (9090/9091); si la aplicación/Prometheus no está en ejecución, el elemento correspondiente muestra SKIP y sale con exit 0.

**Estado**: admin y service ya tienen el endpoint `/metrics` (MetricsController, sin autenticación). El middleware MetricsCollector cuenta realmente según `code="all"|"5xx"` (admin genera `open_admin_http_requests_total`, service genera `property_service_http_requests_total`); la regla `Http5xxRatio` en ambos alerts.yml (proporción de 5xx >5% durante 10 minutos) puede surtir efecto directamente. **Prueba real de alertas pendiente de despliegue**: las reglas están listas pero aún no se ha verificado el disparo en un entorno de despliegue real (depende de `verify_monitoring.sh` y de que Prometheus esté en línea).

## 4. Rotación de logs

- **Logs de contenedor**: todos los servicios de compose ya tienen `json-file` + `max-size 10m / max-file 3`, sin tratamiento adicional.
- **Logs de aplicación del host** (`runtime/*.log`、`service/workerman.log`): usar `admin/deploy/logrotate/pmp-app`:

```bash
sudo cp admin/deploy/logrotate/pmp-app /etc/logrotate.d/pmp-app
# Modificar las rutas dentro del archivo según la ruta de despliegue real; copytruncate permite rotar sin reiniciar webman
sudo logrotate -d /etc/logrotate.d/pmp-app   # Verificación de prueba
```

Por defecto rotación diaria, retención de 30 días, compresión gzip.

## 5. Smoke de pruebas de carga posterior al despliegue

Después del despliegue, usar k6 para un smoke que verifique la cadena de inicio de sesión y la accesibilidad de las interfaces de negocio clave (baja velocidad, no es una prueba de rendimiento). Script: `scripts/loadtest/smoke.js` (por defecto 2 VU, 30s, login + dashboard, ambos admiten sobrescritura con variables de entorno `BASE_URL`/`VUS`/`DURATION`/`TOKEN`).

### 5.1 Smoke local

```bash
cd /path/to/property-management-platform/scripts/loadtest

# Solo sondea la cadena de login (sin token; 422 error de código de verificación/429 límite de velocidad son la defensa activa, se consideran alcanzables)
k6 run -e BASE_URL=http://127.0.0.1:8790 smoke.js

# Con interfaces de negocio autenticadas: emitir JWT de prueba en el servidor de despliegue (depende de admin/.env y vendor) y pasarlo
TOKEN=$(php mint-token.php)
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" smoke.js

# Concurrencia/duración personalizada
k6 run -e BASE_URL=https://admin.example.com -e TOKEN="$TOKEN" -e VUS=5 -e DURATION=60s smoke.js
```

La prueba de carga completa (tres scripts login + dashboard + fee) sigue usando `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]`.

### 5.2 Smoke de CI (disparo manual de GitHub Actions)

Página de Actions del repositorio → **Loadtest Smoke** → **Run workflow**:

| Entrada | Obligatoria | Descripción |
|---|---|---|
| `target_url` | Sí | Dirección del entorno probado, por ejemplo `https://admin.example.com` |
| `duration` | No | Duración del smoke, por defecto `30s` |
| `token` | No | JWT de prueba de carga; si se deja vacío, solo sondea la cadena de login |

Obtención del token (ejecutar en la raíz del repositorio en el servidor de despliegue, requiere `admin/.env` y `admin/vendor/`):

```bash
php scripts/loadtest/mint-token.php
```

> Nota: el token es un JWT dedicado a pruebas de carga (cuenta de administrador erik por defecto), aparecerá en texto plano en los logs del workflow; emítalo con una cuenta dedicada a pruebas; si en producción no se desea exponerlo, use el smoke local de 5.1.
