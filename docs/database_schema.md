# Esquema de Base de Datos - Sistema de Logging PL/SQL

Este documento describe el esquema completo del sistema de logging, incluyendo tablas, índices, vistas y paquetes.

## Variables de Configuración

El sistema utiliza las siguientes variables DEFINE para personalización:

```sql
DEFINE NOMBRE_TABLA_LOG = logs_reg_logger           -- Tabla principal de logs
DEFINE NOMBRE_PAQUETE = zpkg_logger_system          -- Nombre del paquete
DEFINE NOMBRE_TABLA_CFG = cfg_log_reg_logger_silence -- Tabla de configuración
```

## Tablas

### Tabla Principal de Logs: `&NOMBRE_TABLA_LOG`

**Propósito**: Almacena todos los registros de logging del sistema.

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `execution_id` | VARCHAR2(100) | Identificador único de la ejecución (GUID) |
| `ancestor_execution_id` | VARCHAR2(100) | ID de la ejecución padre (trazabilidad) |
| `session_id` | VARCHAR2(100) | ID de la sesión de base de datos |
| `user_name` | VARCHAR2(100) | Usuario que ejecuta el código |
| `module_name` | VARCHAR2(100) | Nombre del módulo/procedimiento |
| `log_timestamp` | TIMESTAMP | Marca de tiempo del log (DEFAULT SYSTIMESTAMP) |
| `insertion_type` | VARCHAR2(20) | Nivel del log (DEBUG, INFO, WARN, ERROR) |
| `log_message` | VARCHAR2(4000) | Mensaje del log |
| `error_code` | VARCHAR2(50) | Código de error (solo para ERROR) |
| `error_message` | VARCHAR2(4000) | Mensaje de error (solo para ERROR) |

### Tabla de Configuración: `&NOMBRE_TABLA_CFG`

**Propósito**: Controla qué logs se silencian por módulo y nivel en AMBAS implementaciones (Database y Queue).

| Columna | Tipo | Descripción |
|---------|------|-------------|
| `module_name` | VARCHAR2(100) NOT NULL | Nombre del módulo a configurar |
| `insertion_type` | NUMBER | Nivel numérico (1=DEBUG, 2=INFO, 3=WARN, 4=ERROR). NULL = silenciar todo |
| `module_name_upper` | VARCHAR2(100) VIRTUAL | Versión en mayúsculas del nombre (columna generada) |

**Lógica de silenciamiento**:
- Si `insertion_type` es NULL: Se silencia todo el módulo
- Si `insertion_type` tiene valor: Se silencian logs de ese nivel y menores
- **Aplica tanto a Database como a Queue**: Logs silenciados no se insertan en BD ni se envían a cola

## Índices

### Índice Único: `uq_upper_&NOMBRE_TABLA_CFG`

```sql
CREATE UNIQUE INDEX uq_upper_&NOMBRE_TABLA_CFG 
ON &NOMBRE_TABLA_CFG (module_name_upper, insertion_type);
```

**Propósito**: Garantiza unicidad de configuración por módulo y nivel, insensible a mayúsculas.

## Vistas

### Vista con Tiempo Transcurrido: `vw_&NOMBRE_TABLA_LOG._elapsed`

**Propósito**: Muestra logs con el tiempo transcurrido desde el log anterior en la misma ejecución.

**Características**:
- Calcula `elapsed_seconds_since_prev` usando funciones de ventana
- Particionado por `execution_id` y `session_id`
- Ordenado por `log_timestamp`

### Vista Ordenada: `vw_&NOMBRE_TABLA_LOG._ordered`

**Propósito**: Presenta los logs ordenados cronológicamente por ejecución.

**Ordenamiento**:
1. `execution_id`
2. `session_id`
3. `log_timestamp`
4. `insertion_type`

## Paquete PL/SQL: `&NOMBRE_PAQUETE`

### Especificación del Paquete

```sql
PACKAGE &NOMBRE_PAQUETE AS
    -- Gestión de ejecuciones
    FUNCTION start_execution(p_module_name VARCHAR2, p_ancestor_execution_id VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;
    PROCEDURE end_execution;
    
    -- Funciones de contexto
    FUNCTION get_ancestor_execution RETURN VARCHAR2;
    FUNCTION get_parent_execution_id RETURN VARCHAR2;
    
    -- Procedimientos de logging
    PROCEDURE log_debug(p_log_message VARCHAR2);
    PROCEDURE log_info(p_log_message VARCHAR2);
    PROCEDURE log_warn(p_log_message VARCHAR2);
    PROCEDURE log_error(p_error_code VARCHAR2, p_error_message VARCHAR2);
END;
```

### Funciones Internas del Paquete

| Función | Propósito |
|---------|-----------|
| `numero_a_nivel()` | Convierte números (1-4) a texto (DEBUG-ERROR) |
| `is_silenced()` | Verifica si un log debe silenciarse según configuración |
| `insert_log()` | Procedimiento centralizado para insertar logs |

### Gestión de Contexto

El paquete utiliza `DBMS_APPLICATION_INFO` para mantener el contexto:

- **CLIENT_INFO**: Almacena el `execution_id` actual
- **MODULE**: Almacena el nombre del módulo
- **ACTION**: Almacena el `ancestor_execution_id`

### Mapeo de Niveles

| Número | Texto | Uso |
|--------|-------|-----|
| 1 | DEBUG | Información detallada para depuración |
| 2 | INFO | Información general del flujo |
| 3 | WARN | Advertencias |
| 4 | ERROR | Errores |

## Transacciones Autónomas

El procedimiento `insert_log` utiliza `PRAGMA AUTONOMOUS_TRANSACTION` para garantizar que:
- Los logs se persistan independientemente de la transacción principal
- Los rollbacks no afecten los registros de logging
- No se bloqueen las transacciones principales por el logging

## Casos de Uso

### Trazabilidad de Ejecuciones Anidadas

**Diseño Principal**: El sistema está específicamente diseñado para manejar ejecuciones anidadas con trazabilidad completa padre-hijo.

#### Estrategia de Anidamiento

**1. Ejecución Manual del Ancestro:**
```sql
-- Casos donde la detección automática NO funciona:
-- ✓ Correlation IDs de APIs externas
-- ✓ Job IDs de schedulers externos (DBMS_SCHEDULER, Cron)
-- ✓ Request IDs de load balancers
-- ✓ Trace IDs de sistemas de observabilidad
-- ✓ Message IDs de colas de mensajes
-- ✓ Session IDs de aplicaciones web

v_execution_id := &NOMBRE_PAQUETE..start_execution('MODULO_PADRE', p_external_id);
```

**2. Ejecución Automática de Hijos:**
```sql
-- Hijo detecta automáticamente el padre como ancestro
v_child_id := &NOMBRE_PAQUETE..start_execution('MODULO_HIJO');
```

**3. Cadena de Trazabilidad:**
- `execution_id`: Identificador único de la ejecución actual (GUID)
- `ancestor_execution_id`: Referencia al padre/ancestro
- Permite construir árboles completos de ejecución

#### Implementación Técnica

**Contexto de Sesión (DBMS_APPLICATION_INFO):**
- `CLIENT_INFO`: Almacena `execution_id` actual
- `MODULE`: Nombre del módulo en ejecución  
- `ACTION`: Almacena `ancestor_execution_id`

**Lógica de Detección Automática:**
```sql
-- Si no se proporciona ancestro manual
IF p_ancestor_execution_id IS NOT NULL THEN
    -- Usar ancestro manual
    v_ancestor_execution_id := p_ancestor_execution_id;
ELSE
    -- Detectar automáticamente del contexto
    v_ancestor_execution_id := get_parent_execution_id;
    IF v_ancestor_execution_id IS NOT NULL AND v_ancestor_execution_id <> v_execution_id THEN
        -- Usar como ancestro
    ELSE
        -- No hay ancestro
        v_ancestor_execution_id := NULL;
    END IF;
END IF;
```

#### Casos de Uso Prácticos

**Escenario 1: Procedimiento Principal → Sub-procedimientos**
```sql
-- NIVEL 1: Procedimiento principal
v_main_id := &NOMBRE_PAQUETE..start_execution('PROC_PRINCIPAL');

-- NIVEL 2: Sub-procedimientos (detectan automáticamente el padre)
v_sub1_id := &NOMBRE_PAQUETE..start_execution('SUB_PROC_1');
&NOMBRE_PAQUETE..log_info('Procesando datos...');
&NOMBRE_PAQUETE..end_execution;

v_sub2_id := &NOMBRE_PAQUETE..start_execution('SUB_PROC_2'); 
&NOMBRE_PAQUETE..log_info('Validando resultados...');
&NOMBRE_PAQUETE..end_execution;

&NOMBRE_PAQUETE..end_execution; -- Fin principal
```

**Escenario 2: Integración con Sistemas Externos**
```sql
-- NIVEL 1: API con correlation ID externo
v_api_id := &NOMBRE_PAQUETE..start_execution('API_HANDLER', p_correlation_id_from_header);

-- NIVEL 2: Tareas que no pueden detectar el correlation ID automáticamente
v_task1_id := &NOMBRE_PAQUETE..start_execution('BUSINESS_LOGIC'); -- Hereda p_correlation_id_from_header
v_task2_id := &NOMBRE_PAQUETE..start_execution('DATA_ACCESS');    -- Hereda p_correlation_id_from_header
```

**Escenario 3: DBMS_SCHEDULER Jobs**
```sql
-- NIVEL 1: Job desde scheduler (ID externo)
SELECT job_name INTO v_job_name FROM user_scheduler_running_jobs WHERE session_id = SYS_CONTEXT('USERENV','SESSIONID');
v_batch_id := &NOMBRE_PAQUETE..start_execution('NIGHTLY_BATCH', v_job_name);

-- NIVEL 2: Sub-tareas (detectan automáticamente el job_name)
v_export_id := &NOMBRE_PAQUETE..start_execution('EXPORT_TASK');
v_cleanup_id := &NOMBRE_PAQUETE..start_execution('CLEANUP_TASK');
```

**Escenario 4: Message Queue Integration**
```sql
-- NIVEL 1: Job batch con ID manual
v_batch_id := &NOMBRE_PAQUETE..start_execution('BATCH_NIGHTLY', 'SCHED_20241008_001');

-- NIVEL 2: Tareas individuales
v_task1_id := &NOMBRE_PAQUETE..start_execution('TASK_EXPORT');
v_task2_id := &NOMBRE_PAQUETE..start_execution('TASK_CLEANUP');
```

**Escenario 4: Message Queue Integration**
```sql
-- NIVEL 1: Message processor con message ID externo
v_msg_id := &NOMBRE_PAQUETE..start_execution('MQ_CONSUMER', p_message_id_from_queue);

-- NIVEL 2: Business logic (hereda message ID)
v_processor_id := &NOMBRE_PAQUETE..start_execution('MESSAGE_PROCESSOR');

-- NIVEL 3: Persistence layer (hereda message ID)
v_persist_id := &NOMBRE_PAQUETE..start_execution('PERSISTENCE_LAYER');
```

#### Limitaciones de la Detección Automática

La librería **NO puede detectar automáticamente** IDs cuando provienen de:

- **Headers HTTP**: Correlation/Request IDs de APIs REST/SOAP
- **Variables de entorno**: Job IDs de schedulers externos
- **Parámetros de entrada**: IDs pasados como argumentos de procedimientos
- **Contexto de aplicación**: Session/User IDs de aplicaciones web
- **Sistemas de colas**: Message/Transaction IDs de MQ, Kafka, etc.
- **Load balancers**: Session affinity IDs
- **Tracing systems**: Trace/Span IDs de Jaeger, Zipkin, etc.

En estos casos, el **registro manual del ancestro es esencial** para mantener la trazabilidad end-to-end.

#### Consultas de Trazabilidad

**Ver jerarquía completa:**
```sql
SELECT 
    LEVEL,
    LPAD(' ', (LEVEL-1)*2) || module_name AS hierarchy,
    execution_id,
    ancestor_execution_id,
    log_timestamp
FROM &NOMBRE_TABLA_LOG
START WITH ancestor_execution_id IS NULL
CONNECT BY PRIOR execution_id = ancestor_execution_id
ORDER SIBLINGS BY log_timestamp;
```

**Ver ejecuciones por familia:**
```sql
WITH execution_family AS (
    SELECT execution_id, ancestor_execution_id, module_name
    FROM &NOMBRE_TABLA_LOG
    START WITH execution_id = 'TARGET_EXECUTION_ID'
    CONNECT BY PRIOR ancestor_execution_id = execution_id
    UNION
    SELECT execution_id, ancestor_execution_id, module_name  
    FROM &NOMBRE_TABLA_LOG
    START WITH execution_id = 'TARGET_EXECUTION_ID'
    CONNECT BY PRIOR execution_id = ancestor_execution_id
)
SELECT * FROM &NOMBRE_TABLA_LOG
WHERE execution_id IN (SELECT execution_id FROM execution_family)
ORDER BY log_timestamp;
```

### Configuración de Silenciamiento

**Estrategia Unificada**: Ambas implementaciones (Database y Queue) respetan el mismo sistema de silenciamiento.

#### Lógica de Silenciamiento por Módulo:
- Por módulo completo: `(module_name, NULL)`
- Por nivel y superiores: `(module_name, nivel_numero)`
- Insensible a mayúsculas y espacios

#### Comportamiento por Implementación:

**Database Implementation:**
```sql
IF NOT is_silenced(p_module_name, p_insertion_type) THEN
    INSERT INTO &NOMBRE_TABLA_LOG (...);  -- Solo inserta si NO está silenciado
END IF;
```

**Queue Implementation:**
```sql
IF NOT is_silenced(p_module_name, p_insertion_type) AND is_queue_enabled(p_module_name) THEN
    DBMS_AQ.ENQUEUE(...);  -- Solo envía a cola si NO está silenciado Y cola habilitada
END IF;
```

#### Combinaciones de Configuración:

| Silenciamiento | Cola Habilitada | Database | Queue |
|---------------|-----------------|----------|-------|
| ❌ No silenciado | ❌ Deshabilitada | ✅ Inserta | ❌ No envía |
| ❌ No silenciado | ✅ Habilitada | ✅ Inserta | ✅ Envía |
| ✅ Silenciado | ❌ Deshabilitada | ❌ No inserta | ❌ No envía |
| ✅ Silenciado | ✅ Habilitada | ❌ No inserta | ❌ No envía |

> 🎯 **Principio**: El silenciamiento tiene prioridad sobre la configuración de cola. Un log silenciado NUNCA se procesa, independientemente del destino.

### Análisis de Rendimiento
- Vista `elapsed` permite medir tiempos entre operaciones
- Timestamps precisos con SYSTIMESTAMP
- Agrupación por ejecución y sesión