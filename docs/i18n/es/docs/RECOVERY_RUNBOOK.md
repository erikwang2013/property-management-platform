# Manual de Simulacro de Restauración de Base de Datos (Recovery Runbook)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Aplica a: property-management-platform (extremo admin + extremo service, MySQL 8.0)
> Leer junto con la sección 1 de [OPS_RUNBOOK.md](OPS_RUNBOOK.md): generación de respaldos, crontab, RPO/RTO en OPS_RUNBOOK; este documento solo explica «cómo restaurar, cómo verificar».

## 0. Objetivo

- **Objetivo del simulacro: completar un simulacro completo de restauración en 30 minutos** (restauración + verificación), al menos una vez por trimestre.
- En cualquier momento, con el respaldo más reciente, se puede restaurar a una base vacía o a un punto en el tiempo según este documento.

Requisitos previos:

- Archivo de respaldo disponible: `scripts/backup.sh` ya ejecutado por cron (ver OPS_RUNBOOK 1.2).
- El entorno objetivo de restauración (máquina de simulacro o producción) es isomórfico a producción: el mismo docker-compose, la misma versión de MySQL 8.0.
- Confirmar antes de restaurar: `gzip -t archivo_de_respaldo` pasa; espacio libre en disco ≥ 2 veces el tamaño del respaldo.

## 1. Escenario A: restaurar a una base vacía (el más común, escenario predeterminado del simulacro)

Objetivo: importar el respaldo a una base vacía nueva y verificar que los datos son utilizables.

```bash
cd /path/to/property-management-platform

# 1) Seleccionar el respaldo más reciente
ls -lt backups/backup_*.sql.gz | head

# 2) Verificación de integridad (si no pasa, usar un respaldo más antiguo)
gzip -t backups/backup_20260816_020000.sql.gz && echo OK

# 3) Confirmar que el contenedor objetivo está en ejecución
docker compose -f admin/docker-compose.yml ps mysql

# 4) Crear base vacía (añadir sufijo _drill al nombre de la base de simulacro para evitar sobrescribir datos de producción por error)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "CREATE DATABASE IF NOT EXISTS property_management_drill DEFAULT CHARACTER SET utf8mb4;"'

# 5) Importar (-T desactiva TTY, garantiza no interactividad; en la práctica toma unos 1-5 minutos)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot --default-character-set=utf8mb4 property_management_drill' \
  < backups/backup_20260816_020000.sql.gz
```

> Nota de credenciales: `MYSQL_PWD` toma `DB_PASSWORD` de `admin/.env`; en producción está prohibido que aparezca en texto plano en el historial del shell; se recomienda usar `--env-file admin/.env` o inyectar variables de entorno. Los ejemplos de este manual son valores convenidos para el entorno de simulacro.

## 2. Escenario B: restaurar a un punto en el tiempo (reproducción de binlog)

Premisa: MySQL 8 tiene binlog habilitado por defecto (`log_bin=ON`); los incrementos posteriores al momento del respaldo están todos en el binlog. La pérdida de datos ≤ último respaldo + período de retención de binlog (por defecto `binlog_expire_logs_seconds=2592000`, 30 días).

Idea: restauración completa → encontrar el punto de inicio del binlog → reproducir con `mysqlbinlog` hasta el punto en el tiempo objetivo.

```bash
# 1) Confirmar que binlog está habilitado y listar los archivos de log
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot -e "SHOW VARIABLES LIKE \"log_bin\"; SHOW BINARY LOGS;"'

# 2) Restauración completa (igual que escenario A pasos 4-5, restaurar a base vacía)

# 3) Encontrar el punto de inicio del binlog correspondiente al respaldo: la posición registrada en el archivo de respaldo (con --master-data=2)
#    Este script no lleva --master-data; el punto de inicio usa el «momento de inicio del respaldo», con error dentro de la duración del respaldo.
#    Reproducir el binlog hasta el punto en el tiempo objetivo (ejemplo: restaurar a 2026-08-16 10:30:00)
docker compose -f admin/docker-compose.yml exec -T \
  -e MYSQL_PWD=root mysql \
  sh -c 'mysqlbinlog --stop-datetime="2026-08-16 10:30:00" /var/lib/mysql/binlog.000012 | mysql -uroot property_management_drill'
```

Puntos clave:

- El binlog está en la ruta del contenedor `/var/lib/mysql/binlog.0000NN`; identifíquelo en la salida de `SHOW BINARY LOGS`.
- Solo reproducir el binlog «posterior al momento de inicio del respaldo»; verificar inmediatamente después de la reproducción (ver sección 3) y confirmar que `max(updated_at)` cumple lo esperado.
- Restauración de operaciones erróneas con precisión de segundos: primero localizar la declaración errónea `mysqlbinlog /var/lib/mysql/binlog.0000NN | grep -n "palabra clave de la operación errónea"` y luego decidir `--stop-datetime` o `--stop-position`.

## 3. Verificación de consistencia de datos (obligatoria después de restaurar)

| Elemento de verificación | Comando | Criterio de aprobación |
|---|---|---|
| Integridad del archivo de respaldo | `gzip -t <respaldo>` | Sin errores |
| Conteo de filas de tablas clave | `SELECT COUNT(*) FROM erik_admin_user;` | Consistente con el conteo registrado antes del respaldo |
| Muestreo de tablas de negocio | `SELECT COUNT(*) FROM erik_owner;`、`erik_tenant`、`erik_fee_bill`、`erik_repair_order` | Tres o más con magnitudes razonables (no 0 y consistentes con antes del respaldo) |
| Campos cifrados descifrables | Consultar un registro con campos encryptable (por ejemplo, documento de identidad/teléfono de `erik_owner`) | Valores correctos, sin errores de decrypt en logs de aplicación |
| Smoke de negocio | Inicio de sesión y consulta de lista de interfaz, 1 vez cada uno | 200 / respuesta normal |

Ejemplo de script de muestreo (entorno de simulacro):

```bash
docker compose -f admin/docker-compose.yml exec -T -e MYSQL_PWD=root mysql \
  sh -c 'mysql -uroot property_management_drill -e "
    SELECT (SELECT COUNT(*) FROM erik_admin_user) AS users,
           (SELECT COUNT(*) FROM erik_owner) AS owners,
           (SELECT COUNT(*) FROM erik_tenant) AS tenants,
           (SELECT COUNT(*) FROM erik_fee_bill) AS fee_bills,
           (SELECT COUNT(*) FROM erik_repair_order) AS repair_orders;"'
```

> Consistencia de conteos: registrar la línea base con el mismo SQL antes del respaldo y comparar después de restaurar; durante el simulacro, escribir la línea base en el registro del simulacro.

## 4. Cronograma del simulacro de 30 minutos

| Tiempo | Acción | Responsable |
|---|---|---|
| 0-5 min | Seleccionar respaldo, `gzip -t`, crear base vacía, registrar conteos de línea base | Operaciones |
| 5-15 min | Restauración e importación del escenario A | Operaciones |
| 15-25 min | Verificación de consistencia de la sección 3 + smoke de negocio | Operaciones + negocio |
| 25-30 min | Registrar resultados, limpiar base de simulacro (`DROP DATABASE property_management_drill`), actualizar el RTO medido de OPS_RUNBOOK 1.4 | Operaciones |

## 5. Manejo de fallos

| Síntoma | Manejo |
|---|---|
| `gzip -t` falla | Respaldo dañado, usar un respaldo más antiguo, aceptar mayor RPO y verificar que el cron de respaldo funciona |
| Error de importación (juego de caracteres/permisos) | Confirmar que `--default-character-set=utf8mb4` coincide con el juego de caracteres de la base vacía; confirmar que el usuario tiene permisos de creación de tablas |
| Conteos no coinciden con la línea base | Detener el simulacro inmediatamente, verificar si se importó a la base/archivo incorrecto; en el escenario de restauración de producción, continuar investigando y revertir la aplicación |
| Datos aún faltantes tras reproducir binlog | Verificar si `--stop-datetime` es posterior al momento de inicio del respaldo; confirmar que la reproducción comienza desde el primer binlog posterior al respaldo |

## 6. Plantilla de registro del simulacro

```text
Fecha: 2026-08-16
Objetivo de restauración: base vacía (escenario A) / punto en el tiempo (escenario B)
Archivo de respaldo: backups/backup_20260816_020000.sql.gz
Conteos de línea base: erik_admin_user=1, erik_owner=42, erik_fee_bill=128
Tiempo de restauración: XX minutos    Tiempo de verificación: XX minutos    Total: XX minutos (objetivo ≤ 30)
Resultado: aprobado / fallido (adjuntar motivo del fallo y manejo)
```
