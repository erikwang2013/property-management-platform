# Plan de Escalado (Scaling Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

El despliegue actual es docker-compose de una sola máquina (MySQL/Redis/Elasticsearch y la aplicación en el mismo host, ver `admin/docker-compose.yml`), sin HA. Este documento explica los riesgos y las mitigaciones existentes, y proporciona la ruta de escalado horizontal, los puntos de activación por volumen de datos y las recomendaciones de simulacros. La línea base de operaciones (respaldo/restauración, monitoreo y alertas, rotación de logs) se encuentra en [OPS_RUNBOOK.md](OPS_RUNBOOK.md).

---

## 1. Despliegue actual y riesgos

### 1.1 Estado actual

| Componente | Versión | Descripción |
|------|------|------|
| MySQL | 8.0.36 | Instancia única, datos persistidos en volumen del host |
| Redis | 7.2-alpine | Instancia única, caché/cola/bloqueos |
| Elasticsearch | 8.12.0 | Nodo único, búsqueda de texto completo con scout |
| nginx + webman | — | admin (8787) y service (8788) multiproceso en el mismo host |
| Prometheus + Grafana | — | Monitoreo y alertas, mismo host |

### 1.2 Lista de riesgos

| Riesgo | Impacto | Probabilidad | Consecuencia |
|------|------|------|------|
| Punto único de fallo (caída de cualquier middleware) | Todo el sitio no disponible | Baja | Alta |
| Contención de disco/memoria/CPU del host | Consultas lentas, ES lento, OOM | Media (aumenta con el crecimiento de datos) | Media |
| Daño irrecuperable de la instancia única de MySQL | Pérdida de datos | Muy baja | Muy alta |
| Sin centro de datos de recuperación ante desastres | Pérdida total por fallo a nivel de centro de datos | Muy baja | Muy alta |
| Simulacros de respaldo/restauración no realizados | Restauración con timeout o fallida | Media | Alta |

## 2. Mitigaciones existentes (implementadas)

- **Respaldo**: script de respaldo de entrada única `scripts/backup.sh` (lee la conexión de `admin/.env`, mysqldump dentro del contenedor por defecto), respaldo completo diario por crontab, retención predeterminada de 7 días (`--keep-days=30` configurable); el proceso de simulacro de restauración y la explicación de RPO/RTO se encuentran en OPS_RUNBOOK §1 y RECOVERY_RUNBOOK.
- **Monitoreo y alertas**: Prometheus + Grafana + `deploy/monitoring/alerts.yml`, cubre AppDown / MysqlDown / RedisDown / ElasticsearchDown / QueueBacklog, ver OPS_RUNBOOK §3.
- **Rotación de logs**: logs de contenedor `max-size 10m`, logs del host con logrotate diario con retención de 30 días, ver OPS_RUNBOOK §4.
- **Capa de aplicación**: webman multiproceso residente, tareas de cola desacoplan operaciones lentas, verificación de salud `/health`.

Conclusión: las mitigaciones anteriores cubren «fallo recuperable», **no cubren «fallo sin interrupción»**. Si el negocio no puede aceptar interrupciones, se debe entrar en el escalado horizontal de §3.

## 3. Ruta de escalado horizontal (por prioridad)

Principio general de escalado: primero vertical (más CPU/memoria/disco) y luego horizontal (dividir componentes), primero middleware y luego aplicación, cada paso es reversible de forma independiente.

### 3.1 MySQL maestro-esclavo + semisíncrono (primera prioridad)

- Arquitectura: maestro (instancia existente) → esclavo (máquina nueva), activar replicación semisíncrona (`rpl_semi_sync_master_enabled=1`).
- Escalado de lectura: la aplicación configura separación maestro-esclavo (actívela si `config/database.php` la soporta; de lo contrario, primero haga solo alta disponibilidad maestro-esclavo).
- Migración de respaldo: el script de respaldo se apunta al esclavo para evitar presionar al maestro.
- Versión: el esclavo debe coincidir con la versión mayor del maestro (actualmente 8.0.36).
- Condiciones de actualización: CPU del maestro sostenida >70%, conexiones cerca de max_connections, aumento brusco de filas escaneadas en el log de consultas lentas.

### 3.2 Redis Sentinel o Cluster (segunda prioridad)

- Sentinel (3 nodos): elija Sentinel cuando el requisito de capacidad no sea alto; conmutación en segundos; el cliente debe soportar el modo `sentinel`.
- Cluster (≥3 maestros 3 esclavos): elija Cluster cuando la cantidad de caché supere la memoria de una sola máquina o aumente la concurrencia de escritura.
- Nota: las colas y los bloqueos distribuidos dependen de Redis; al cambiar la topología, modifique `config/redis.php` en consecuencia y verifique el comportamiento de bloqueos/colas bajo conmutación por error.

### 3.3 Nodo independiente de Elasticsearch

- ES de nodo único sin réplicas: si el índice se daña, la búsqueda no está disponible. Migre al menos a una máquina independiente + 1 réplica.
- Cuando crezca el volumen de datos, divida los índices (por dominio de negocio) y desactive réplicas de índices no necesarios para controlar recursos.
- Condiciones de actualización: uso de memoria heap >70% sostenido, rechazos de escritura (`es_rejected_executions` en aumento), p95 de consultas >1s.

### 3.4 Múltiples réplicas de aplicación + balanceo de carga (por último)

- Inicie 2+ réplicas de admin/service cada una, con nginx como balanceador frontal (round-robin o least_conn).
- Requisito previo: sin estado (sesión en Redis, sin dependencia de archivos locales; este sistema con JWT + sesión Redis cumple básicamente).
- Luego multiplique la capacidad de procesamiento por el número de réplicas y vuelva a los cuellos de botella de middleware de §3.1-3.3.

## 4. Puntos de activación por crecimiento de datos y recomendaciones

| Punto de activación | Umbral sugerido | Acción obligatoria |
|--------|----------|----------|
| Volumen total de base de datos | > 50GB o una tabla > 50 millones de filas | Separación maestro-esclavo + archivar tablas históricas de facturas/logs |
| Consultas lentas | Promedio diario > 10 o una sola > 2s | Añadir índices, particionar tablas, verificar N+1 |
| Conexiones MySQL | Sostenido > 80% de max_connections | Pool de conexiones + maestro-esclavo |
| Memoria Redis | > 70% y creciendo | Limpiar claves expiradas → Sentinel → Cluster |
| Memoria heap ES | > 70% o rechazos de escritura | Nodo independiente + réplicas + división de índices |
| CPU | Núcleo sostenido > 80% y cola acumulada | Múltiples réplicas de aplicación → división de middleware |
| Disco | > 80% | Limpiar respaldos/logs, archivar datos fríos |

Recomendación: verificar la tabla anterior mensualmente (los datos pueden provenir de los paneles de Grafana); si algún elemento supera el umbral durante dos semanas consecutivas, inicie el escalado correspondiente.

## 5. Recomendaciones de simulacros de escalado

- **Una vez por trimestre**: simulacro de restauración (ver OPS_RUNBOOK §1.3), verificando que se cumplan RPO/RTO.
- **Una vez al año**: simulacro de conmutación maestro-esclavo (practique en una máquina nueva, no toque el maestro de producción): crear esclavo → ponerse al día → conmutar → verificar lectura/escritura en ambos extremos → volver a conmutar.
- **Después del primer escalado**: use `scripts/loadtest` para probar tres rutas (login/lista/búsqueda) y confirmar que p95 cumple (referencia `docs/PERFORMANCE_REPORT_2026-08-16.md`).
- **Registro de simulacros**: cada simulacro se registra en el log de cambios (CHANGELOG.md), incluyendo: fecha, elemento del simulacro, resultado, problemas pendientes.

## 6. Referencia rápida de la ruta de actualización

```
Una sola máquina (estado actual)
  ├─ MySQL maestro-esclavo semisíncrono   ← Primera prioridad
  ├─ Redis Sentinel/Cluster    ← Segunda prioridad
  ├─ Nodo ES independiente + réplicas   ← Tercera prioridad
  └─ Múltiples réplicas de aplicación + LB   ← Por último
        ↓
Despliegue multi-máquina (sin punto único, acepta interrupción por fallo → acepta interrupción de minutos → conmutación en segundos)
```

> Con el volumen de negocio actual no se necesita escalado; este documento sirve para «hacerlo directamente» cuando cambien los requisitos de datos/fallos, evitando decisiones improvisadas.
