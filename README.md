# Sistema de Logging PL/SQL

Sistema completo de logging para Oracle PL/SQL con capacidades avanzadas de trazabilidad, configuración de silenciamiento y medición de rendimiento.

## 📋 Características Principales

- **Logging por niveles**: DEBUG, INFO, WARN, ERROR
- **Dos implementaciones**: Database only vs Queue only (JMS/AQ)
- **Trazabilidad completa**: Seguimiento de ejecuciones padre-hijo con anidamiento automático
- **Ejecuciones anidadas**: Detección automática de ancestros + registro manual opcional
- **Configuración de silenciamiento**: Control granular por módulo y nivel (consistente en ambas implementaciones)
- **Medición de tiempos**: Cálculo automático de tiempo transcurrido entre logs
- **Transacciones autónomas**: Logging independiente de la transacción principal
- **Identificadores únicos**: GUIDs para cada ejecución
- **Testing integrado**: Suite completa de pruebas automatizadas
- **Idempotencia**: Scripts ejecutables múltiples veces sin errores

## 🏗️ Estructura del Proyecto

```
plsql_logs/
├── README.md                    # Este archivo
├── deploy/                      # Scripts de despliegue
│   ├── README.md               # Documentación de despliegues
│   ├── deploy_database_logger.sql    # Deploy estándar BD
│   ├── deploy_database_with_tests.sql # BD + pruebas integradas
│   ├── deploy_queue_logger.sql       # Deploy implementación colas
│   ├── deploy_queue_with_tests.sql   # Colas + pruebas integradas
│   ├── deploy_tests_database.sql     # Solo pruebas BD
│   ├── deploy_tests_queue.sql        # Solo pruebas colas
│   ├── deploy_cleanup_database.sql   # Limpieza BD
│   └── deploy_cleanup_queue.sql      # Limpieza colas
├── src/                        # Código fuente modular
│   ├── config/                 # Configuraciones
│   │   ├── README.md          # Documentación configuraciones
│   │   ├── config_common.sql  # Variables comunes
│   │   ├── config_database.sql # Config implementación BD
│   │   └── config_queue.sql   # Config implementación colas
│   ├── tables/                # Definiciones de tablas
│   ├── indexes/               # Índices de optimización
│   ├── views/                 # Vistas de consulta
│   ├── packages/              # Paquetes PL/SQL
│   ├── queues/               # Objetos Oracle AQ
│   └── cleanup/              # Scripts de limpieza
├── tests/                     # Scripts de pruebas
│   ├── README.md             # Guía de pruebas
│   ├── TESTING_GUIDE.md      # Documentación completa
│   ├── test_database_logger.sql # Pruebas BD exhaustivas
│   ├── test_database_simple.sql # Pruebas BD rápidas
│   ├── test_queue_logger.sql # Pruebas colas exhaustivas
│   ├── test_queue_simple.sql # Pruebas colas rápidas
│   └── test_queue_monitor.sql # Monitor tiempo real
├── docs/                     # Documentación técnica
│   ├── database_schema.md    # Esquema de base de datos
│   ├── idempotency.md        # Documentación de idempotencia
│   └── generation.md         # Proceso de generación de archivos
├── scripts/                  # Herramientas de construcción
├── requirements.txt          # Dependencias Python
└── LICENSE                   # Licencia MIT
```

## 🎯 Implementaciones Disponibles

### 📊 **Implementación Database** (Recomendada)
- **Arquitectura**: Almacenamiento directo en tablas Oracle
- **Uso**: Aplicaciones que requieren persistencia local de logs
- **Características**: Vistas de consulta, índices optimizados, silenciamiento configurable

### 🔄 **Implementación Queue**
- **Arquitectura**: Envío de logs a Oracle Advanced Queuing (AQ)
- **Uso**: Sistemas distribuidos, integración con herramientas externas
- **Requisitos**: Privilegios de AQ habilitados en Oracle
- **Características**: Procesamiento asíncrono, integración con sistemas externos

## 🚀 Instalación y Deployment

### Prerrequisitos

- Python 3.x
- Herramienta `MergeSourceFile` (disponible en PyPI)
- Oracle Database con privilegios de creación de objetos

### Instalación de Dependencias

```bash
# Crear entorno virtual (recomendado)
python -m venv venv

# Activar entorno virtual
# En Windows:
venv\Scripts\activate
# En Linux/Mac:
source venv/bin/activate

# Instalar todas las dependencias
pip install -r requirements.txt
```

### Generar Scripts Consolidados

#### Opción 1: Script Automático (Recomendado)
```bash
# Generar todos los scripts de una vez
python generate_all.py

# Generar solo archivos específicos
python generate_all.py database queue

# Ver targets disponibles
python generate_all.py --list

# Ayuda
python generate_all.py --help
```

#### Opción 2: Generación Manual
Usa la herramienta `MergeSourceFile` para consolidar archivos específicos:

```bash
# Implementación de Base de Datos
MergeSourceFile -i deploy\deploy_database_logger.sql -o database_logger.sql

# Implementación de Base de Datos con Pruebas
MergeSourceFile -i deploy\deploy_database_with_tests.sql -o database_with_tests.sql

# Implementación de Colas
MergeSourceFile -i deploy\deploy_queue_logger.sql -o queue_logger.sql

# Implementación de Colas con Pruebas  
MergeSourceFile -i deploy\deploy_queue_with_tests.sql -o queue_with_tests.sql

# Solo Pruebas (sistema ya instalado)
MergeSourceFile -i deploy\deploy_tests_database.sql -o tests_database.sql
MergeSourceFile -i deploy\deploy_tests_queue.sql -o tests_queue.sql

# Scripts de Limpieza (eliminan todo)
MergeSourceFile -i deploy\deploy_cleanup_database.sql -o cleanup_database.sql
MergeSourceFile -i deploy\deploy_cleanup_queue.sql -o cleanup_queue.sql
```

> 💡 **Archivos Generados**: Los archivos consolidados (`*.sql`) no se versionan en el repositorio para mantenerlo limpio. Se generan dinámicamente desde las fuentes modulares en `src/`.

> 📖 **Herramienta**: Para más información sobre MergeSourceFile, consulta el [repositorio oficial](https://github.com/alegorico/mergeSourceFile).
> 
> 📋 **Documentación**: Consulta `deploy/README.md` para detalles específicos de cada implementación.

### Ejecutar Scripts Consolidados

Todos los archivos generados son compatibles con herramientas Oracle estándar: **SQL*Plus**, **SQL Developer**, **SQLcl**

```sql
-- INSTALACIÓN
-- Opción 1: Solo Base de Datos
@database_logger.sql

-- Opción 2: Base de Datos con Pruebas
@database_with_tests.sql

-- Opción 3: Solo Colas AQ
@queue_logger.sql

-- Opción 4: Colas AQ con Pruebas
@queue_with_tests.sql

-- PRUEBAS (sistema ya instalado)
-- Opción 5: Solo pruebas de Base de Datos
@tests_database.sql

-- Opción 6: Solo pruebas de Colas AQ
@tests_queue.sql

-- LIMPIEZA (ELIMINA TODO PERMANENTEMENTE)
-- Opción 7: Limpiar implementación de Base de Datos
@cleanup_database.sql

-- Opción 8: Limpiar implementación de Colas AQ
@cleanup_queue.sql
```

> ℹ️ **Idempotencia**: Todos los scripts son idempotentes y pueden ejecutarse múltiples veces sin errores. Ver `docs/idempotency.md` para detalles técnicos.

> ⚠️ **Advertencia**: Los scripts utilizan DROP/CREATE para tablas, lo que **eliminará datos existentes**. Ideal para desarrollo y testing.

> 🚨 **IMPORTANTE - Scripts de Limpieza**: Los scripts `cleanup_*.sql` eliminan **PERMANENTEMENTE** todos los objetos, datos y configuraciones del sistema. NO son recuperables. Solo usar en desarrollo o cuando se desee desinstalar completamente el sistema.

## 🧪 Pruebas y Validación

El proyecto incluye una suite completa de pruebas en la carpeta `tests/`:

### Pruebas Rápidas
```sql
-- Validación básica del sistema Database
@tests/test_database_simple.sql

-- Validación básica del sistema Queue
@tests/test_queue_simple.sql
```

### Pruebas Completas
```sql
-- Batería exhaustiva para Database
@tests/test_database_logger.sql

-- Batería exhaustiva para Queue
@tests/test_queue_logger.sql
```

### Monitoreo en Tiempo Real
```sql
-- Monitor continuo de la cola (en sesión separada)
@tests/test_queue_monitor.sql
```

**Documentación completa**: Ver `tests/TESTING_GUIDE.md` para instrucciones detalladas, troubleshooting y ejemplos de uso.

## 📊 Componentes del Sistema

### Implementación Database

#### Tablas Principales
- **`logs_reg`**: Almacena todos los registros de logging con trazabilidad completa
- **`cfg_log_silence`**: Configuración para silenciar módulos y niveles específicos

#### Vistas de Consulta
- **`vw_logs_reg_ordered`**: Vista ordenada por execution_id, session_id y timestamp
- **`vw_logs_reg_elapsed`**: Incluye cálculo de tiempo transcurrido entre logs consecutivos

### Implementación Queue

#### Componentes de Oracle AQ
- **Queue Table**: Tabla base para el sistema de colas
- **Queue Definition**: Definición de la cola de logging
- **Queue Grants**: Permisos necesarios para operación de colas

### Paquete Principal (Ambas Implementaciones)

#### `pkg_logger`
API unificada de logging que funciona con ambas implementaciones:

- `start_execution()` - Inicia trazabilidad de ejecución
- `end_execution()` - Finaliza trazabilidad de ejecución
- `log_debug()` - Logging nivel DEBUG
- `log_info()` - Logging nivel INFO
- `log_warn()` - Logging nivel WARN
- `log_error()` - Logging nivel ERROR

## 💻 Uso del Sistema

> 💡 **Nota**: La API de logging es idéntica para ambas implementaciones (Database y Queue). Solo cambia el destino de los logs.

### Iniciar una ejecución
```sql
DECLARE
    v_execution_id VARCHAR2(100);
BEGIN
    -- Ejecución padre (puede especificar ancestro manual)
    v_execution_id := &NOMBRE_PAQUETE..start_execution('MI_MODULO');
    
    -- Tu código aquí
    &NOMBRE_PAQUETE..log_info('Proceso iniciado');
    
    -- Ejecución hijo (detecta automáticamente el padre)
    DECLARE
        v_child_id VARCHAR2(100);
    BEGIN
        v_child_id := &NOMBRE_PAQUETE..start_execution('SUB_MODULO');
        &NOMBRE_PAQUETE..log_debug('Sub-proceso en ejecución');
        &NOMBRE_PAQUETE..end_execution;
    END;
    
    &NOMBRE_PAQUETE..log_info('Proceso completado');
    &NOMBRE_PAQUETE..end_execution;
END;
/
```

### Ejecuciones anidadas con ancestro manual
```sql
-- Caso 1: Correlation ID desde API externa
v_execution_id := &NOMBRE_PAQUETE..start_execution('API_HANDLER', p_correlation_id);

-- Caso 2: Job ID desde scheduler externo  
v_execution_id := &NOMBRE_PAQUETE..start_execution('BATCH_PROCESS', p_job_id);

-- Caso 3: Transaction ID desde sistema de colas
v_execution_id := &NOMBRE_PAQUETE..start_execution('QUEUE_PROCESSOR', p_transaction_id);

-- Caso 4: Session ID desde aplicación web
v_execution_id := &NOMBRE_PAQUETE..start_execution('WEB_HANDLER', p_session_id);

-- Los hijos detectarán automáticamente estos IDs como ancestros
v_child_id := &NOMBRE_PAQUETE..start_execution('BUSINESS_LOGIC');
```

> 💡 **Casos donde la detección automática no funciona:**
> - IDs provenientes de APIs externas
> - Job/Batch IDs de schedulers (DBMS_SCHEDULER, Cron, etc.)
> - Correlation IDs de sistemas distribuidos
> - Transaction IDs de message queues
> - Session IDs de aplicaciones web
> - Request IDs de load balancers
> - Trace IDs de sistemas de observabilidad

## ⚙️ Configuración

El sistema utiliza variables DEFINE para personalización:

```sql
DEFINE NOMBRE_TABLA_LOG = logs_reg
DEFINE NOMBRE_PAQUETE = zpkg_logger
DEFINE NOMBRE_TABLA_CFG = cfg_log_reg_silence
```

Antes del deployment, personaliza los archivos de configuración:

### Configuración Database
Edita `src/config/config_database.sql` para personalizar nombres de tablas y objetos específicos de la implementación BD.

### Configuración Queue  
Edita `src/config/config_queue.sql` para personalizar nombres de colas y objetos AQ específicos de la implementación de colas.

### Configuración Común
El archivo `src/config/config_common.sql` contiene variables compartidas por ambas implementaciones.

> 📋 **Detalles de Configuración**: Consulta `src/config/README.md` para información detallada sobre cada parámetro configurable.

### Configurar silenciamiento (Ambas implementaciones)
```sql
-- Silenciar todos los logs DEBUG para un módulo (aplica a Database y Queue)
INSERT INTO &NOMBRE_TABLA_CFG (module_name, insertion_type) 
VALUES ('MI_MODULO', 1);

-- Silenciar completamente un módulo (aplica a Database y Queue)
INSERT INTO &NOMBRE_TABLA_CFG (module_name, insertion_type) 
VALUES ('MODULO_SILENCIOSO', NULL);
```

> 💡 **Consistencia**: El silenciamiento funciona igual en Database y Queue. Logs silenciados no se insertan en BD ni se envían a cola.

### Consultar logs (Solo implementación Database)
```sql
-- Ver logs con tiempo transcurrido
SELECT * FROM vw_&NOMBRE_TABLA_LOG._elapsed 
WHERE module_name = 'MI_MODULO';

-- Ver logs ordenados
SELECT * FROM vw_&NOMBRE_TABLA_LOG._ordered 
WHERE execution_id = 'guid-de-ejecucion';

-- Ver jerarquía de ejecuciones anidadas
SELECT 
    LEVEL,
    LPAD(' ', (LEVEL-1)*2) || module_name AS hierarchy,
    execution_id,
    ancestor_execution_id
FROM &NOMBRE_TABLA_LOG
START WITH ancestor_execution_id IS NULL
CONNECT BY PRIOR execution_id = ancestor_execution_id
ORDER SIBLINGS BY log_timestamp;
```

> 📋 **Implementación Queue**: Los logs se envían a colas AQ para procesamiento por sistemas externos. Consulta la documentación de tu sistema consumidor para ver los logs.

## 🔧 Configuración

El sistema utiliza variables DEFINE para personalización:

- `NOMBRE_TABLA_LOG`: Nombre de la tabla principal de logs (default: `logs_reg`)
- `NOMBRE_PAQUETE`: Nombre del paquete de logging (default: `pkg_logger`)
- `NOMBRE_TABLA_CFG`: Nombre de la tabla de configuración (default: `cfg_log_silence`)

## 📈 Niveles de Logging

| Nivel | Número | Descripción |
|-------|--------|-------------|
| DEBUG | 1      | Información detallada para debugging |
| INFO  | 2      | Información general del flujo |
| WARN  | 3      | Advertencias y condiciones no óptimas |
| ERROR | 4      | Errores y excepciones |

## 🤝 Contribución

1. Modificar archivos fuente en el directorio `src/`
2. Compilar con `MergeSourceFile`
3. Probar en entorno de desarrollo
4. Commit de cambios en archivos fuente (no del compilado)

## 📝 Notas de Desarrollo

- **Entorno Virtual**: Se recomienda usar un entorno virtual de Python para aislar las dependencias
- **Arquitectura Modular**: El código fuente está organizado por funcionalidad en `src/`
- **Múltiples Implementaciones**: Elegir entre Database o Queue según necesidades del proyecto
- **Build Tool**: `MergeSourceFile` incluido en `requirements.txt` - consultar documentación oficial para opciones avanzadas
- **Testing Integrado**: Usar scripts `*_with_tests.sql` para validación automática
- **Configuración**: Personalizar archivos en `src/config/` antes del deployment
- **Limpieza**: Usar scripts de cleanup para eliminar instalaciones completas
- **Archivos Generados**: Los archivos `*.sql` consolidados no se versionan, usar `python generate_all.py` para crearlos
- **Versionado**: Solo versionar archivos fuente, no los compilados
- **Documentación**: Consultar `deploy/README.md` para detalles específicos de deployment

## 🌐 Integración con Sistemas Externos

### Trazabilidad End-to-End

El sistema permite integrar IDs de trazabilidad de sistemas externos que la librería no puede detectar automáticamente:

```sql
-- Ejemplo: API REST con correlation header
PROCEDURE handle_api_request(p_correlation_id VARCHAR2) IS
    v_exec_id VARCHAR2(100);
BEGIN
    -- Usar correlation ID del header HTTP
    v_exec_id := &NOMBRE_PAQUETE..start_execution('API_ENDPOINT', p_correlation_id);
    
    -- Procesar request (hijos heredan la trazabilidad)
    process_business_logic();
    call_database_operations();
    
    &NOMBRE_PAQUETE..end_execution;
END;

-- Ejemplo: Job desde DBMS_SCHEDULER
PROCEDURE scheduled_job IS
    v_exec_id VARCHAR2(100);
    v_job_name VARCHAR2(100);
BEGIN
    -- Obtener job name del contexto del scheduler
    SELECT job_name INTO v_job_name 
    FROM user_scheduler_running_jobs 
    WHERE session_id = SYS_CONTEXT('USERENV','SESSIONID');
    
    -- Usar job name como ancestro
    v_exec_id := &NOMBRE_PAQUETE..start_execution('NIGHTLY_BATCH', v_job_name);
    
    &NOMBRE_PAQUETE..end_execution;
END;
```

### Patrones de Integración

| Fuente Externa | Ejemplo de ID | Uso en start_execution |
|----------------|---------------|------------------------|
| **API Gateway** | `req-123e4567-e89b-12d3` | `start_execution('API', p_request_id)` |
| **Message Queue** | `msg-789a1234-b567-89cd` | `start_execution('MQ_CONSUMER', p_message_id)` |
| **Microservice** | `trace-456f7890-1234-5678` | `start_execution('SERVICE', p_trace_id)` |
| **Load Balancer** | `lb-session-987654321` | `start_execution('LB_HANDLER', p_lb_session)` |
| **DBMS_SCHEDULER** | `JOB_NIGHTLY_20241008` | `start_execution('BATCH', p_job_name)` |

## 📊 Niveles de Logging

| Nivel | Número | Descripción |
|-------|--------|-------------|
| DEBUG | 1      | Información detallada para depuración |
| INFO  | 2      | Información general del flujo |
| WARN  | 3      | Advertencias que no impiden la ejecución |
| ERROR | 4      | Errores que pueden afectar la funcionalidad |

## ⚙️ Requisitos

- Oracle Database 12c o superior
- Privilegios para crear tablas, índices, vistas y paquetes
- Privilegio para usar DBMS_APPLICATION_INFO
- Para implementación Queue: Privilegios de Oracle Advanced Queuing habilitados

### Compatibilidad Oracle

El sistema está optimizado para Oracle Database y utiliza:
- **Variables DEFINE**: Para configuración dinámica de nombres
- **PRAGMA AUTONOMOUS_TRANSACTION**: Para logging independiente
- **DBMS_APPLICATION_INFO**: Para trazabilidad de contexto
- **Funciones analíticas**: LAG() para cálculo de tiempos transcurridos
- **Columnas virtuales**: Para optimización de búsquedas case-insensitive

### Configuración del Entorno de Desarrollo

1. **Clonar el repositorio**:
   ```bash
   git clone <repository-url>
   cd plsql_logs
   ```

2. **Configurar entorno Python**:
   ```bash
   python -m venv venv
   venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   ```

3. **Compilar y probar**:
   ```bash
   # Implementación básica con pruebas
   MergeSourceFile -i deploy\deploy_database_with_tests.sql -o test_logger.sql
   ```

## 🔧 Gestión de Archivos Generados

### ¿Por qué no se versionan los archivos `*.sql` consolidados?

1. **Fuente única de verdad**: Los archivos fuente en `src/` son la autoridad
2. **Evitar duplicación**: Los archivos generados son derivados de las fuentes
3. **Prevenir conflictos**: Los merges serían complicados con archivos grandes generados
4. **Flexibilidad**: Cada usuario puede generar con su configuración personalizada
5. **Tamaño del repo**: Mantener el repositorio ligero y enfocado

### Ventajas del Script de Generación Python

- **🌐 Multiplataforma**: Funciona en Windows, Linux y macOS
- **🔧 Robusto**: Mejor manejo de errores y timeouts
- **⚡ Flexible**: Generar archivos específicos o todos a la vez
- **📋 Informativo**: Resumen detallado de resultados
- **🐍 Consistente**: Usa Python como el resto de las dependencias

### Flujo recomendado:

1. **Desarrollo**: Modificar archivos en `src/`
2. **Generación**: Ejecutar `python generate_all.py` o comandos MergeSourceFile específicos
3. **Testing**: Probar con archivos generados localmente
4. **Commit**: Solo versionar cambios en `src/`, `deploy/`, `tests/`, etc.

> 💡 **Tip**: El script `generate_all.py` automatiza la generación de todos los archivos consolidados y proporciona opciones flexibles.

## 📚 Soporte y Documentación

Para información técnica detallada:
- **Esquema de BD**: `docs/database_schema.md`
- **Idempotencia**: `docs/idempotency.md` 
- **Generación**: `docs/generation.md`
- **Testing**: `tests/TESTING_GUIDE.md`
- **Configuración**: `src/config/README.md`
- **Deployment**: `deploy/README.md`
- **Código fuente**: Directorio `src/`
- **Herramienta de generación**: [MergeSourceFile](https://github.com/alegorico/mergeSourceFile)

## �📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

**Desarrollado por**: Alejandro G.  
**Última actualización**: 16 de octubre de 2025