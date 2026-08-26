# Evaluación del Plan SaaS Multiusuario (Multi-Tenant Plan)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz
> Estado: borrador de evaluación (P3-① tarea previa) | Fecha: 2026-08-16

## 1. Inventario del estado actual

### 1.1 Clasificación de estructura de tablas (65 tablas, verificado en docs/install.sql)

| Categoría | Tablas | Descripción |
|------|-----|------|
| Tablas globales/de plataforma | erik_admin_user / admin_role / admin_permission / admin_user_role / admin_role_permission、erik_system_config、erik_operation_log | Autenticación, configuración, auditoría; naturalmente a nivel de plataforma, sin inquilino |
| Tablas de dimensión de comunidad | erik_community y 40+ tablas de negocio atribuidas mediante community_id (building/unit/room/owner/fee_*/repair_order/parking_*/announcement, etc.) | Atribuidas indirectamente al inquilino mediante community_id |
| Tablas de asociación de grupo | erik_group (grupo)、erik_group_community (grupo↔comunidad) | Actualmente es una **asociación opcional**, sin semántica de inquilino; el resumen multicomunidad depende de join |
| Tablas de extensión de plataforma | erik_notification_template、erik_knowledge_base、erik_mall_*、erik_face_info, etc. | Algunas a nivel de plataforma, otras a nivel de comunidad; requiere confirmación caso por caso |
| Tablas fácilmente confundibles | **erik_tenant (tabla de inquilinos de vivienda)** | ⚠️ Conflicto semántico: es «inquilino de vivienda» (dimensión room_id/owner_id), **no** es un inquilino SaaS |

### 1.2 Cadena de autenticación (extremo admin, verificado en código)

```
Middleware global: Cors → SecurityFilter → RateLimit
Middleware de grupo de rutas: AdminAuth(JWT → $request->adminId) → AdminPermission(RBAC method.path) → OperationLog → Controller
```

- `AdminAuth` ya establece el patrón de inyección de solicitud (`$request->adminId`); el contexto de inquilino puede replicarlo completamente
- `AdminPermission` es RBAC a nivel de plataforma, **ortogonal** al aislamiento de inquilinos, se puede superponer
- Portal de propietarios de service: JWT porta owner_id, los datos están naturalmente restringidos por room_owner → room.community_id, bajo riesgo de cruce entre inquilinos

### 1.3 Conclusiones clave

- No existe ningún modelo SaaS de inquilinos actual; el nombre `erik_tenant` ya está ocupado por los inquilinos de vivienda; el nuevo concepto debe evitar ese nombre
- Todos los controladores consultan directamente con Eloquent, sin capa repository, sin scopes globales — la transformación de aislamiento debe hacerse en la capa de modelos
- config/database.php tiene una sola conexión, pero illuminate/database soporta nativamente múltiples connections (reservado para la evolución a base de datos separada)

## 2. Comparación de planes y recomendación

| Plan | Mecanismo | Volumen de transformación | Costo operativo | Adecuado para |
|------|------|--------|----------|------|
| **A. Base de datos compartida + aislamiento por filas con tenant_id (recomendado)** | Tabla de inquilinos + columna tenant_id en tablas de negocio + filtro con scope global de Eloquent | Medio (añadir columna a 2 tablas + middleware + scope global + relleno de datos existentes) | Bajo (el respaldo/migración de una sola base no cambia) | Propiedades medianas y pequeñas, inquilino único < 5 millones de filas |
| B. Base de datos independiente (una por inquilino) | Enrutamiento de conexiones + agregación entre bases | Alto (gestión de conexiones/informes entre bases/migración×N/respaldo×N) | Alto | Grandes grupos, requisitos de aislamiento por cumplimiento |
| C. Híbrido (base sensible independiente + compartida) | Combinación A+B | Alto | Alto | Escenarios de aislamiento fuerte como pagos/reconocimiento facial |

**Se recomienda A; B es la dirección de evolución.** Razones:

1. Las 65 tablas actuales están unificadas en una sola base; el modelo de datos con tenant_id de A no obstaculiza el futuro desglose de bases (la granularidad del filtro pasa de fila a base; con A, el ID de inquilino ya está modelado globalmente)
2. Todos los datos de negocio se atribuyen mediante community_id; tenant_id solo necesita añadirse a las **tablas de nivel superior**; las 40 tablas de negocio intermedias quedan garantizadas por la ruta de acceso, evitando añadir columnas tabla por tabla
3. Ambos extremos (admin/service) comparten el mismo modelo de datos; la transformación de A se concentra en la capa de ejecución del extremo admin
4. Con el despliegue actual de una sola máquina, la complejidad de respaldo/migración de B es inaceptable

## 3. Diseño de puntos de aislamiento

### 3.1 Modelo de datos (conjunto mínimo)

- Crear `erik_platform_tenant` (para evitar conflicto con la tabla de inquilinos erik_tenant): id/name/status/created_at, etc.
- `erik_community` añade `tenant_id BIGINT NOT NULL DEFAULT 0`, índice `(tenant_id, community_id)`
- `erik_admin_user` añade `tenant_id BIGINT NOT NULL DEFAULT 0` (0 = superadministrador de plataforma)
- Las tablas de negocio intermedias (building/room/fee_bill y otras 40) **no añaden columnas**, se atribuyen mediante community_id

### 3.2 Tríada de capa de ejecución

1. **Middleware TenantContext**: el payload JWT añade la declaración `tenant_id` → `$request->tenantId` (replica el patrón de inyección de AdminAuth); lista de exención para login/instalación/rutas de nivel de plataforma (user/role/permission/config)
2. **Scope global TenantScope**: montar scope global de Eloquent en Community y modelos de negocio de nivel de plataforma, filtrando automáticamente por `$request->tenantId`; `find()` también está restringido por el scope, previniendo naturalmente consultas directas de una sola fila entre inquilinos
3. **Contexto explícito Tenant::for()**: tareas programadas/colas/importaciones sin solicitud HTTP usan cierres para especificar explícitamente el inquilino; cuando falta contexto, **fail-closed** (rechazar consulta), sin permitir pasar en silencio sin filtro

### 3.3 Puntos clave de las pruebas de prevención de excesos (matriz de aceptación)

| Caso de uso | Resultado esperado |
|------|------|
| Administrador del inquilino A lista community/building/fee_bill del inquilino B | Devuelve vacío o solo datos de A |
| Administrador del inquilino A hace find/update/delete de un registro único del inquilino B (consulta directa por id) | 403 / datos vacíos / rechazo |
| Administrador de plataforma (tenant_id=0) opera entre inquilinos | Permite (capacidad de nivel de plataforma) |
| Propietario de service opera en otra comunidad (pagos/reparaciones) | Rechazo (verificación de atribución community) |
| Tareas programadas/colas sin contexto de inquilino | Error fail-closed en lugar de operar sin filtro |

## 4. Ruta de evolución (migración por pasos)

| Paso | Contenido | Aceptación |
|------|------|------|
| 1. Capa de datos | Crear tabla platform_tenant + añadir columnas a community/admin_user + migración idempotente + inicialización del inquilino predeterminado y relleno de datos existentes | Cada community debe tener inquilino; el informe de datos huérfanos debe ser cero |
| 2. Capa de ejecución | Middleware TenantContext + TenantScope + utilidad Tenant::for() + lista de rutas exentas | Regresión de inquilino único: pasan las 133 pruebas completas |
| 3. Módulos piloto | Habilitar primero el aislamiento en 4 módulos: gestión de grupos → comunidad → propietarios → cargos (facturas) | Pasa la matriz de pruebas de excesos |
| 4. Despliegue completo | Habilitar módulo por módulo por lotes (núcleo del lote 1 → auxiliares del lote 2 → módulos de extensión) | Pasan las matrices de excesos de todos los módulos |
| 5. Evolución | Evaluar el desglose de base (plan B) cuando los datos de un inquilino superen 5 millones de filas o haya requisitos de cumplimiento; el modelo de datos de A no bloquea | Evaluación del plan de desglose de base |

Estrategia de migración de datos: todos los datos existentes se asignan al «inquilino predeterminado» (creado por el script de migración), sin eliminar ni modificar datos de negocio; el script de migración es idempotente y se puede ejecutar repetidamente.

## 5. Lista de riesgos

| Riesgo | Área de impacto | Mitigación / reversión |
|------|--------|-------------|
| Gran volumen de transformación de las rutas de consulta de los controladores 58+17 | Todas las interfaces de negocio | El scope global cubre ~80% de listas/detalles; raw query e importación masiva usan Tenant::for(); despliegue gradual por lotes |
| El scope global afecta por error consultas de nivel de plataforma (resumen multicomunidad del panel) | Panel/informes | Las interfaces de nivel de plataforma usan explícitamente Tenant::without() o bypass con tenant_id=0 |
| Tareas programadas/colas sin contexto de solicitud | Tareas de fondo como cobros/SLA/notificaciones | Envolver explícitamente con Tenant::for() + fail-closed |
| Errores de relleno de datos existentes | Todos los datos existentes | Script idempotente + validación de relleno + modo dry-run |
| Impacto de índices/rendimiento | Tablas de alta frecuencia (fee_bill/room/owner) | Índice compuesto (tenant_id, community_id); revisión con log de consultas lentas |
| Regresión de las 133 pruebas | Todo | Ejecutar regresión completa después de inyectar el scope antes de iniciar el piloto |
| Confusión de nombres (inquilino de vivienda erik_tenant vs inquilino SaaS) | Cognición de desarrollo | Nombrar la nueva tabla platform_tenant, declararlo explícitamente en la documentación |
| **Plan de reversión** | — | El scope global se puede desactivar con un interruptor de configuración en un clic (restaurando la semántica de inquilino único); las columnas de datos se conservan sin eliminar; sin cambios destructivos |

## 6. Conclusión de la evaluación

**Se recomienda hacer inmediatamente**:
- Base compartida + aislamiento por filas con tenant_id (plan A), crear la tabla `erik_platform_tenant`, añadir columnas a community/admin_user
- Middleware TenantContext + scope global TenantScope + utilidad Tenant::for()
- Orden del piloto: grupo → comunidad → propietarios → cargos
- Dependencia previa: completada — tablas/columnas/relleno de multiusuario ya integrados en docs/install.sql (fusionado el 2026-08-16, entrada única de creación de base)

**Se recomienda posponer**:
- Aislamiento con base independiente (B): solo iniciar cuando un inquilino supere 5 millones de filas o haya requisitos de cumplimiento; el modelo de datos ya está preparado
- Plan híbrido (C): evaluar solo si el cliente solicita explícitamente escenarios de aislamiento fuerte como pagos/reconocimiento facial

**No se recomienda hacer**:
- Aislamiento a nivel de esquema (MySQL no tiene semántica de esquema independiente; el costo equivale a base independiente)
- Enrutamiento dinámico multi-base (sin beneficio en despliegue de una sola máquina)
- Esquemas/campos personalizados por inquilino (YAGNI)
- Reutilizar/transformar la tabla de inquilinos de vivienda erik_tenant como inquilino SaaS (conflicto semántico, rompe el negocio de inquilinos)
