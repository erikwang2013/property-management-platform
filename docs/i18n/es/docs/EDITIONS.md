# Comparación de Versiones (Editions Comparison)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

El sistema de gestión de propiedades se divide en tres versiones: Edición Básica (Lite), Edición Estándar (Standard) y Edición Completa (Full), con progresión acumulativa por niveles.

---

## Resumen

| Indicador | Edición Básica (Lite) | Edición Estándar (Standard) | Edición Completa (Full) |
|------|:-----------:|:---------------:|:-----------:|
| Tablas de base de datos | **21** | **31** | **65** |
| Modelos Eloquent | 19 | 30 | 58 |
| Controladores del panel de administración | 17 | 28 | 47 |
| Controladores del portal de propietarios | 9 | 12 | 17 |
| Rutas de API | 35 | 70 | 178 |
| Módulos de negocio | 10 | 18 | 34 |
| Capas de seguridad | 18 capas | 18 capas | 18 capas |

---

## Comparación de módulos funcionales

### Edición Básica (Lite)

Gestión de propiedades principal, incluye el sistema general del panel de administración + 10 módulos de negocio principales.

**Panel de administración**: panel, CRUD de usuarios/roles/permisos/configuración/logs, CRUD de comunidad/edificio/unidad/tipo de vivienda/propiedad/propietario/inquilino/cargos/reparación/aviso

**Portal de propietarios**: registro/inicio de sesión, inicio, mis propiedades, pago de facturas, envío/evaluación de reparaciones, consulta de avisos, información personal

---

### Edición Estándar (Standard)

Añade 6 módulos de negocio auxiliares sobre la Básica + visualización de panel + exportación de datos.

**Nuevo en el panel de administración**: CRUD de espacios de estacionamiento/vehículos, registro de equipos + mantenimiento, gestión de quejas + seguimiento, aprobación de visitantes, gestión de contratos, gestión de ingresos/gastos + estadísticas

**Nuevo en el portal de propietarios**: mis vehículos/espacios, registros de estacionamiento, reserva de visitantes/código de paso

---

### Edición Completa (Full)

Añade módulos avanzados + 12 funciones extendidas sobre la Estándar.

**Nuevo en el panel de administración**: rutas de patrullaje + registros, zonas de limpieza + registros, zonas verdes + mantenimiento, gestión de actividades comunitarias, medidores de energía + lectura, gestión de empleados, plantillas de notificación + envío, motor de aprobación, órdenes de pago + reembolsos, gestión de votaciones + reglas SLA + estrategias de cobro + tareas de inspección + gestión de tienda + revisión facial + gestión de grupos + base de conocimiento

**Nuevo en el portal de propietarios**: inscripción a actividades comunitarias, reserva de estacionamiento/visitantes, notificaciones de mensajes, votaciones + recuento, navegar productos + realizar pedidos, Q&A inteligente, registro facial

---

## Comparación de indicadores técnicos

| Indicador | Básica | Estándar | Completa |
|------|:------:|:------:|:------:|
| Tablas de base de datos | 21 | 31 | 65 |
| Archivos de modelo | 19 | 30 | 58 |
| Controladores admin | 17 | 28 | 47 |
| Controladores service | 9 | 12 | 17 |
| Rutas admin | 45 | 80 | 123 |
| Rutas service | 20 | 35 | 55 |
| Páginas Flutter Admin | 4 | 7 | 57 |
| Páginas HarmonyOS | 2 | 3 | 7 |
| Middleware | 7 | 8 | 9 |
| Pruebas PHP | 18 | 18 | 133 |

---

## Sistema de seguridad (común a las tres versiones)

Defensa en profundidad de 18 capas: código de verificación → confirmación de contraseña → verificación aleatoria → escaneo de seguridad → intercepción de ataques → HTTPS + AES-256-CBC → JWT → control de sesión → bloqueo de cuenta → RBAC → límite de velocidad → protección de ID → cifrado de solicitud → cifrado de almacenamiento → enmascaramiento de presentación → auditoría → CSP → marca de agua de copyright

---

## Ruta de migración

```
Edición Básica (Lite)
  │
  │  + 6 módulos auxiliares + panel + exportación
  ▼
Edición Estándar (Standard)
  │
  │  + 6 módulos avanzados + 12 funciones extendidas
  ▼
Edición Completa (Full)
```

La actualización solo requiere ejecutar los archivos de migración SQL del lote correspondiente, sin migración de datos ni cambios destructivos.

---

## Flujo de demostración

**Preparación**: se ha ejecutado `docs/install.sql` (estructura completa de tablas, incluye tablas de todas las versiones); `admin/.env` tiene la conexión de base de datos configurada. Las diferencias de versión están en el registro de rutas y la visibilidad de funciones; la estructura de tablas es única y completa.

### Edición Básica (Lite)

1. Ejecutar datos de demostración: `cd admin && php ../scripts/demo_data.php` (idempotente, se puede ejecutar repetidamente)
2. Alcance de los datos de demostración: comunidad/edificio/unidad/tipo de vivienda/propiedad/propietario/inquilino/cargos/facturas/avisos + cuentas de demostración, cubre los módulos principales de Lite
3. Qué ver: panel del panel de administración + CRUD de usuarios/roles/permisos/configuración/logs + CRUD de propiedades/propietarios/inquilinos/cargos/reparaciones/avisos; en el portal de propietarios: registro/inicio de sesión, inicio, mis propiedades, pago de facturas, reparaciones, avisos
4. Diferencias de rutas: solo se registra el grupo Lite; los bloques envueltos con `edition_supports('standard'/'full')` no se registran (`admin/config/route.php`)

### Edición Estándar (Standard)

1. Ejecutar datos de demostración: `cd admin && php ../scripts/demo_data.php` (idempotente, la re-ejecución solo completa lo que falta sin duplicar datos)
2. Los módulos auxiliares tienen pocos datos; estacionamiento/equipos/quejas/visitantes/contratos/ingresos-gastos se pueden ingresar con pocos datos de demostración
3. Qué ver: en el panel de administración, nuevos espacios de estacionamiento/vehículos, registro de equipos + mantenimiento, gestión de quejas + seguimiento, aprobación de visitantes, gestión de contratos, gestión de ingresos/gastos + estadísticas; en el portal de propietarios, nuevos mis vehículos/espacios, registros de estacionamiento, reserva de visitantes/código de paso
4. Diferencias de rutas: se añade el grupo `edition_supports('standard')`, el grupo Lite se conserva

### Edición Completa (Full)

1. Ejecutar datos de demostración: `cd admin && php ../scripts/demo_data.php` (idempotente)
2. Los datos de demostración de los módulos avanzados (pagos/aprobaciones/votaciones/tienda/inspección/facial/grupos/base de conocimiento) se ingresan según necesidad, o se crean directamente con la cuenta de demostración
3. Qué ver: sobre Standard, nuevos patrullaje/limpieza/jardinería/energía/empleados/plantillas de notificación/motor de aprobación/órdenes de pago/votaciones/SLA/cobros/inspección/tienda/facial/grupos/base de conocimiento; en el portal de propietarios: inscripción a actividades, notificaciones de mensajes, votaciones, pedidos de tienda, Q&A inteligente, registro facial
4. Diferencias de rutas: registro completo, el grupo `edition_supports('full')` entra en vigor (`admin/config/route.php`)

### Cambio de versión

```bash
# Establecer la versión objetivo en admin/.env (progresión acumulativa, full incluye todas las funciones)
EDITIONS=lite|standard|full

# Reiniciar webman para que surta efecto (despliegue en contenedor: docker compose restart app; bare metal: php start.php restart)
```

- Configuración fail-fast: un valor `EDITIONS` inválido lanza un error directamente (`admin/config/edition.php`), sin volver silenciosamente a una versión incorrecta.
- El script de datos de demostración es idempotente; no es necesario limpiar la base al cambiar entre versiones; los módulos Standard/Full tienen pocos datos y se pueden ingresar con negocio real.
