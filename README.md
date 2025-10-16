# PL/SQL Logger System

Sistema de logging avanzado para Oracle PL/SQL con trazabilidad de ejecución, control de niveles y arquitectura modular.

## 📋 Características Principales

- **Trazabilidad de Ejecución**: Seguimiento completo de jerarquías de ejecución con `execution_id` y `ancestor_execution_id`
- **Control de Niveles**: Sistema de logging con niveles DEBUG, INFO, WARN, ERROR
- **Silenciamiento Configurable**: Capacidad de silenciar logs por módulo y nivel
- **Arquitectura Modular**: Código fuente organizado en componentes reutilizables
- **Múltiples Implementaciones**: Database (tablas) y Queue (Oracle AQ) según necesidades
- **Testing Integrado**: Suites de pruebas automáticas incluidas
- **Build System**: Herramienta Python para compilar archivos fuente en ejecutables SQL

## 🏗️ Arquitectura del Proyecto

```
plsql_logs/
├── src/                          # Código fuente modular
│   ├── config/                   # Configuraciones por implementación
│   ├── tables/                   # Definiciones de tablas
│   ├── indexes/                  # Índices de optimización
│   ├── views/                    # Vistas para consultas
│   ├── packages/                 # Paquete principal de logging
│   ├── queues/                   # Componentes de Oracle Advanced Queuing
│   └── cleanup/                  # Scripts de limpieza
├── deploy/                       # Scripts de deployment
│   ├── deploy_database_logger.sql     # Implementación solo-BD
│   ├── deploy_database_with_tests.sql # BD + pruebas integradas
│   ├── deploy_queue_logger.sql        # Implementación con colas AQ
│   ├── deploy_queue_with_tests.sql    # Colas + pruebas integradas
│   ├── deploy_tests_database.sql      # Solo pruebas BD
│   ├── deploy_tests_queue.sql         # Solo pruebas colas
│   ├── deploy_cleanup_database.sql    # Limpieza BD
│   ├── deploy_cleanup_queue.sql       # Limpieza colas
│   └── README.md                      # Documentación de deployment
├── requirements.txt              # Dependencias Python
├── LICENSE                      # Licencia MIT
└── README.md                    # Documentación del proyecto
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

# Instalar dependencias desde requirements.txt
pip install -r requirements.txt

# O instalar directamente MergeSourceFile
pip install MergeSourceFile
```

### Compilación del Proyecto

Selecciona la implementación que necesites y compila:

```bash
# Implementación Database (recomendada)
MergeSourceFile -i deploy\deploy_database_logger.sql -o database_logger.sql

# Implementación Database con pruebas
MergeSourceFile -i deploy\deploy_database_with_tests.sql -o database_with_tests.sql

# Implementación Queue
MergeSourceFile -i deploy\deploy_queue_logger.sql -o queue_logger.sql

# Implementación Queue con pruebas
MergeSourceFile -i deploy\deploy_queue_with_tests.sql -o queue_with_tests.sql
```

> 📖 **Nota**: Para opciones avanzadas de `MergeSourceFile`, consulta la [documentación oficial de MergeSourceFile](https://pypi.org/project/MergeSourceFile/).
> 
> 📋 **Deployment Details**: Consulta `deploy/README.md` para detalles específicos de cada implementación.

### Deployment en Base de Datos

Todos los archivos generados son compatibles con herramientas Oracle estándar:
- **SQL*Plus**, **SQL Developer**, **SQLcl**

#### Deployment Básico - Implementación Database
```bash
sqlplus usuario/password@database
SQL> @database_logger.sql
```

#### Deployment con Pruebas - Validación Automática
```bash
sqlplus usuario/password@database
SQL> @database_with_tests.sql
```

#### Deployment Implementación Queue (requiere privilegios AQ)
```bash
sqlplus usuario/password@database
SQL> @queue_logger.sql
```

> ⚠️ **Importante**: La implementación Queue requiere privilegios de Oracle Advanced Queuing habilitados.
> 
> 📋 **Configuración**: Antes del deployment, revisa y personaliza los archivos de configuración en `src/config/`.

## 🧪 Testing y Validación

El proyecto incluye suites de pruebas integradas para validar la funcionalidad:

### Scripts de Pruebas Disponibles
- **`deploy_database_with_tests.sql`**: Instalación completa + pruebas automáticas
- **`deploy_queue_with_tests.sql`**: Instalación colas + pruebas automáticas
- **`deploy_tests_database.sql`**: Solo pruebas para implementación BD existente
- **`deploy_tests_queue.sql`**: Solo pruebas para implementación colas existente

### Limpieza del Sistema
```bash
# Limpiar implementación Database
MergeSourceFile -i deploy\deploy_cleanup_database.sql -o cleanup_db.sql

# Limpiar implementación Queue  
MergeSourceFile -i deploy\deploy_cleanup_queue.sql -o cleanup_queue.sql
```

> ⚠️ **ADVERTENCIA**: Los scripts de limpieza eliminan **PERMANENTEMENTE** todos los objetos y datos del sistema de logging.

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

### Ejemplo Básico

```sql
DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    -- Iniciar trazabilidad
    v_execution_id := pkg_logger.start_execution('MI_MODULO');
    
    -- Logging de diferentes niveles
    pkg_logger.log_info('Proceso iniciado correctamente');
    pkg_logger.log_debug('Valor de variable X: ' || v_variable);
    pkg_logger.log_warn('Condición no óptima detectada');
    
    -- En caso de error
    pkg_logger.log_error('ORA-00001', 'Error de integridad referencial');
    
    -- Finalizar trazabilidad
    pkg_logger.end_execution();
END;
/
```

## ⚙️ Configuración

Antes del deployment, personaliza los archivos de configuración según tu implementación:

### Configuración Database
Edita `src/config/config_database.sql` para personalizar:
- Nombres de tablas y objetos
- Parámetros de configuración específicos

### Configuración Queue  
Edita `src/config/config_queue.sql` para personalizar:
- Nombres de colas y objetos AQ
- Parámetros de configuración específicos

### Configuración Común
El archivo `src/config/config_common.sql` contiene variables compartidas por ambas implementaciones.

> 📋 **Detalles de Configuración**: Consulta `src/config/README.md` para información detallada sobre cada parámetro configurable.

### Configuración de Silenciamiento (Solo Implementación Database)

```sql
-- Silenciar todos los logs de un módulo
INSERT INTO cfg_log_silence (module_name, insertion_type) 
VALUES ('MODULO_RUIDOSO', NULL);

-- Silenciar solo DEBUG e INFO de un módulo (mostrar solo WARN y ERROR)
INSERT INTO cfg_log_silence (module_name, insertion_type) 
VALUES ('MODULO_PARCIAL', 2);
```

### Consulta de Logs (Solo Implementación Database)

```sql
-- Ver logs ordenados con tiempo transcurrido
SELECT execution_id, module_name, log_timestamp, insertion_type, 
       log_message, elapsed_seconds_since_prev
FROM vw_logs_reg_elapsed
WHERE module_name = 'MI_MODULO'
ORDER BY log_timestamp;
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
- **Build Tool**: Consultar documentación de `MergeSourceFile` para opciones avanzadas
- **Testing Integrado**: Usar scripts `*_with_tests.sql` para validación automática
- **Configuración**: Personalizar archivos en `src/config/` antes del deployment
- **Limpieza**: Usar scripts de cleanup para eliminar instalaciones completas
- **Versionado**: Solo versionar archivos fuente, no los compilados
- **Documentación**: Consultar `deploy/README.md` para detalles específicos de deployment

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

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

**Desarrollado por**: Alejandro G.  
**Última actualización**: 16 de octubre de 2025