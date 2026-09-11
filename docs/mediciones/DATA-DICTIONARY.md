# Diccionario de Datos — SGROAS

## Mediciones

### Rendimiento (k6)

| Variable | Tipo | Unidad | Rango esperado | Significado |
|---|---|---|---|---|
| `http_req_duration` | float | ms | 10–500 | Tiempo de respuesta por peticion |
| `http_req_failed` | float | % | 0–1 | Porcentaje de peticiones fallidas |
| `http_reqs` | int | count | — | Total de peticiones realizadas |
| `iterations` | int | count | — | Iteraciones completadas |
| `vus` | int | count | 0–50 | Usuarios virtuales concurrentes |
| `data_received` | int | bytes | — | Datos recibidos |
| `data_sent` | int | bytes | — | Datos enviados |
| `p50` | float | ms | 10–200 | Percentil 50 del tiempo de respuesta |
| `p90` | float | ms | 10–350 | Percentil 90 del tiempo de respuesta |
| `p95` | float | ms | 10–500 | Percentil 95 del tiempo de respuesta |
| `p99` | float | ms | 10–800 | Percentil 99 del tiempo de respuesta |
| `throughput` | float | req/s | 10–500 | Peticiones por segundo |

### Seguridad (OWASP)

| Variable | Tipo | Unidad | Rango esperado | Significado |
|---|---|---|---|---|
| `http_status` | int | HTTP code | 200–599 | Codigo de respuesta HTTP |
| `response_time` | float | ms | 10–5000 | Tiempo de respuesta del endpoint |
| `tls_version` | string | — | TLSv1.2/TLSv1.3 | Version de TLS negociada |
| `cipher_suite` | string | — | — | Suite de cifrado negociada |

### Usabilidad (SUS)

| Variable | Tipo | Unidad | Rango esperado | Significado |
|---|---|---|---|---|
| `participante` | string | — | P01–P10 | Codigo anonimizado del participante |
| `item_01` | int | Likert | 1–5 | Respuesta a pregunta 1 SUS |
| `item_02` | int | Likert | 1–5 | Respuesta a pregunta 2 SUS |
| `item_03` | int | Likert | 1–5 | Respuesta a pregunta 3 SUS |
| `item_04` | int | Likert | 1–5 | Respuesta a pregunta 4 SUS |
| `item_05` | int | Likert | 1–5 | Respuesta a pregunta 5 SUS |
| `item_06` | int | Likert | 1–5 | Respuesta a pregunta 6 SUS |
| `item_07` | int | Likert | 1–5 | Respuesta a pregunta 7 SUS |
| `item_08` | int | Likert | 1–5 | Respuesta a pregunta 8 SUS |
| `item_09` | int | Likert | 1–5 | Respuesta a pregunta 9 SUS |
| `item_10` | int | Likert | 1–5 | Respuesta a pregunta 10 SUS |
| `score` | float | 0–100 | 0–100 | Puntuacion SUS calculada |

### Cobertura (JaCoCo)

| Variable | Tipo | Unidad | Rango esperado | Significado |
|---|---|---|---|---|
| `line_coverage` | float | % | 0–100 | Porcentaje de lineas cubiertas |
| `branch_coverage` | float | % | 0–100 | Porcentaje de ramas cubiertas |
| `complexity_coverage` | float | % | 0–100 | Complejidad ciclomatica cubierta |
| `method_coverage` | float | % | 0–100 | Porcentaje de metodos cubiertos |
| `class_coverage` | float | % | 0–100 | Porcentaje de clases cubiertas |

### Accesibilidad (Lighthouse)

| Variable | Tipo | Unidad | Rango esperado | Significado |
|---|---|---|---|---|
| `performance` | float | score | 0–100 | Puntaje de rendimiento |
| `accessibility` | float | score | 0–100 | Puntaje de accesibilidad |
| `best_practices` | float | score | 0–100 | Puntaje de buenas practicas |
| `seo` | float | score | 0–100 | Puntaje de SEO |
| `first_contentful_paint` | float | ms | 500–5000 | Primera pintura de contenido |
| `largest_contentful_paint` | float | ms | 1000–8000 | Mayor pintura de contenido |
| `cumulative_layout_shift` | float | score | 0–1 | Cambio de layout acumulado |
| `total_blocking_time` | float | ms | 0–1000 | Tiempo de bloqueo total |
# Diccionario de Datos — SGROAS

## 1. Variables de Configuracion

| Variable | Tipo | Unidad | Rango / Valores | Descripcion |
|---|---|---|---|---|
| `APP_JWT_SECRET` | string | — | min 32 chars | Clave secreta para firmar JWT (HS256) |
| `APP_JWT_EXPIRATION_MS` | long | ms | 1–604800000 | Tiempo de vida del access token |
| `APP_JWT_REFRESH_EXPIRATION_MS` | long | ms | 1–2592000000 | Tiempo de vida del refresh token |
| `SPRING_DATASOURCE_URL` | string | — | `jdbc:postgresql://host:5432/db` | URL de conexion a PostgreSQL |
| `SPRING_DATASOURCE_USERNAME` | string | — | — | Usuario de base de datos |
| `SPRING_DATASOURCE_PASSWORD` | string | — | — | Contrasena de base de datos |
| `SPRING_DATA_REDIS_HOST` | string | — | — | Host de Redis |
| `SPRING_DATA_REDIS_PORT` | int | — | 1–65535 | Puerto de Redis |
| `app.cache.default-ttl` | long | s | 1–86400 | TTL por defecto del cache Redis |

## 2. Tablas de Base de Datos

### 2.1. `usuarios`

| Columna | Tipo SQL | Tipo Java | Longitud | Nulo | Unico | Valores | Descripcion |
|---|---|---|---|---|---|---|---|
| `id` | BIGSERIAL | Long | — | NO | SI | — | Identificador unico |
| `nombre` | VARCHAR(100) | String | 100 | NO | — | — | Nombre completo del usuario |
| `email` | VARCHAR(255) | String | 255 | NO | SI | — | Correo electronico (login) |
| `password_hash` | VARCHAR(255) | String | 255 | NO | — | — | Hash BCrypt de la contrasena |
| `rol` | VARCHAR(30) | Rol (enum) | 30 | NO | — | ROLE_ADMIN, ROLE_COORDINADOR, ROLE_SEGURIDAD | Rol de autorizacion |
| `activo` | BOOLEAN | Boolean | — | NO | — | true/false | Eliminacion logica |
| `creado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de creacion |
| `actualizado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de ultima modificacion |

### 2.2. `conductores`

| Columna | Tipo SQL | Tipo Java | Longitud | Nulo | Unico | Valores | Descripcion |
|---|---|---|---|---|---|---|---|
| `id` | BIGSERIAL | Long | — | NO | SI | — | Identificador unico |
| `nombres` | VARCHAR(100) | String | 100 | NO | — | — | Nombres del conductor |
| `apellidos` | VARCHAR(100) | String | 100 | NO | — | — | Apellidos del conductor |
| `cedula` | VARCHAR(10) | String | 10 | NO | SI | — | Cedula de identidad (10 digitos) |
| `numero_licencia` | VARCHAR(30) | String | 30 | NO | SI | — | Numero de licencia de conducir |
| `tipo_licencia` | VARCHAR(10) | String | 10 | NO | — | A, B, C, D, E, F, G | Tipo de licencia |
| `fecha_vencimiento_licencia` | DATE | LocalDate | — | NO | — | >= 2020-01-01 | Fecha de vencimiento de licencia |
| `telefono` | VARCHAR(20) | String | 20 | — | — | — | Numero de telefono |
| `email` | VARCHAR(255) | String | 255 | — | — | — | Correo electronico |
| `estado` | VARCHAR(20) | EstadoConductor (enum) | 20 | NO | — | ACTIVO, INACTIVO, SUSPENDIDO | Estado del conductor |
| `activo` | BOOLEAN | Boolean | — | NO | — | true/false | Eliminacion logica |
| `creado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de creacion |
| `actualizado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de ultima modificacion |

### 2.3. `vehiculos`

| Columna | Tipo SQL | Tipo Java | Longitud | Nulo | Unico | Valores | Descripcion |
|---|---|---|---|---|---|---|---|---|
| `id` | BIGSERIAL | Long | — | NO | SI | — | Identificador unico |
| `placa` | VARCHAR(20) | String | 20 | NO | SI | — | Placa del vehiculo |
| `marca` | VARCHAR(50) | String | 50 | NO | — | — | Marca del vehiculo |
| `modelo` | VARCHAR(50) | String | 50 | NO | — | — | Modelo del vehiculo |
| `anio` | INTEGER | Integer | — | NO | — | 1990-2030 | Anio de fabricacion |
| `capacidad_pasajeros` | INTEGER | Integer | — | NO | — | >= 1 | Capacidad de pasajeros |
| `numero_motor` | VARCHAR(50) | String | 50 | — | — | — | Numero de motor |
| `numero_chasis` | VARCHAR(50) | String | 50 | — | — | — | Numero de chasis |
| `color` | VARCHAR(30) | String | 30 | — | — | — | Color del vehiculo |
| `estado` | VARCHAR(25) | EstadoVehiculo (enum) | 25 | NO | — | ACTIVO, EN_MANTENIMIENTO, FUERA_DE_SERVICIO | Estado del vehiculo |
| `activo` | BOOLEAN | Boolean | — | NO | — | true/false | Eliminacion logica |
| `creado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de creacion |
| `actualizado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de ultima modificacion |

### 2.4. `rutas`

| Columna | Tipo SQL | Tipo Java | Longitud | Nulo | Unico | Valores | Descripcion |
|---|---|---|---|---|---|---|---|---|
| `id` | BIGSERIAL | Long | — | NO | SI | — | Identificador unico |
| `codigo` | VARCHAR(20) | String | 20 | NO | SI | — | Codigo unico de ruta |
| `nombre` | VARCHAR(100) | String | 100 | NO | — | — | Nombre de la ruta |
| `origen` | VARCHAR(150) | String | 150 | NO | — | — | Lugar de origen |
| `destino` | VARCHAR(150) | String | 150 | NO | — | — | Lugar de destino |
| `distancia_km` | DOUBLE PRECISION | Double | — | NO | — | >= 0 | Distancia en kilometros |
| `duracion_estimada_min` | INTEGER | Integer | — | NO | — | >= 1 | Duracion estimada en minutos |
| `estado` | VARCHAR(10) | EstadoRuta (enum) | 10 | NO | — | ACTIVA, INACTIVA | Estado de la ruta |
| `activo` | BOOLEAN | Boolean | — | NO | — | true/false | Eliminacion logica |
| `creado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de creacion |
| `actualizado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de ultima modificacion |

### 2.5. `asignacion_rutas`

| Columna | Tipo SQL | Tipo Java | Longitud | Nulo | Unico | Valores | Descripcion |
|---|---|---|---|---|---|---|---|---|
| `id` | BIGSERIAL | Long | — | NO | SI | — | Identificador unico |
| `conductor_id` | BIGINT | Long (FK) | — | NO | — | — | FK a conductores |
| `vehiculo_id` | BIGINT | Long (FK) | — | NO | — | — | FK a vehiculos |
| `ruta_id` | BIGINT | Long (FK) | — | NO | — | — | FK a rutas |
| `fecha_asignacion` | DATE | LocalDate | — | NO | — | — | Fecha de asignacion |
| `fecha_inicio` | DATE | LocalDate | — | NO | — | — | Fecha de inicio |
| `fecha_fin` | DATE | LocalDate | — | — | — | — | Fecha de fin |
| `estado` | VARCHAR(15) | EstadoAsignacion (enum) | 15 | NO | — | ACTIVA, COMPLETADA, CANCELADA | Estado de la asignacion |
| `activo` | BOOLEAN | Boolean | — | NO | — | true/false | Eliminacion logica |
| `creado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de creacion |
| `actualizado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de ultima modificacion |

### 2.6. `incidentes`

| Columna | Tipo SQL | Tipo Java | Longitud | Nulo | Unico | Valores | Descripcion |
|---|---|---|---|---|---|---|---|---|
| `id` | BIGSERIAL | Long | — | NO | SI | — | Identificador unico |
| `asignacion_id` | BIGINT | Long (FK) | — | NO | — | — | FK a asignacion_rutas |
| `reportado_por` | VARCHAR(100) | String | 100 | NO | — | — | Persona que reporta |
| `tipo` | VARCHAR(25) | TipoIncidente (enum) | 25 | NO | — | ACCIDENTE, AVERIA_MECANICA, INFRACCION, QUEJA, OTRO | Tipo de incidente |
| `descripcion` | TEXT | String | — | NO | — | — | Descripcion detallada |
| `fecha_incidente` | TIMESTAMPTZ | LocalDateTime | — | NO | — | — | Fecha y hora del incidente |
| `ubicacion` | VARCHAR(255) | String | 255 | — | — | — | Ubicacion del incidente |
| `gravedad` | VARCHAR(10) | GravedadIncidente (enum) | 10 | NO | — | BAJA, MEDIA, ALTA, CRITICA | Nivel de gravedad |
| `estado` | VARCHAR(20) | EstadoIncidente (enum) | 20 | NO | — | REPORTADO, EN_INVESTIGACION, RESUELTO, CERRADO | Estado del incidente |
| `activo` | BOOLEAN | Boolean | — | NO | — | true/false | Eliminacion logica |
| `creado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de creacion |
| `actualizado_en` | TIMESTAMPTZ | Instant | — | NO | — | — | Timestamp de ultima modificacion |

## 3. DTOs (API REST)

### 3.1. `LoginRequest`

| Campo | Tipo | Requerido | Descripcion |
|---|---|---|---|
| `email` | String | SI | Email del usuario |
| `password` | String | SI | Contrasena del usuario |

### 3.2. `RegisterRequest`

| Campo | Tipo | Requerido | Descripcion |
|---|---|---|---|
| `nombre` | String | SI | Nombre del nuevo usuario |
| `email` | String | SI | Email del nuevo usuario |
| `password` | String | SI | Contrasena del nuevo usuario |
| `rol` | String | NO | Rol (default: ROLE_COORDINADOR) |

### 3.3. `SesionResponse` (cuerpo de login/refresh/verify-email/me)

Los JWT ya no viajan en el cuerpo: van solo en cookies HttpOnly
`access_token` (Path `/`) y `refresh_token` (Path `/api/auth`),
ambas con `Secure` (prod) + `SameSite=Strict`.

| Campo | Tipo | Descripcion |
|---|---|---|
| `nombre` | String | Nombre del usuario autenticado |
| `email` | String | Email del usuario autenticado |
| `rol` | String | Rol del usuario (ROLE_ADMIN, etc.) |
| `expiresIn` | long | Tiempo de vida del access token en ms |

> `AuthResponse` (con `accessToken`/`refreshToken`/`tokenType`) sigue
> existiendo como objeto interno del servicio, pero no se expone por HTTP.

### 3.4. `RefreshTokenRequest`

| Campo | Tipo | Requerido | Descripcion |
|---|---|---|---|
| `refreshToken` | String | SI | UUID del refresh token |

### 3.5. `ConductorRequest`

| Campo | Tipo | Requerido | Descripcion |
|---|---|---|---|
| `nombres` | String | SI | Nombres del conductor |
| `apellidos` | String | SI | Apellidos del conductor |
| `cedula` | String | SI | Cedula (10 digitos) |
| `numeroLicencia` | String | SI | Numero de licencia |
| `tipoLicencia` | String | SI | Tipo de licencia |
| `fechaVencimientoLicencia` | LocalDate | SI | Fecha vencimiento |
| `telefono` | String | NO | Telefono |
| `email` | String | NO | Email |
| `estado` | String | NO | Estado (default: ACTIVO) |

### 3.6. `ConductorResponse`

| Campo | Tipo | Descripcion |
|---|---|---|
| `id` | Long | ID del conductor |
| `nombres` | String | Nombres |
| `apellidos` | String | Apellidos |
| `cedula` | String | Cedula |
| `numeroLicencia` | String | Numero de licencia |
| `tipoLicencia` | String | Tipo de licencia |
| `fechaVencimientoLicencia` | LocalDate | Fecha vencimiento |
| `telefono` | String | Telefono |
| `email` | String | Email |
| `estado` | String | Estado |
| `licenciaPorVencer` | boolean | true si faltan <= 30 dias para vencer |

### 3.7. `ErrorResponse` (ProblemDetails RFC 7807)

| Campo | Tipo | Descripcion |
|---|---|---|
| `type` | URI | URL del tipo de error |
| `title` | String | Titulo del error |
| `status` | int | Codigo HTTP |
| `detail` | String | Descripcion detallada |
| `instance` | URI | Path del endpoint |
| `errors` | Map (opcional) | Errores de validacion por campo |

## 4. Claims del JWT

| Claim | Tipo | Descripcion | Valor ejemplo |
|---|---|---|---|
| `jti` | UUID | Identificador unico del token | `4006d81d-e963-4f70-b2d3-b0ab4974267b` |
| `iss` | URI | Emisor del token | `https://sgroas.uteq.edu.ec` |
| `sub` | String | Sujeto (email del usuario) | `admin@sgroas.com` |
| `aud` | String[] | Audiencia | `["sgroas-frontend"]` |
| `iat` | long | Emitido en (epoch ms) | `1785388105` |
| `nbf` | long | No antes de (epoch ms) | `1785388105` |
| `exp` | long | Expira en (epoch ms) | `1785391705` |

## 5. Metricas de Rendimiento (k6)

| Metrica | Unidad | Descripcion |
|---|---|---|
| `http_req_duration` | ms | Tiempo total de respuesta HTTP |
| `http_req_waiting` | ms | Tiempo de espera (TTFB) |
| `http_req_blocked` | ms | Tiempo en cola de conexion |
| `http_req_connecting` | ms | Tiempo de establecimiento TCP |
| `http_req_tls_handshaking` | ms | Tiempo de handshake TLS |
| `http_req_sending` | ms | Tiempo de envio de request |
| `http_req_receiving` | ms | Tiempo de recepcion de response |
| `http_req_failed` | ratio | Tasa de errores (0 = 0%) |
| `iterations` | count | Numero de iteraciones completadas |
| `vus` | count | Numero de usuarios virtuales concurrentes |
| `vus_max` | count | Maximo de usuarios virtuales |

## 6. Metricas de Cobertura (JaCoCo)

| Contador | Descripcion | Unidad |
|---|---|---|
| `INSTRUCTION` | Instrucciones de bytecode cubiertas | count / ratio |
| `LINE` | Lineas de codigo cubiertas | count / ratio |
| `BRANCH` | Ramas condicionales cubiertas | count / ratio |
| `COMPLEXITY` | Complejidad ciclomatica cubierta | count / ratio |
| `METHOD` | Metodos cubiertos | count / ratio |
| `CLASS` | Clases cubiertas | count / ratio |

## 7. API REST (Endpoints)

| Metodo | Path | Autenticacion | Descripcion |
|---|---|---|---|
| POST | `/api/auth/login` | No | Inicio de sesion |
| POST | `/api/auth/register` | No | Registro de usuario |
| POST | `/api/auth/refresh` | No | Renovar access token |
| POST | `/api/auth/logout` | Si | Cerrar sesion |
| GET | `/api/conductores` | ADMIN, COORDINADOR | Listar conductores |
| GET | `/api/conductores/{id}` | ADMIN, COORDINADOR | Obtener conductor por ID |
| POST | `/api/conductores` | ADMIN, COORDINADOR | Crear conductor |
| PUT | `/api/conductores/{id}` | ADMIN, COORDINADOR | Actualizar conductor |
| DELETE | `/api/conductores/{id}` | ADMIN, COORDINADOR | Eliminar conductor (logico) |
| GET | `/api/vehiculos` | ADMIN, COORDINADOR | Listar vehiculos |
| GET | `/api/vehiculos/{id}` | ADMIN, COORDINADOR | Obtener vehiculo por ID |
| POST | `/api/vehiculos` | ADMIN, COORDINADOR | Crear vehiculo |
| PUT | `/api/vehiculos/{id}` | ADMIN, COORDINADOR | Actualizar vehiculo |
| DELETE | `/api/vehiculos/{id}` | ADMIN, COORDINADOR | Eliminar vehiculo (logico) |
| GET | `/api/rutas` | ADMIN, COORDINADOR | Listar rutas |
| GET | `/api/rutas/{id}` | ADMIN, COORDINADOR | Obtener ruta por ID |
| POST | `/api/rutas` | ADMIN, COORDINADOR | Crear ruta |
| PUT | `/api/rutas/{id}` | ADMIN, COORDINADOR | Actualizar ruta |
| DELETE | `/api/rutas/{id}` | ADMIN, COORDINADOR | Eliminar ruta (logico) |
| GET | `/api/asignaciones` | ADMIN, COORDINADOR | Listar asignaciones |
| GET | `/api/asignaciones/{id}` | ADMIN, COORDINADOR | Obtener asignacion por ID |
| POST | `/api/asignaciones` | ADMIN, COORDINADOR | Crear asignacion |
| PUT | `/api/asignaciones/{id}` | ADMIN, COORDINADOR | Actualizar asignacion |
| DELETE | `/api/asignaciones/{id}` | ADMIN, COORDINADOR | Eliminar asignacion (logico) |
| GET | `/api/incidentes` | ADMIN, COORDINADOR, SEGURIDAD | Listar incidentes |
| GET | `/api/incidentes/{id}` | ADMIN, COORDINADOR, SEGURIDAD | Obtener incidente por ID |
| POST | `/api/incidentes` | ADMIN, COORDINADOR, SEGURIDAD | Crear incidente |
| PUT | `/api/incidentes/{id}` | ADMIN, COORDINADOR, SEGURIDAD | Actualizar incidente |
| DELETE | `/api/incidentes/{id}` | ADMIN, COORDINADOR, SEGURIDAD | Eliminar incidente (logico) |
| GET | `/api/docs/swagger-ui.html` | No | Documentacion OpenAPI 3.0 |

## 8. Estadi­sticos del analisis (k6 / SUS)

| Metrica | Tipo | Unidad | Descripcion |
|---|---|---|---|
| `media` | float | ms / puntos SUS | Media aritmetica |
| `desviacion_tipica` | float | ms / puntos SUS | DT muestral (n-1) |
| `error_estandar` | float | ms / puntos SUS | SE = s / sqrt(n) |
| `ic95_inf` / `ic95_sup` | float | ms / puntos SUS | Limites del IC 95% (t de Student) |
| `p95` | float | ms | Percentil 95 de http_req_duration |
| `error_rate` | ratio | 0-1 | http_req_failed (0 = sin errores) |
| `t_critico` | float | — | Valor critico t para gl y alfa=0.05 |
| `d_cliff` | float | [-1, 1] | Tamano del efecto (d de Cliff) |

## 9. Metricas de usabilidad (SUS)

| Variable | Tipo | Rango | Descripcion |
|---|---|---|---|
| `codigo` | string | P01..P10 | Identificador anonimizado del participante |
| `q1..q10` | int | 1-5 | Respuestas Likert del SUS (Brooke, 1996) |
| `sus_score` | float | 0-100 | Puntuacion SUS = (suma contribuciones) * 2.5 |
| `sexo` / `edad` | string / int | — | Demografia (sin datos identificables) |
| `experiencia_web` | string | Baja/Media/Alta | Autopercepcion de experiencia |
| `consentimiento` | string | Si | Confirmacion de consentimiento informado |

## 10. Metricas de calidad web (Lighthouse)

| Categoria | Significado | Umbral |
|---|---|---|
| `performance` | Rendimiento de carga | >= 80 |
| `accessibility` | Accesibilidad (axe) | >= 90 |
| `best-practices` | Practicas recomendadas | >= 90 |
| `seo` | Optimizacion para buscadores | >= 90 |

## 11. Seguridad (ZAP)

| Variable | Descripcion |
|---|---|
| `alert_count` | Numero de alertas por nivel (info, low, medium, high) |
| `fail_count` | Numero de reglas fallidas en el baseline |
| `pass_count` | Numero de reglas superadas |
| `warn_count` | Numero de advertencias |
| `scan_date` | Fecha del escaneo (ISO 8601) |
