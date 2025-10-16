# PL/SQL Logger System

Sistema de logging avanzado para Oracle PL/SQL con trazabilidad de ejecución, control de niveles y arquitectura modular.

## 📋 Características Principales

- **Trazabilidad de Ejecución**: Seguimiento completo de jerarquías de ejecución con `execution_id` y `ancestor_execution_id`
- **Control de Niveles**: Sistema de logging con niveles DEBUG, INFO, WARN, ERROR
- **Silenciamiento Configurable**: Capacidad de silenciar logs por módulo y nivel
- **Arquitectura Modular**: Código fuente organizado en componentes reutilizables
- **Build System**: Herramienta Python para compilar archivos fuente en ejecutables SQL

## 🏗️ Arquitectura del Proyecto

```
plsql_logs/
├── src/                          # Código fuente modular
│   ├── config/
│   │   └── config_common.sql     # Variables de configuración
│   ├── tables/
│   │   ├── log_table.sql         # Tabla principal de logs
│   │   └── config_table.sql      # Tabla de configuración
│   ├── indexes/
│   │   └── config_index.sql      # Índices de optimización
│   ├── views/
│   │   ├── log_elapsed.sql       # Vista con tiempos transcurridos
│   │   └── log_ordered.sql       # Vista ordenada de logs
│   └── packages/
│       └── pkg_logger.sql        # Paquete principal de logging
├── deploy/
│   └── deploy_database_logger.sql # Script de deployment
├── logger.sql                    # Archivo compilado completo
├── requirements.txt             # Dependencias Python
├── LICENSE                      # Licencia MIT
└── README.md                    # Documentación del proyecto
```

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

Para generar el archivo SQL ejecutable desde las fuentes modulares:

```bash
MergeSourceFile -i deploy\deploy_database_logger.sql -o logger.sql
```

> 📖 **Nota**: Para opciones avanzadas de `MergeSourceFile` (como `--skip-var` u otras), consulta la [documentación oficial de MergeSourceFile](https://pypi.org/project/MergeSourceFile/).

El proceso de compilación:
1. Lee el script de deployment que referencia todos los archivos fuente
2. Combina todos los componentes modulares en un archivo único
3. Genera `logger.sql` listo para ejecutar en Oracle

### Deployment en Base de Datos

El archivo generado `logger.sql` es totalmente compatible con:
- **SQL*Plus**: Herramienta de línea de comandos de Oracle
- **SQL Developer**: IDE gráfico de Oracle
- **SQLcl**: Herramienta moderna de línea de comandos de Oracle

#### Deployment con SQL*Plus
```bash
# Conectar y ejecutar
sqlplus usuario/password@database
SQL> @logger.sql
```

#### Deployment con SQL Developer
1. Abrir SQL Developer
2. Conectar a la base de datos
3. Abrir el archivo `logger.sql`
4. Ejecutar como script (F5)

#### Deployment con SQLcl
```bash
sql usuario/password@database
SQL> @logger.sql
```

## 📊 Componentes del Sistema

### Tablas Principales

#### `logs_reg` - Tabla de Logs
Almacena todos los registros de logging con trazabilidad completa.

#### `cfg_log_silence` - Configuración de Silenciamiento
Permite configurar qué módulos y niveles de logging se silencian.

### Vistas

#### `vw_logs_reg_ordered`
Vista ordenada de logs por execution_id, session_id y timestamp.

#### `vw_logs_reg_elapsed`
Vista que incluye cálculo de tiempo transcurrido entre logs consecutivos.

### Paquete Principal

#### `pkg_logger`
Paquete que proporciona la API de logging:

- `start_execution()` - Inicia trazabilidad de ejecución
- `end_execution()` - Finaliza trazabilidad de ejecución
- `log_debug()` - Logging nivel DEBUG
- `log_info()` - Logging nivel INFO
- `log_warn()` - Logging nivel WARN
- `log_error()` - Logging nivel ERROR

## 💻 Uso del Sistema

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

### Configuración de Silenciamiento

```sql
-- Silenciar todos los logs de un módulo
INSERT INTO cfg_log_silence (module_name, insertion_type) 
VALUES ('MODULO_RUIDOSO', NULL);

-- Silenciar solo DEBUG e INFO de un módulo (mostrar solo WARN y ERROR)
INSERT INTO cfg_log_silence (module_name, insertion_type) 
VALUES ('MODULO_PARCIAL', 2);
```

### Consulta de Logs

```sql
-- Ver logs ordenados con tiempo transcurrido
SELECT execution_id, module_name, log_timestamp, insertion_type, 
       log_message, elapsed_seconds_since_prev
FROM vw_logs_reg_elapsed
WHERE module_name = 'MI_MODULO'
ORDER BY log_timestamp;
```

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
- **Archivos Fuente**: Mantener siempre actualizados los archivos en `src/`
- **Compilación**: No editar directamente `logger.sql`, usar siempre el build system
- **Build Tool**: Consultar documentación de `MergeSourceFile` para opciones avanzadas
- **Testing**: Compilar y probar en entorno de desarrollo antes de deployment
- **Versionado**: Solo versionar archivos fuente, no los compilados
- **Dependencias**: El archivo `requirements.txt` contiene todas las dependencias Python necesarias
- **Gitignore**: Los archivos compilados (`logger.sql`) están excluidos del control de versiones

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
   MergeSourceFile -i deploy\deploy_database_logger.sql -o logger.sql
   ```

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

**Desarrollado por**: Alejandro G.  
**Última actualización**: 16 de octubre de 2025