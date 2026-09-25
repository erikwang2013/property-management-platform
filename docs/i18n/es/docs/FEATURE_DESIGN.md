# Documento de Diseño de Funciones (Feature Design)

> Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

<img src="../../../images/pet_xiaozhu.svg" alt="小筑 · project mascot" width="110" align="right">

<img src="../../../images/design_function.svg" alt="Panorama de módulos funcionales" width="1000">

> English edition: `../../../images/design_function_en.svg`


## Resumen

El sistema de gestión de propiedades se divide en **panel de administración** (uso interno de la empresa de propiedades) y **portal de propietarios** (propietarios/inquilinos de la comunidad), cubriendo 15 módulos de negocio, entregados en 3 lotes.

---

## Lote 1: Negocio principal

### 1. Gestión de comunidades (Community)

**Panel de administración:**
- Lista de comunidades (búsqueda, paginación, filtro de estado)
- Crear/ver/editar/eliminar comunidad
- Información de la comunidad: nombre, dirección (provincia/ciudad/distrito), área de construcción, número de edificios, número de viviendas, desarrollador, empresa de propiedades, teléfono de contacto
- La eliminación requiere confirmación secundaria de contraseña y usa eliminación suave

**Portal de propietarios:** no requiere permisos de administración; la página de inicio muestra la información de la comunidad vinculada.

### 2. Gestión de edificios (Building)

**Panel de administración:**
- Lista de edificios filtrada por comunidad
- Crear/ver/editar/eliminar edificio
- Información del edificio: nombre, tipo (torre/placa/villa/comercial), número de pisos, número de unidades, número de ascensores, año de construcción, tipo de estructura
- Soporta ordenación

### 3. Gestión de unidades (Unit)

**Panel de administración:**
- Lista de unidades filtrada por edificio
- Crear/ver/editar/eliminar unidad
- Información de la unidad: nombre, número de viviendas por piso

### 4. Gestión de tipos de vivienda (RoomType)

**Panel de administración:**
- CRUD de lista de tipos de vivienda
- Información del tipo: nombre (tres dormitorios y dos salones), número de dormitorios/salones/baños, plano del tipo

### 5. Gestión de propiedades (Room)

**Panel de administración:**
- Vista de árbol de viviendas (comunidad→edificio→unidad→vivienda)
- Crear/ver/editar/eliminar vivienda
- Información de la vivienda: número, piso, tipo, área (interior/compartida/total), orientación, decoración, uso (residencial/comercial/oficina), estado (vacante/vendida/alquilada/autocupada)
- Vinculación/desvinculación masiva de propietarios

**Portal de propietarios:**
- Ver la lista de mis propiedades vinculadas
- Ver el detalle de la propiedad (área, orientación, tipo, información de titularidad)

### 6. Gestión de propietarios (Owner)

**Panel de administración:**
- Lista de propietarios (búsqueda, paginación, filtro de estado)
- Crear/ver/editar/eliminar propietario
- Información del propietario: nombre, teléfono (cifrado), correo (cifrado), documento de identidad (cifrado), género, fecha de nacimiento, contacto de emergencia, fecha de mudanza
- Importación masiva (Excel), habilitar/deshabilitar masivo, eliminación masiva
- Vinculación/desvinculación de propiedades

**Portal de propietarios:**
- Registro (teléfono + contraseña + código de verificación, con verificación de vinculación de propiedad)
- Inicio de sesión (teléfono + contraseña + código de verificación de clic, con protección de bloqueo de cuenta)
- Ver/modificar información personal
- Cambiar contraseña, cerrar sesión

### 7. Gestión de inquilinos (Tenant)

**Panel de administración:**
- Lista de inquilinos filtrada por propiedad/arrendador
- Crear/ver/editar/eliminar inquilino
- Información del inquilino: nombre, teléfono (cifrado), documento de identidad (cifrado), inicio/fin del contrato de arrendamiento, renta mensual, estado

### 8. Gestión de cargos (Fee)

**Tipos de cargo (panel de administración):**
- CRUD de tipos de cargo: cuota de propiedades, agua, electricidad, gas, calefacción, estacionamiento, fondo de reparación, otros
- Precio unitario, unidad de facturación (yuan/m²/mes, yuan/tonelada, yuan/kWh, etc.), período de facturación (mensual/trimestral/anual), si es obligatorio

**Gestión de facturas (panel de administración):**
- Consulta de facturas por comunidad/edificio/propiedad
- Crear/editar facturas manualmente
- Generación masiva de facturas (seleccionar comunidad + tipo de cargo + período, generar automáticamente para todas las viviendas)
- Información de la factura: tipo de cargo, monto, recargo por mora, período del cargo, fecha límite
- Estado: sin pagar/pagada parcialmente/pagada/vencida/exenta
- Notificación masiva de cobro

**Facturas (portal de propietarios):**
- Lista de mis facturas (filtro por estado: sin pagar/pagada/vencida)
- Detalle de factura
- Pago en línea (WeChat/Alipay, requiere confirmación secundaria de contraseña)
- Consulta de registros de pago
- Estadísticas de cargos (tendencia mensual/anual, proporción por categoría de cargo)

**Registros de pago (panel de administración):**
- Consulta de registros de pago
- Registro de cobro offline (efectivo/tarjeta/transferencia bancaria)

### 9. Gestión de reparaciones (Repair)

**Panel de administración:**
- Lista de reparaciones (filtro por estado/categoría)
- Ver detalle de reparación
- Asignación (asignar personal de reparación)
- Actualización del progreso de la reparación

**Portal de propietarios:**
- Lista de mis reparaciones
- Enviar reparación (seleccionar propiedad, categoría, urgencia, descripción, subir imágenes, hora de cita)
- Ver detalle y progreso de la reparación
- Cancelar reparación (solo en estado pendiente de asignación, requiere confirmación de contraseña)
- Evaluar reparación (1-5 estrellas + comentario de texto)

### 10. Avisos y notificaciones (Announcement)

**Panel de administración:**
- CRUD de lista de avisos
- Publicar avisos por comunidad
- Categorías: notificación/aviso/recordatorio/actividad
- Fijar, estado de borrador/publicado

**Portal de propietarios:**
- Ver lista de avisos publicados (filtro por categoría)
- Detalle del aviso

---

## Lote 2: Negocio auxiliar

### 11. Gestión de estacionamiento (Parking)

**Panel de administración:**
- Gestión de espacios (número, superficie/subterráneo, área, estado: libre/vendido/alquilado/en mantenimiento)
- Gestión de vehículos (matrícula cifrada, marca, color, tipo, espacio/propietario vinculado)
- Consulta de registros de estacionamiento (hora de entrada/salida, duración de estancia, cargo)

**Portal de propietarios:**
- Lista de mis vehículos
- Lista de mis espacios
- Consulta de registros de estacionamiento

### 12. Gestión de equipos (Equipment)

**Panel de administración:**
- Registro de equipos (nombre, número, categoría: ascensor/bomberos/control de acceso/vigilancia/abastecimiento y drenaje/suministro eléctrico/calefacción y ventilación)
- Información del equipo: marca, modelo, ubicación de instalación, fecha de instalación, vencimiento de garantía, vida útil de diseño
- Registros de mantenimiento: inspección diaria/mantenimiento periódico/reparación de averías/revisión general/sustitución
- Personal de mantenimiento, costo, unidad de mantenimiento, próxima fecha de mantenimiento

### 13. Quejas y sugerencias (Complaint)

**Panel de administración:**
- Lista de quejas (filtro por tipo/estado)
- Gestionar quejas (asignar gestor, completar notas de gestión)
- Registro de seguimiento (notas de seguimiento, registro de satisfacción)

**Portal de propietarios:**
- Lista de mis quejas/sugerencias
- Enviar queja/sugerencia (tipo: queja/sugerencia/elogio, categoría: servicio/entorno/seguridad/instalaciones/ruido/construcción ilegal)
- Soporta envío anónimo y carga de imágenes
- Ver progreso del tratamiento
- Evaluación de satisfacción

### 14. Gestión de visitantes (Visitor)

**Panel de administración:**
- Aprobación de reservas de visitantes
- Consulta de registros de visitantes

**Portal de propietarios:**
- Reserva de visitante (nombre del visitante, teléfono, documento de identidad, matrícula, número de acompañantes, motivo de la visita, hora estimada)
- Generación de código de paso
- Modificar/cancelar reserva

### 15. Gestión de contratos (Contract)

**Panel de administración:**
- Lista de contratos (filtro por tipo/estado)
- Tipos de contrato: contrato de propiedades/contrato de arrendamiento/contrato de mantenimiento/contrato de servicios/contrato de compra
- Información del contrato: número, partes A y B, monto, fechas de inicio y fin, fecha de firma, anexos
- Estado: borrador/en ejecución/vencido/terminado/renovado

### 16. Gestión financiera (Finance)

**Panel de administración:**
- Gestión de ingresos (cuota de propiedades/estacionamiento/renta/publicidad/fondo de reparación/otros)
- Gestión de gastos (personal/compra de equipos/mantenimiento/energía/limpieza y jardinería/oficina/impuestos/otros)
- Informes estadísticos de ingresos y gastos (mensual/trimestral/anual)

---

## Lote 3: Funciones avanzadas

### 17. Patrullaje de seguridad (Security Patrol)

**Panel de administración:**
- Gestión de rutas de patrullaje (coordenadas de ruta, puntos de control)
- Registros de patrullaje (hora de inicio/fin, duración, notas de anomalías)
- Estadísticas de tasa de finalización de patrullaje

### 18. Gestión de limpieza (Cleaning)

**Panel de administración:**
- Gestión de zonas de limpieza (ubicación, área, frecuencia: diaria/semanal/quincenal/mensual)
- Registros de limpieza (hora de limpieza, inspector, notas de inspección, imágenes del sitio)
- Estadísticas de tasa de finalización de limpieza

### 19. Gestión de jardinería (Green)

**Panel de administración:**
- Gestión de zonas verdes (ubicación, área, plantas principales)
- Registros de mantenimiento (riego/poda/fertilización/control de plagas/replantación, costo)

### 20. Actividades comunitarias (Activity)

**Panel de administración:**
- Gestión de actividades (título, contenido, categoría: deportes y cultura/festividades/beneficencia/conferencias/familiares)
- Imagen de portada, ubicación, número máximo de participantes, hora, costo
- Estado: inscripción abierta/en curso/finalizada/cancelada
- Ver lista de inscripciones

**Portal de propietarios:**
- Lista de actividades (filtro: inscripción abierta/en curso)
- Detalle de la actividad
- Inscribirse/cancelar inscripción

### 21. Gestión de energía (Energy)

**Panel de administración:**
- Gestión de medidores (electricidad/agua/gas/calefacción, número)
- Registros de lectura (lectura actual, consumo, precio unitario, costo)
- Generación automática de facturas vinculadas

### 22. Gestión de empleados (Staff)

**Panel de administración:**
- Información de empleados (nombre, teléfono cifrado, documento de identidad cifrado, puesto, departamento, fecha de ingreso)
- Departamentos: administración/atención al cliente/ingeniería/seguridad/limpieza/jardinería/finanzas
- Estado: activo/baja/licencia

---

## Visualización de panel y exportación

### Panel del panel de administración

**Panel del panel de administración:**
- Tarjetas de indicadores principales: monto total por cobrar, monto total cobrado, tasa de morosidad, tasa de ocupación
- Gráfico de líneas de tendencia de cargos (mensual/trimestral)
- Gráfico circular por categoría de cargo
- Estadísticas de reparaciones (por categoría, por estado)
- Estadísticas de quejas
- Logs de operaciones recientes

**Inicio del portal de propietarios:**
- Número de mis propiedades, monto pendiente de pago, número de reparaciones en curso, últimos avisos

### Exportación Excel

- Exportación de lista de propietarios
- Exportación de informes de facturas
- Exportación de registros de pago
- Exportación de informes financieros
- Enmascaramiento automático de datos sensibles al exportar

### Exportación PDF

- Exportación de visualización del panel
- Informes financieros PDF (copyright en el encabezado + marca de agua de copyright irremovible en el pie)
- Diseño A4 horizontal

---

## Características transversales

| Característica | Descripción |
|------|------|
| Protección de ID | Todos los ID de interfaces se codifican con hashids para la transmisión |
| Cifrado de datos | Campos sensibles (teléfono/correo/documento de identidad) con AES-256-CBC en la capa API, encryptable en la capa de BD |
| Auditoría de operaciones | Todas las operaciones POST/PUT/DELETE de administradores se registran automáticamente, incluida la detección automática del origen |
| Control de permisos | RBAC con granularidad method.path, superadministrador con identificador * |
| Protección de límite de velocidad | Ventana deslizante Redis, login 10 veces/minuto, registro 5 veces/minuto |
| Código de verificación | Código de verificación chino de clic, obligatorio en login/registro |
| Eliminación suave | Propietarios, comunidades, propiedades y avisos soportan eliminación suave |
| Internacionalización | Bilingüe chino/inglés, PHP symfony/translation + Flutter GetX Translations, chino por defecto, inglés de respaldo |
| Documentación de API | Generada automáticamente por `hg/apidoc`; 57 de 58 controladores anotados en 10 grupos (Base/Docs/Install sin agrupar), `/apidoc/config` proporciona la API de configuración |
| Pruebas | Proceso TDD, 133 pruebas/465 aserciones, service 100% aprobado, flutter analyze con cero problemas |
| Flutter Web | 13 páginas (login/inicio/cargos/reparaciones/centro personal, etc.), estilo escritorio PC, gestión de estado GetX |
| HarmonyOS | Esqueleto completo del proyecto, capa de servicios ArkTS + autenticación + login/inicio, @ohos.net.http |

## Funciones extendidas (Lote 4)

### Centro de notificaciones de mensajes
- Plantillas de notificación configurables (push de App/SMS/correo)
- Recordatorios de facturas, progreso de reparaciones, avisos publicados con notificación automática
- Lista de mensajes del portal de propietarios + gestión de leídos

### Motor de flujo de aprobación
- Tipos y pasos de aprobación configurables (supervisor→gerente→director)
- Asignación de reparaciones/aprobación de visitantes/aprobación de contratos por procesos estandarizados
- Registros de aprobación trazables

### Integración de pagos
- Gestión de órdenes de pago WeChat/Alipay
- Procesamiento de callbacks de pago, reembolsos, estadísticas de conciliación
- Actualización automática de facturas vinculadas

### Votaciones de propietarios
- Votación normal + votación de asamblea de propietarios (ponderada por área)
- Gestión de opciones, registros de votación, recuento automático
- Estadísticas de participación

### Escalado automático SLA de reparaciones
- Configuración de plazos de respuesta/solución por categoría + urgencia
- Escalado automático al rol superior al superar el plazo
- Registro automático de multas por retraso

### Cobros inteligentes
- Configuración de estrategias de cobro escalonadas (días de morosidad → acción)
- Coincidencia automática de facturas vencidas para ejecutar el cobro (App/SMS/teléfono/visita)
- Cálculo automático de recargos por mora

### Inspección móvil
- Asignación de tareas de inspección (ruta GPS + puntos de control)
- Registro móvil (ubicación + fotos + marcado de anomalías)
- Estadísticas de tasa de finalización de inspección

### Tienda comunitaria
- Gestión de categorías de productos/publicación/retirada
- Navegación de propietarios + pedidos + seguimiento de órdenes
- Gestión de envíos/reembolsos

### Reconocimiento facial
- Registro facial de propietarios (integración con servicio de reconocimiento de terceros)
- Revisión y autenticación en el panel de administración
- Asociación con control de acceso

### Gestión de grupos multicomunidad
- Asociación muchos a muchos grupo→comunidad
- Resumen de datos entre comunidades (vista unificada de propiedades/propietarios/cobros)

### Q&A inteligente
- Gestión de base de conocimiento (categorías/artículos/palabras clave)
- Coincidencia automática de preguntas de propietarios
- Historial de conversaciones + estadísticas de tasa de resolución

### Pantalla de datos
- Visualización en pantalla completa de datos de propiedades en tiempo real
- Cuatro paneles: cobros/reparaciones/equipos/energía
- Refresco automático con rotación
