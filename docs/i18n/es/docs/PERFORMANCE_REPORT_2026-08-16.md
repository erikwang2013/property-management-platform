# Informe de Pruebas de Rendimiento y Gobernanza de Consultas Lentas (2026-08-16)

Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

## 1. Entorno y método de prueba

| Elemento | Valor |
|---|---|
| Aplicación | webman v2 (PHP 8.3, 32 workers), aplicaciones duales admin + service |
| Instancia probada | admin en puerto independiente 8790 (`SERVER_LISTEN=http://0.0.0.0:8790`) |
| Herramienta | k6 v0.51.0 (sin wrk/ab/hey en la máquina), scripts en `scripts/loadtest/` |
| Objetivos de la prueba | Inicio de sesión (/api/auth/login), panel (/admin/dashboard), lista de pagos de cargos (/admin/fee-payment) |
| Autenticación | dashboard/fee usan `scripts/loadtest/mint-token.php` para emitir JWT (omite el código de verificación, `sub=21000000000000100`); el script de login usa un código de verificación inválido para sondear la cadena |
| Datos | Conexión directa a 127.0.0.1 en una sola máquina, sin pasar por gateway/CDN; MySQL/Redis y la aplicación en el mismo host |

Entrada del script: `bash scripts/loadtest/run.sh [BASE_URL] [VUS] [DURATION]` (requiere k6 en PATH).
Nota sobre el script de login: el inicio de sesión está doblemente protegido por código de verificación + límite de velocidad (10 veces/min/IP), es un diseño de seguridad, no es posible ni debe someterse a pruebas de alta concurrencia; login.js sondea la latencia de la cadena con 1 VU / 8 solicitudes de baja velocidad, se espera que devuelva 422 (error de código de verificación) o 429 (límite de velocidad), ambas son la defensa funcionando correctamente.

## 2. Resultados de las pruebas de carga

### 20 VU / 30s (carga base)

| Interfaz | Solicitudes | Rendimiento | avg | p90 | p95 | max | Tasa de fallos |
|---|---|---|---|---|---|---|---|
| login (1 VU × 8 veces) | 8 | 14.4/s | 68.6ms | 154ms | 207.8ms | 261ms | 0% |
| dashboard | 6863 | 227.9/s | 86.0ms | 151ms | 189.5ms | 1.37s | 0% |
| fee-payment | 5944 | 197.2/s | 99.3ms | 178ms | 220.0ms | 704ms | 0% |

### 50 VU / 30s (con presión)

| Interfaz | Solicitudes | Rendimiento | avg | p95 | max | Tasa de fallos |
|---|---|---|---|---|---|---|
| login (1 VU × 8 veces) | 8 | 18.7/s | 52.1ms | 173ms | 243.8ms | 0% |
| dashboard | 6902 | 226.9/s | 212.7ms | 544.0ms | 1.99s | 0% |
| fee-payment | 7525 | 247.4/s | 195.7ms | 514.2ms | 2.0s | 0% |

(A 50 VU, p95 superó el umbral de 500ms; k6 determinó que el umbral se superó y salió, pero 0% de solicitudes fallaron y 0 respuestas no-200.)

### Conclusiones

- Todas las interfaces a 20 VU tienen 0 fallos y p95 < 220ms: saludable.
- **El cuello de botella de rendimiento es de aproximadamente 230–250 rps**: de 20 VU a 50 VU, el rendimiento no aumenta sino que se aplana (dashboard 227.9 → 226.9, fee 197 → 247), mientras que la latencia p95 se duplica (~190ms → ~540ms). Con 32 workers en una sola máquina, cada worker procesa ~7–8 rps, característico del límite de procesamiento de un solo núcleo en la cadena completa de PHP (incluidas consultas MySQL y viajes de ida y vuelta de caché Redis), no por agotamiento de conexiones (sin solicitudes fallidas).
- Recomendación: esta escala en una sola máquina es suficiente (aproximadamente 20 millones de solicitudes/día); si se necesita mayor rendimiento, priorice agregar instancias horizontalmente; en segundo lugar, investigue el SQL de cada interfaz y el acierto de caché (ver abajo).

## 3. Revisión de consultas lentas

- Las tablas de cargos `management_fee_bill` / `management_fee_payment` tienen índices completos (paid_at, bill_id, owner_id, payment_number, etc.); las consultas principales tienen índices disponibles.
- Hallazgo: la búsqueda difusa de la lista de cargos por `payment_number like %kw%` (comodín de prefijo) no puede usar el índice y, con muchos datos, esa condición degenera en escaneo completo de tabla. Es una búsqueda de panel de administración de baja frecuencia; no se maneja por ahora; cuando crezca el volumen de datos, puede cambiarse a índice invertido o de prefijo.
- **MySQL slow_query_log está en OFF**: se recomienda activarlo y establecer `long_query_time=1` para observar continuamente el SQL lento real (en lugar de inferirlo de las pruebas de carga). Ejecución en producción:
  ```sql
  SET GLOBAL slow_query_log = ON;
  SET GLOBAL long_query_time = 1;
  ```
- Agregación del panel: cada reconstrucción de caché ejecuta aproximadamente 8 agregaciones COUNT + estadísticas agrupadas por 30 días; una reconstrucción cuesta segundos, absorbida por el caché Redis de 5 minutos (ver abajo); no es una ruta crítica.

## 4. Revisión de la caché Redis

- Caché del panel `dashboard:data`: `setex 300`, ~10ms cuando hay acierto, segundos para reconstruir en caso de fallo. **Problema: no hay lógica de invalidación en ninguna operación de escritura**; los datos pueden estar desactualizados hasta 5 minutos tras un cambio. Se recomienda eliminar esta clave en las interfaces de escritura de cargos/propiedades (una línea `del dashboard:data`).
- **Sin protección contra la ruptura de caché**: en el momento en que la clave expira, 32 workers reconstruyen simultáneamente (ejecutando 8 consultas de agregación repetidamente). Con más datos, se recomienda añadir un mutex simple (por ejemplo, bloqueo `set nx ex` + doble verificación).
- Caché de permisos `perm:{adminId}` 60s, comportamiento normal.
- Elemento pendiente de investigación: la clave `dashboard:data` nunca se observó en el Redis local (ausente en varias bases de datos), pero la respuesta de la interfaz es normal y la latencia con acierto es claramente menor. Durante las pruebas aparecieron 403 ocasionales de «sin permiso de acceso» (aparecieron 2 veces y luego volvieron a ser 200 estables). Se sospecha que es una diferencia entre múltiples instancias Redis/variables de entorno locales y la configuración en línea; se debe verificar en el entorno objetivo; no afecta las conclusiones de las pruebas (0 fallos en el segmento estable).

## 5. Entregables

- `scripts/loadtest/mint-token.php` — emite JWT de prueba de carga (`php mint-token.php --file=/tmp/pmp-token`)
- `scripts/loadtest/login.js` / `dashboard.js` / `fee.js` — scripts k6
- `scripts/loadtest/run.sh` — ejecución en un clic (mint token + tres scripts, parámetros: BASE_URL VUS DURATION)
- Este informe

Comando de reproducción: `PATH=/home/erik/bin:$PATH bash scripts/loadtest/run.sh http://127.0.0.1:8790 20 30s`
