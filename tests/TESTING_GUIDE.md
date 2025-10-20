# Scripts de Pruebas para Logger con Colas

Este directorio contiene varios scripts para probar y validar el sistema de logging basado en Oracle Advanced Queuing.

## Scripts Disponibles

### 1. `test_queue_logger.sql` - Pruebas Completas
**Propósito**: Batería completa de pruebas para validar todas las funcionalidades del sistema de logging con colas.

**Características**:
- ✅ Configuración de módulos con cola habilitada/deshabilitada
- ✅ Pruebas de silenciamiento por nivel
- ✅ Verificación de estado de colas AQ
- ✅ Logging en todos los niveles (DEBUG, INFO, WARN, ERROR)
- ✅ Ejecuciones anidadas con trazabilidad
- ✅ Simulación de consumo de mensajes
- ✅ Limpieza automática de datos de prueba

**Cómo usar**:
```sql
-- 1. Ejecutar primero el deploy
@generated_queue_fixed.sql

-- 2. Ejecutar las pruebas
@test_queue_logger.sql
```

### 2. `test_queue_simple.sql` - Pruebas Rápidas
**Propósito**: Validación rápida del funcionamiento básico.

**Características**:
- ✅ Configuración mínima
- ✅ Logging básico en varios niveles
- ✅ Verificación de mensajes en cola
- ✅ Limpieza automática

**Cómo usar**:
```sql
@test_queue_simple.sql
```

### 3. `test_queue_monitor.sql` - Monitor en Tiempo Real
**Propósito**: Monitoreo de la cola de logging durante las pruebas.

**Características**:
- ✅ Monitoreo continuo de mensajes en cola
- ✅ Estadísticas por nivel de log
- ✅ Vista de últimos mensajes
- ✅ Estado de configuración de módulos

**Cómo usar**:
```sql
-- En una sesión separada
@test_queue_monitor.sql
```

## Flujo de Trabajo Recomendado

### Instalación y Configuración
1. **Desplegar el sistema**:
   ```sql
   @generated_queue_fixed.sql
   ```

2. **Verificar instalación**:
   ```sql
   @test_queue_simple.sql
   ```

### Pruebas Exhaustivas
1. **Ejecutar en una terminal** (monitor):
   ```sql
   @test_queue_monitor.sql
   ```

2. **Ejecutar en otra terminal** (pruebas):
   ```sql
   @test_queue_logger.sql
   ```

### Uso en Aplicaciones

```sql
-- Ejemplo de uso en tu aplicación
DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    -- 1. Configurar módulo (una sola vez)
    INSERT INTO cfg_log_queue_logger (module_name, queue_enabled) 
    VALUES ('MI_APLICACION', 1);
    COMMIT;
    
    -- 2. Usar en tu código
    v_execution_id := pkg_logger.start_execution('MI_APLICACION');
    
    pkg_logger.log_info('Aplicacion iniciada');
    pkg_logger.log_warn('Advertencia de ejemplo');
    
    pkg_logger.end_execution();
END;
/
```

## Configuraciones Avanzadas

### Silenciamiento por Nivel
```sql
-- Silenciar DEBUG e INFO, permitir solo WARN y ERROR
INSERT INTO cfg_log_reg_logger_silence (module_name, insertion_type) 
VALUES ('MI_MODULO', 2);
```

### Deshabilitar Cola para un Módulo
```sql
-- El módulo seguirá funcionando pero no enviará a cola
INSERT INTO cfg_log_queue_logger (module_name, queue_enabled) 
VALUES ('MI_MODULO', 0);
```

## Consultas Útiles

### Ver Mensajes en Cola
```sql
SELECT 
    TO_CHAR(enq_time, 'DD/MM/YY HH24:MI:SS') as fecha,
    priority as nivel,
    user_data.text_vc as mensaje_json
FROM qt_log_logger 
ORDER BY enq_time DESC;
```

### Estadísticas de Cola
```sql
SELECT 
    COUNT(*) as total_mensajes,
    COUNT(CASE WHEN state = 0 THEN 1 END) as pendientes,
    COUNT(CASE WHEN state = 1 THEN 1 END) as procesados
FROM qt_log_logger;
```

### Configuración Actual
```sql
-- Módulos con cola
SELECT * FROM cfg_log_queue_logger;

-- Módulos silenciados  
SELECT * FROM cfg_log_reg_logger_silence;
```

## Troubleshooting

### Cola No Recibe Mensajes
1. Verificar que el módulo tenga cola habilitada:
   ```sql
   SELECT * FROM cfg_log_queue_logger WHERE module_name = 'TU_MODULO';
   ```

2. Verificar que no esté silenciado:
   ```sql
   SELECT * FROM cfg_log_reg_logger_silence WHERE module_name = 'TU_MODULO';
   ```

3. Verificar estado de la cola:
   ```sql
   SELECT * FROM user_queues WHERE name = 'QUEUE_LOG_LOGGER';
   ```

### Errores de Privilegios AQ
```sql
-- Verificar privilegios (ejecutar como SYSDBA si es necesario)
GRANT EXECUTE ON DBMS_AQ TO tu_usuario;
GRANT EXECUTE ON DBMS_AQADM TO tu_usuario;
```

### Limpiar Cola
```sql
-- Eliminar todos los mensajes de la cola
DELETE FROM qt_log_logger;
COMMIT;
```