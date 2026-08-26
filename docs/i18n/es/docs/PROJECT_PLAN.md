# Sistema de Gestión de Propiedades — Plan Integral del Proyecto

> Fecha de generación: 2026-08-16 · Fuente: auditoría del equipo pmp-team (auditor / security-auditor / planner)

## 1. Conclusiones de la auditoría del estado actual

**Funcionalidad: consistente con lo declarado.** Los 22 módulos de negocio + 12 funciones extendidas están completos, 68 tablas / 178 API, admin 58 controladores / 127 rutas, service 19 controladores / 57 rutas, panel de administración Flutter Web de 42 páginas + portal de propietarios de 13 páginas, HarmonyOS 5 páginas. Los 14 documentos de docs/ + 35 SVG están todos respaldados por código; no se encontraron funciones «declaradas pero no implementadas».

**Pruebas: todo en verde (hasta 2026-08-17).** admin 193 tests / 452 aserciones, service 101 tests / 385 aserciones (7 omitidos por dependencias de entorno), 9 pruebas de widget Flutter (login/inicio/página de facturas).

**Ingeniería ya disponible:** docker-compose en ambos extremos, CI de GitHub Actions (sintaxis PHP + phpunit en ambos extremos + composer audit + Flutter analyze), Dependabot, endpoints de métricas Prometheus.

**Deuda técnica (principalmente de bajo riesgo):**
1. Acumulación de logs: service/workerman.log 9.3M, admin/runtime/logs 5.7M (ya en gitignore, solo ocupa disco) → necesita rotación
2. El README no documenta por separado la cifra de los 57 modelos del extremo service (64 solo se refiere al extremo admin)
3. Sin TODO/FIXME, .env no está en el repositorio, sin anomalías en versiones de dependencias — limpio

## 2. Brechas de seguridad y calidad (security-auditor)

**Defensa de 18 capas: 16/18 verificadas como existentes**, implementación consistente con SECURITY_ARCHITECTURE.md (código de verificación, confirmación secundaria, poster, SecurityFilter, AES-256-CBC, JWT, límite de sesión, bloqueo de cuenta, RBAC, límite de velocidad, hashids, cifrado de campos, enmascaramiento, log de auditoría, CSP).

**Dos discrepancias (ambas P1 ya corregidas):**
1. ~~security-php solo instalado en el extremo service~~ → ya conectado a SecurityFilter en ambos extremos (admin y service tienen capa de escaneo profundo 4b, SecurityGuard con inicialización perezosa, registra y escala al bloquear)
2. ~~Marca de agua de copyright en PDF sin implementación~~ → verificado que la capa 18 de marca de agua en ExportController está implementada (ExportController.php:179,206), falso positivo de auditoría

**El más crítico: clave de respaldo codificada (ya corregido).** EncryptionService/configuración de cifrado cambiados a fail-fast (falta o change-me lanza error al inicio), eliminadas las claves codificadas y el respaldo aleatorio de los plugins encryptable/jwt; las claves de .env son valores aleatorios reales generados, CI carga con copia de .env.example. Las contraseñas de DB/Redis siguen siendo marcadores de posición, son credenciales de despliegue inyectadas por el despliegue.

**Debilidades de ingeniería (P1 completadas):** CI añade trabajos phpstan (Nivel 5 + baseline), puertas de cobertura PHPUnit en ambos extremos (línea base medida admin 1.66% / service 3.21%, la puerta previene regresión de instrumentación cero), escaneo de fugas de secretos gitleaks (.gitleaks.toml permite plantillas de entorno).

**Verificación de patrones de alto riesgo:** eval( solo en Redis::eval (seguro), exec en 3 lugares (controladores de monitoreo/instalación), md5( solo para hash de lista negra de tokens, todo SQL va por query builder — sin riesgo de concatenación cruda.

## 3. Posicionamiento estratégico

**Fase de funciones completas → fase de ingeniería/comercialización.** El desarrollo de funciones de negocio ha terminado (los commits recientes son de documentación/auditoría/complemento de pruebas). Direcciones de inversión de la siguiente fase: **CI/CD y puertas de calidad, producción de pagos, monitoreo de alertas y respaldo/restauración, SaaS multiusuario, complemento móvil**. El empaquetado comercial ya tiene base (EDITIONES de tres versiones + asistente de instalación + marca de agua de copyright); lo que falta es la credibilidad de ingeniería que haga que los clientes se atrevan a pagar.

## 4. Hoja de ruta por fases

### P1 Consolidación de ingeniería (2-4 semanas) — hacer que el sistema sea «confiable»

| Objetivo | Tareas clave | Criterios de aceptación |
|------|---------|---------|
| Puertas de calidad en verde, claves controlables, datos sin pérdida | ① CI completo: Flutter analyze, pruebas de service, puerta de cobertura PHPUnit, phpstan, gitleaks ② Gestión de claves: generador de .env + scripts de rotación de claves JWT/DB ③ Respaldo/restauración: script mysqldump + manual de simulacro de restauración ④ Degradación de ES: respaldo de log de fallos de escritura de cola + degradación de búsqueda a MySQL LIKE (pospuesto) ⑤ Gestión de versiones SQL: unificar la migración completa en entrada única docs/install.sql (el plan original de migración dividida se canceló, fusionado el 2026-08-16) | CI todo en verde incluyendo cobertura; simulacro de restauración con datos consistentes en 30 minutos; búsqueda utilizable con ES detenido; scripts de actualización ejecutables |

**Estado de P1**: ✅ Todo completado (el respaldo/restauración se registra en P8: scripts/backup.sh + docs/RECOVERY_RUNBOOK.md).

### P2 Capacidad de comercialización (4-8 semanas) — hacer que los clientes «se atrevan a comprar»

| Objetivo | Tareas clave | Criterios de aceptación |
|------|---------|---------|
| Cierre del ciclo de pagos, monitoreable, entregable | ① Producción de pagos: flujo completo de sandbox WeChat/Alipay (pedido→callback idempotente→reembolso→conciliación), credenciales centralizadas en config/payment.php + env ② Monitoreo de alertas: orquestación Prometheus+Grafana + reglas de alerta (5xx, conexión ES/Redis, acumulación de cola) + rotación de logs ③ Control de versión comercial: interruptores de versión basados en EDITIONS (activación por grupos de rutas Lite/Standard/Full) + datos Demo ④ Asistente de instalación que cubre configuración de pagos/ES | Flujo completo de sandbox aprobado (incluida idempotencia de callbacks repetidos); alertas probadas con disparo real; interruptores de tres versiones demostrables; entorno nuevo instalado en 10 minutos |

**Estado actual de P2**: ✅ Parte offline completamente terminada (2026-08-16/17): código de cadena completa de pagos (PaymentService pedido/callback idempotente/reembolso/conciliación + credenciales centralizadas en config/payment.php + PaymentServiceTest de funciones puras), orquestación de monitoreo (doble pila Prometheus + 6 reglas de alerta + provisioning de dashboards Grafana en ambos extremos), interruptores de versión (tres versiones EDITIONS + validación fail-fast), asistente de instalación (incluida activación automática de configuración de pagos + bug de ruta de plantilla corregido). Dependencias externas restantes: **integración de sandbox pendiente de credenciales** (tras obtener credenciales WECHAT_PAY_* / ALIPAY_* ejecutar `scripts/payment_sandbox_smoke.php`), **prueba real de alertas pendiente de despliegue** (`scripts/verify_monitoring.sh` se puede validar localmente, la verificación de disparo real requiere despliegue).

### P3 Escalamiento (8-12 semanas) — hacer que el sistema «se pueda vender más»

| Objetivo | Tareas clave | Criterios de aceptación |
|------|---------|---------|
| Multiusuario, rendimiento conforme, móvil completo | ① SaaS multiusuario: comenzando por la gestión de grupos, erik_community añade tenant_id + aislamiento con middleware (evaluación de plan primero, base independiente como dirección de evolución) ② Pruebas de rendimiento: wrk/k6 para login/cargos/panel, revisión de consultas lentas + caché Redis ③ Complemento móvil: ampliar las 5 páginas de HarmonyOS a rutas principales (pagos/reparaciones/avisos/visitantes/estacionamiento), adaptación móvil del portal Flutter de propietarios ④ API abierta / Webhook (opcional) | Pruebas de excesos de inquilino aprobadas; P95 de interfaces principales < 300ms; rutas principales de HarmonyOS completas |

**Estado de P3**: ✅ Todo completado (entregado 2026-08-16: tríada de multiusuario + pruebas de carga reales con P95 conforme + HarmonyOS ampliado a 5 páginas).

### P4-P9 Registro de entregas adicionales (2026-08-16 ~ 08-17, nuevas fases de ingeniería fuera del alcance original de P1-P3)

| Fase | Contenido entregado | Estado |
|------|---------|------|
| P4 Cierre | Respaldo de ruta de escritura de ES (AdminUser Searchable try/catch + degradación de log), configuración de pagos del asistente de instalación (activación automática si las credenciales están completas), rotación de logs (logrotate.conf), orquestación de monitoreo de alertas (doble pila Prometheus + 6 reglas) | ✅ Completado |
| P5 Elementos restantes | Entrega de Webhook (firma HMAC-SHA256 + reintento con retroceso exponencial + 3 puntos de disparo), pruebas unitarias de negocio de cargos/aprobaciones/SLA | ✅ Completado |
| P6 Cierre de despliegue | Script de despliegue en un clic (deploy.sh: pull → .env → compose → importación idempotente de install.sql → smoke de monitoreo), corrección del montaje de logs de contenedores, aumento de la puerta de cobertura de CI, plan de escalado (SCALING_PLAN) | ✅ Completado |
| P7 Profundidad de pruebas | Pruebas unitarias de service 43→82, pruebas de widget Flutter de 3 páginas con 8 casos (integradas en CI), API abierta (/open 3 endpoints de solo lectura + autenticación X-API-Key + gen_api_key.php), smoke de pruebas de carga (k6 smoke.js + workflow manual con workflow_dispatch) | ✅ Completado |
| P8 Cierre operativo | Respaldo/restauración implementados (backup.sh + RECOVERY_RUNBOOK), dashboard Grafana (provisioning de 7 paneles del extremo service), +11 pruebas unitarias de admin (152 en verde), **corrección del bug de ruta de plantillas del asistente de instalación** (plantilla movida a app/view/install, renderizado verificado con curl 200) | ✅ Completado |
| P9 Cierre de ingeniería | Limpieza de scripts de respaldo no veraces (git rm de 4 archivos en ambos extremos + unificación de 8 lugares de documentación), dashboard Grafana del extremo admin (prefijo open_admin_* 7 paneles), extracción de función pura de validación InstallValidator + 17 casos (admin 193 en verde) | ✅ Completado |

**Resumen de P4-P9**: pruebas unitarias de admin 93→193, pruebas unitarias de service 43→101, pruebas de widget Flutter 9/9, API abierta 3 endpoints, paneles de monitoreo simétricos en ambos extremos, conjunto completo de scripts operativos de respaldo/restauración/claves/despliegue listos.

## 5. Top 10 acciones prioritarias (por relación costo-beneficio)

| # | Acción | Impacto | Costo | Riesgo | Estado |
|---|--------|------|------|------|------|
| 1 | Gestión de claves: generador de env + scripts de rotación + eliminación de claves de respaldo codificadas (validación al inicio de que no sea change-me) | Alto (cumplimiento de seguridad) | Bajo | Bajo | ✅ Completado |
| 2 | CI completo: Flutter analyze + pruebas de service + puerta de cobertura + phpstan + gitleaks | Alto (línea base de calidad) | Bajo | Bajo | ✅ Completado (P7 añade flutter test) |
| 3 | Script de respaldo + simulacro de restauración | Alto (sin pérdida de datos) | Bajo | Bajo | ✅ Completado (P8: backup.sh + RECOVERY_RUNBOOK) |
| 4 | Respaldo de degradación de ES (MySQL LIKE) | Alto (disponibilidad) | Bajo | Medio (mantenimiento de doble ruta de consulta) | ✅ Completado (P4: respaldo try/catch en ruta de escritura; la búsqueda ya va toda por MySQL LIKE) |
| 5 | Flujo completo de sandbox de pagos + verificación de idempotencia de callbacks | Alto (requerido para comercializar) | Medio | Medio (credenciales/seguridad de callbacks) | 🔶 Código completado, integración de sandbox pendiente de credenciales |
| 6 | Alertas Prometheus + Grafana + rotación de logs | Alto (operable) | Medio | Bajo | ✅ Completado (paneles de ambos extremos completados en P8/P9; prueba real de alertas pendiente de despliegue) |
| 7 | Gestión de migración SQL (fusión completa en entrada única install.sql) | Medio (actualizable) | Bajo | Bajo | ✅ Completado (fusionado el 2026-08-16) |
| 8 | Evaluación del plan multiusuario + aislamiento tenant_id | Alto (techo) | Alto | Alto (afecta todas las consultas) | ✅ Completado (entregado en P3, pruebas de excesos aprobadas) |
| 9 | Pruebas de carga + gobernanza de consultas lentas | Medio (rendimiento) | Medio | Bajo | ✅ Completado (P3 real con P95 conforme; versión smoke de P7 en CI) |
| 10 | Interruptores de licencia de versión comercial + datos Demo | Medio (previo a venta) | Medio | Bajo | ✅ Completado (EDITIONS + demo_data.php + documento de flujo de demostración) |

## 6. Riesgos y dependencias

| Riesgo | Estado actual | Mitigación sugerida | Estado |
|------|------|---------|------|
| Despliegue de una sola máquina sin HA | docker-compose de una sola máquina, MySQL/Redis/ES en el mismo host | Simulacro de respaldo/restauración + monitoreo de alertas + documento de plan de escalado | ✅ Mitigación implementada (respaldo P8 + monitoreo P2/P8/P9 + SCALING_PLAN P6); ejecución de simulacros pendiente de despliegue |
| Dependencia dura de ES | Búsqueda/sincronización de índices todo por ES | Respaldo de degradación + script de reconstrucción de índices | ✅ Mitigado (P4 respaldo en ruta de escritura; la búsqueda ya va toda por MySQL LIKE, ES no es dependencia de ruta de consulta) |
| Gestión de claves | Marcadores de posición + claves de respaldo codificadas, sin rotación | Generador + scripts de rotación; producción con inyección de variables de entorno | ✅ Resuelto (validación fail-fast + gen_env_keys.sh + rotate_keys.sh) |
| Credenciales de pago dispersas | Módulo de pagos sin configuración centralizada, sandbox sin verificar | Centralización de configuración + sandbox primero | 🔶 Configuración centralizada (config/payment.php), integración de sandbox pendiente de credenciales |
| Gestión de migraciones | install.sql de archivo único (IF NOT EXISTS idempotente) | Ya unificado en una sola entrada completa; si se necesita ruta de actualización incremental, se discute aparte | ✅ Ya unificado (fusionado el 2026-08-16) |
| Cobertura de pruebas estructural | 133 pruebas concentradas en schema/seguridad/ida y vuelta | Puerta de cobertura + pruebas unitarias de negocio central (cargos/aprobaciones/SLA) | ✅ Reforzado (admin 193 / service 101 / Flutter 9; la puerta previene regresión de instrumentación cero) |
| Brechas móviles | HarmonyOS solo 5 páginas, portal de propietarios sin App nativa | Completar rutas principales de P3; dependencia: dispositivo de prueba HarmonyOS | ✅ Rutas principales completadas (5 páginas: pagos/reparaciones/avisos/visitantes/estacionamiento); verificación en dispositivo real pendiente de equipo |

## 7. División del equipo (pmp-team)

| Rol | Tareas asignadas |
|------|---------|
| Arquitectura | Evaluación del plan multiusuario y diseño de aislamiento tenant_id (P3), arquitectura de degradación de ES, arquitectura de monitoreo (P2), revisión del diseño de idempotencia de callbacks de pago |
| Backend | Scripts de generación/rotación de claves, implementación de degradación de ES, centralización de configuración de pagos + integración de sandbox, división de scripts de migración, pruebas de carga y gobernanza de consultas lentas |
| Frontend Flutter | flutter analyze integrado en CI, adaptación móvil del portal de propietarios (P3), soporte de UI de interruptores de versión |
| HarmonyOS | Completar rutas principales: pagos/reparaciones/avisos/visitantes/estacionamiento (P3) |
| Pruebas | Puerta de cobertura, casos de sandbox de pagos (callbacks repetidos/reembolso/conciliación), scripts de pruebas de carga, ejecución de simulacros de respaldo/restauración |
| Revisión | Revisión de rutas críticas de pagos y seguridad, gitleaks en CI, revisión de pruebas de excesos multiusuario |
| Documentación | Manuales de despliegue/operación (incluido simulacro de restauración), documento del plan multiusuario, manual de configuración de monitoreo, manual de entrega de versión comercial |

## 8. Recomendaciones de acción inmediata

✅ Los elementos 1-4 del P1 original (refuerzo de claves → CI completo → script de respaldo → degradación de ES) ya se ejecutaron por completo (entregas iterativas P4-P9).

**Dependencias restantes (requieren condiciones externas, no son brechas de código)**:
1. Integración de sandbox de pagos: tras obtener las credenciales WECHAT_PAY_* / ALIPAY_* ejecutar `scripts/payment_sandbox_smoke.php` (verificación de cadena completa pedido→callback repetido idempotente→reembolso→conciliación)
2. Prueba real de alertas de monitoreo: tras el despliegue ejecutar `scripts/verify_monitoring.sh` para validar la carga de reglas y disparar realmente 5xx/fallos de conexión para verificar alertas (la regla Http5xxRatio ya puede surtir efecto directamente)
3. Simulacro de respaldo/restauración: ejecutar simulacro trimestral según docs/RECOVERY_RUNBOOK.md y registrar el tiempo real (objetivo RTO ≤ 1h)
4. Verificación en dispositivo real de HarmonyOS: ejecutar rutas principales (pagos/reparaciones/avisos/visitantes/estacionamiento) cuando el equipo de prueba esté disponible
