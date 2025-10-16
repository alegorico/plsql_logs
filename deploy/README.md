# Scripts de Despliegue del Logger

## Descripción
Esta carpeta contiene los scripts de despliegue para las diferentes implementaciones del sistema de logging.

## Scripts Disponibles

### Implementación de Base de Datos

#### `deploy_database_logger.sql`
- **Propósito**: Despliegue para implementación solo-BD
- **Configuración**: Usa `config_database.sql` (personalizable)
- **Arquitectura**: Almacenamiento en tablas Oracle
- **Uso**: Modifica `config_database.sql` según tus necesidades y ejecuta

#### `deploy_database_with_tests.sql`
- **Propósito**: Despliegue completo BD + suite de pruebas
- **Configuración**: Usa `config_database.sql`
- **Contenido**: Sistema completo + pruebas integradas
- **Uso**: Instalación completa con validación automática

#### `deploy_tests_database.sql`
- **Propósito**: Solo scripts de pruebas para BD
- **Prerequisito**: Sistema ya instalado
- **Uso**: Ejecutar pruebas en sistema existente

### Implementación de Colas

#### `deploy_queue_logger.sql`
- **Propósito**: Despliegue para implementación con Oracle Advanced Queuing
- **Configuración**: Usa `config_queue.sql`
- **Arquitectura**: Envío de logs a colas AQ para sistemas externos
- **Requisitos**: Privilegios de AQ habilitados

#### `deploy_queue_with_tests.sql`
- **Propósito**: Despliegue completo colas + suite de pruebas
- **Configuración**: Usa `config_queue.sql`
- **Contenido**: Sistema completo + pruebas integradas
- **Uso**: Instalación completa con validación automática

#### `deploy_tests_queue.sql`
- **Propósito**: Solo scripts de pruebas para colas
- **Prerequisito**: Sistema ya instalado
- **Uso**: Ejecutar pruebas en sistema existente

### Scripts de Limpieza

#### `deploy_cleanup_database.sql`
- **Propósito**: Elimina completamente la implementación de BD
- **⚠️ PELIGRO**: Eliminación PERMANENTE de todos los objetos y datos
- **Configuración**: Usa `config_database.sql`
- **Uso**: Solo para desarrollo o desinstalación completa

#### `deploy_cleanup_queue.sql`
- **Propósito**: Elimina completamente la implementación con colas
- **⚠️ PELIGRO**: Eliminación PERMANENTE de objetos, datos y mensajes AQ
- **Configuración**: Usa `config_queue.sql`
- **Uso**: Solo para desarrollo o desinstalación completa

> 🚨 **ADVERTENCIA CRÍTICA**: Los scripts de limpieza eliminan **PERMANENTEMENTE** todos los datos, configuraciones y objetos relacionados. No hay vuelta atrás. Solo usar en entornos de desarrollo o cuando se desee desinstalar completamente el sistema.

## Cómo Generar Scripts Consolidados

Usa la herramienta `mergeSourceFile.py` para consolidar todos los archivos:

```bash
# Para implementación de BD
python scripts/mergeSourceFile.py --config ./deploy/deploy_database_logger.sql --output ./output_database.sql

# Para implementación de BD con pruebas
python scripts/mergeSourceFile.py --config ./deploy/deploy_database_with_tests.sql --output ./output_database_with_tests.sql

# Para solo pruebas de BD
python scripts/mergeSourceFile.py --config ./deploy/deploy_tests_database.sql --output ./output_tests_database.sql

# Para implementación de colas
python scripts/mergeSourceFile.py --config ./deploy/deploy_queue_logger.sql --output ./output_queue.sql

# Para implementación de colas con pruebas
python scripts/mergeSourceFile.py --config ./deploy/deploy_queue_with_tests.sql --output ./output_queue_with_tests.sql

# Para solo pruebas de colas
python scripts/mergeSourceFile.py --config ./deploy/deploy_tests_queue.sql --output ./output_tests_queue.sql

# Para limpieza de BD (ELIMINA TODO)
python scripts/mergeSourceFile.py --config ./deploy/deploy_cleanup_database.sql --output ./output_cleanup_database.sql

# Para limpieza de colas (ELIMINA TODO)
python scripts/mergeSourceFile.py --config ./deploy/deploy_cleanup_queue.sql --output ./output_cleanup_queue.sql
```

## Ejecución de Scripts Consolidados

```sql
-- INSTALACIÓN
@output_database.sql                    -- Solo BD
@output_database_with_tests.sql         -- BD + Pruebas
@output_queue.sql                       -- Solo Colas
@output_queue_with_tests.sql            -- Colas + Pruebas

-- PRUEBAS (solo si sistema ya instalado)
@output_tests_database.sql              -- Pruebas BD
@output_tests_queue.sql                 -- Pruebas Colas

-- LIMPIEZA (ELIMINA TODO - NO RECUPERABLE)
@output_cleanup_database.sql            -- Limpiar BD
@output_cleanup_queue.sql               -- Limpiar Colas
```

## Personalización

Para personalizar nombres de tablas y objetos:

1. **Edita las configuraciones**: Modifica `src/config/config_database.sql` o `src/config/config_queue.sql`
2. **Cambia las variables DEFINE**: Ajusta los nombres según tu proyecto
3. **Genera el script**: Ejecuta `mergeSourceFile.py` con el deploy correspondiente

## Estructura de un Script de Deploy

```sql
-- Comentarios descriptivos
@src/config/tu_configuracion.sql
@src/tables/log_table.sql
-- ... más objetos según necesites
```