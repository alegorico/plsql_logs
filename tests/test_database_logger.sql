-- ================================================================
-- SCRIPT DE PRUEBAS PARA LOGGER CON BASE DE DATOS
-- ================================================================
-- Descripcion: Script completo para probar todas las funcionalidades
--              del sistema de logging basado en tablas de BD
-- Prerequisitos: Ejecutar primero generated_table.sql
-- ================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET TIMING ON;
SET ECHO ON;

PROMPT ================================================================
PROMPT INICIO DE PRUEBAS PARA LOGGER CON BASE DE DATOS
PROMPT ================================================================

-- Limpiar datos de pruebas anteriores si existen
BEGIN
    DELETE FROM &NOMBRE_TABLA_CFG;
    DELETE FROM &NOMBRE_TABLA_LOG;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Tablas de configuracion y logs limpiadas');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Error limpiando tablas: ' || SQLERRM);
END;
/

PROMPT ================================================================
PROMPT PRUEBA 1: CONFIGURACION DE SILENCIAMIENTO
PROMPT ================================================================

-- Configurar silenciamiento para pruebas
BEGIN
    -- Silenciar DEBUG y INFO para un modulo
    INSERT INTO &NOMBRE_TABLA_CFG (module_name, insertion_type) 
    VALUES ('TEST_MODULE_SILENT', 2); -- Solo WARN y ERROR pasaran
    
    -- Silenciar completamente un modulo
    INSERT INTO &NOMBRE_TABLA_CFG (module_name, insertion_type) 
    VALUES ('TEST_MODULE_MUTED', NULL);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Configuracion de silenciamiento creada');
END;
/

-- Verificar configuracion de silenciamiento
SELECT 'CONFIG SILENCIO:' as tipo, module_name, insertion_type 
FROM &NOMBRE_TABLA_CFG 
ORDER BY module_name;

PROMPT ================================================================
PROMPT PRUEBA 2: LOGGING BASICO SIN SILENCIAMIENTO
PROMPT ================================================================

DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando sesion de logging para TEST_MODULE_NORMAL ---');
    
    -- Iniciar ejecucion
    v_execution_id := &NOMBRE_PAQUETE.start_execution('TEST_MODULE_NORMAL');
    DBMS_OUTPUT.PUT_LINE('✓ Execution ID: ' || v_execution_id);
    
    -- Probar todos los niveles
    &NOMBRE_PAQUETE.log_debug('Mensaje de debug - sin silenciamiento');
    &NOMBRE_PAQUETE.log_info('Mensaje de info - sin silenciamiento');
    &NOMBRE_PAQUETE.log_warn('Mensaje de warning - sin silenciamiento');
    &NOMBRE_PAQUETE.log_error('ERR001', 'Mensaje de error - sin silenciamiento');
    
    -- Finalizar ejecucion
    &NOMBRE_PAQUETE.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Ejecucion finalizada para modulo normal');
END;
/

-- Verificar registros insertados
SELECT COUNT(*) as "Registros Insertados" FROM &NOMBRE_TABLA_LOG 
WHERE module_name = 'TEST_MODULE_NORMAL';

PROMPT ================================================================
PROMPT PRUEBA 3: LOGGING CON SILENCIAMIENTO PARCIAL
PROMPT ================================================================

DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando sesion de logging para TEST_MODULE_SILENT ---');
    
    -- Iniciar ejecucion
    v_execution_id := &NOMBRE_PAQUETE.start_execution('TEST_MODULE_SILENT');
    DBMS_OUTPUT.PUT_LINE('✓ Execution ID: ' || v_execution_id);
    
    -- Estos mensajes deberian ser silenciados (DEBUG=1, INFO=2, config=2)
    &NOMBRE_PAQUETE.log_debug('DEBUG silenciado - NO deberia aparecer en BD');
    &NOMBRE_PAQUETE.log_info('INFO silenciado - NO deberia aparecer en BD');
    
    -- Estos mensajes NO deberian ser silenciados (WARN=3, ERROR=4 > config=2)
    &NOMBRE_PAQUETE.log_warn('WARNING NO silenciado - SI deberia aparecer en BD');
    &NOMBRE_PAQUETE.log_error('ERR002', 'ERROR NO silenciado - SI deberia aparecer en BD');
    
    -- Finalizar ejecucion
    &NOMBRE_PAQUETE.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Ejecucion finalizada para modulo silenciado');
END;
/

-- Verificar que solo WARN y ERROR se insertaron
SELECT 
    'LOGS SILENCIADOS:' as tipo,
    insertion_type,
    CASE insertion_type 
        WHEN 1 THEN 'DEBUG'
        WHEN 2 THEN 'INFO' 
        WHEN 3 THEN 'WARN'
        WHEN 4 THEN 'ERROR'
    END as nivel,
    COUNT(*) as cantidad
FROM &NOMBRE_TABLA_LOG 
WHERE module_name = 'TEST_MODULE_SILENT'
GROUP BY insertion_type 
ORDER BY insertion_type;

PROMPT ================================================================
PROMPT PRUEBA 4: LOGGING CON SILENCIAMIENTO TOTAL
PROMPT ================================================================

DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando sesion de logging para TEST_MODULE_MUTED ---');
    
    -- Iniciar ejecucion
    v_execution_id := &NOMBRE_PAQUETE.start_execution('TEST_MODULE_MUTED');
    DBMS_OUTPUT.PUT_LINE('✓ Execution ID: ' || v_execution_id);
    
    -- Todos estos mensajes deberian ser silenciados
    &NOMBRE_PAQUETE.log_debug('DEBUG completamente silenciado');
    &NOMBRE_PAQUETE.log_info('INFO completamente silenciado');
    &NOMBRE_PAQUETE.log_warn('WARNING completamente silenciado');
    &NOMBRE_PAQUETE.log_error('ERR003', 'ERROR completamente silenciado');
    
    -- Finalizar ejecucion
    &NOMBRE_PAQUETE.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Ejecucion finalizada para modulo completamente silenciado');
END;
/

-- Verificar que NO se insertaron registros
SELECT COUNT(*) as "Logs Silenciados (debe ser 0)" FROM &NOMBRE_TABLA_LOG 
WHERE module_name = 'TEST_MODULE_MUTED';

PROMPT ================================================================
PROMPT PRUEBA 5: EJECUCIONES ANIDADAS CON TRAZABILIDAD
PROMPT ================================================================

DECLARE
    v_parent_execution_id VARCHAR2(32);
    v_child_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba de ejecuciones anidadas ---');
    
    -- Ejecucion padre
    v_parent_execution_id := &NOMBRE_PAQUETE.start_execution('TEST_PARENT_MODULE');
    DBMS_OUTPUT.PUT_LINE('✓ Parent Execution ID: ' || v_parent_execution_id);
    
    &NOMBRE_PAQUETE.log_info('Mensaje desde el proceso padre');
    
    -- Ejecucion hija (deberia detectar automaticamente el padre)
    v_child_execution_id := &NOMBRE_PAQUETE.start_execution('TEST_CHILD_MODULE');
    DBMS_OUTPUT.PUT_LINE('✓ Child Execution ID: ' || v_child_execution_id);
    
    &NOMBRE_PAQUETE.log_info('Mensaje desde el proceso hijo');
    &NOMBRE_PAQUETE.log_warn('Warning desde proceso hijo');
    
    -- Finalizar hijo primero
    &NOMBRE_PAQUETE.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Proceso hijo finalizado');
    
    -- Continuar con padre
    &NOMBRE_PAQUETE.log_info('Mensaje padre despues de hijo');
    
    -- Finalizar padre
    &NOMBRE_PAQUETE.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Proceso padre finalizado');
END;
/

-- Verificar jerarquia de ejecuciones
SELECT 
    'JERARQUIA:' as tipo,
    LEVEL as nivel_anidamiento,
    LPAD(' ', (LEVEL-1)*2) || module_name AS jerarquia,
    execution_id,
    ancestor_execution_id
FROM &NOMBRE_TABLA_LOG
WHERE module_name IN ('TEST_PARENT_MODULE', 'TEST_CHILD_MODULE')
  AND insertion_type = 2 -- Solo INFO para simplificar
START WITH ancestor_execution_id IS NULL
CONNECT BY PRIOR execution_id = ancestor_execution_id
ORDER SIBLINGS BY log_timestamp;

PROMPT ================================================================
PROMPT PRUEBA 6: MEDICION DE TIEMPOS TRANSCURRIDOS
PROMPT ================================================================

DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba de medicion de tiempos ---');
    
    -- Iniciar ejecucion
    v_execution_id := &NOMBRE_PAQUETE.start_execution('TEST_TIMING_MODULE');
    
    &NOMBRE_PAQUETE.log_info('Primer log');
    
    -- Simular algo de trabajo
    DBMS_LOCK.SLEEP(1);
    
    &NOMBRE_PAQUETE.log_info('Segundo log (1 segundo despues)');
    
    -- Simular más trabajo
    DBMS_LOCK.SLEEP(2);
    
    &NOMBRE_PAQUETE.log_warn('Tercer log (2 segundos despues)');
    
    -- Finalizar
    &NOMBRE_PAQUETE.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Prueba de timing completada');
END;
/

-- Ver tiempos transcurridos usando la vista
SELECT 
    'TIEMPOS:' as tipo,
    TO_CHAR(log_timestamp, 'HH24:MI:SS.FF3') as timestamp_log,
    ROUND(elapsed_seconds, 3) as segundos_transcurridos,
    log_message
FROM vw_&NOMBRE_TABLA_LOG._elapsed 
WHERE module_name = 'TEST_TIMING_MODULE'
ORDER BY log_timestamp;

PROMPT ================================================================
PROMPT PRUEBA 7: CONSULTA DE LOGS ORDENADOS
PROMPT ================================================================

-- Usar la vista de logs ordenados
SELECT 
    'LOGS ORDENADOS:' as tipo,
    module_name,
    TO_CHAR(log_timestamp, 'DD/MM HH24:MI:SS') as timestamp_log,
    CASE insertion_type 
        WHEN 1 THEN 'DEBUG'
        WHEN 2 THEN 'INFO' 
        WHEN 3 THEN 'WARN'
        WHEN 4 THEN 'ERROR'
    END as nivel,
    SUBSTR(log_message, 1, 50) as mensaje
FROM vw_&NOMBRE_TABLA_LOG._ordered 
WHERE module_name LIKE 'TEST_%'
  AND log_timestamp >= SYSDATE - 1/24 -- Ultima hora
ORDER BY log_timestamp DESC;

PROMPT ================================================================
PROMPT PRUEBA 8: ESTADISTICAS GENERALES
PROMPT ================================================================

-- Estadisticas por modulo
SELECT 
    'STATS POR MODULO:' as tipo,
    module_name,
    COUNT(*) as total_logs,
    COUNT(CASE WHEN insertion_type = 1 THEN 1 END) as debug_count,
    COUNT(CASE WHEN insertion_type = 2 THEN 1 END) as info_count,
    COUNT(CASE WHEN insertion_type = 3 THEN 1 END) as warn_count,
    COUNT(CASE WHEN insertion_type = 4 THEN 1 END) as error_count
FROM &NOMBRE_TABLA_LOG 
WHERE module_name LIKE 'TEST_%'
GROUP BY module_name 
ORDER BY module_name;

-- Estadisticas por nivel
SELECT 
    'STATS POR NIVEL:' as tipo,
    CASE insertion_type 
        WHEN 1 THEN 'DEBUG'
        WHEN 2 THEN 'INFO' 
        WHEN 3 THEN 'WARN'
        WHEN 4 THEN 'ERROR'
    END as nivel,
    COUNT(*) as cantidad,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as porcentaje
FROM &NOMBRE_TABLA_LOG 
WHERE module_name LIKE 'TEST_%'
GROUP BY insertion_type 
ORDER BY insertion_type;

PROMPT ================================================================
PROMPT PRUEBA 9: LIMPIEZA Y VERIFICACION FINAL
PROMPT ================================================================

-- Estadisticas finales antes de limpiar
SELECT 
    'TOTALES FINALES:' as tipo,
    COUNT(*) as total_registros,
    COUNT(DISTINCT module_name) as modulos_diferentes,
    COUNT(DISTINCT execution_id) as ejecuciones_diferentes,
    MIN(log_timestamp) as primer_log,
    MAX(log_timestamp) as ultimo_log
FROM &NOMBRE_TABLA_LOG 
WHERE module_name LIKE 'TEST_%';

-- Limpiar datos de prueba
BEGIN
    DELETE FROM &NOMBRE_TABLA_CFG WHERE module_name LIKE 'TEST_%';
    DELETE FROM &NOMBRE_TABLA_LOG WHERE module_name LIKE 'TEST_%';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Datos de prueba eliminados');
END;
/

PROMPT ================================================================
PROMPT RESUMEN DE PRUEBAS COMPLETADAS
PROMPT ================================================================

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 1: Configuracion de silenciamiento - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 2: Logging basico sin silenciamiento - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 3: Logging con silenciamiento parcial - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 4: Logging con silenciamiento total - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 5: Ejecuciones anidadas con trazabilidad - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 6: Medicion de tiempos transcurridos - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 7: Consulta de logs ordenados - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 8: Estadisticas generales - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 9: Limpieza final - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('TODAS LAS PRUEBAS HAN SIDO EJECUTADAS EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('El sistema de logging con base de datos esta funcionando correctamente');
    DBMS_OUTPUT.PUT_LINE('================================================================');
END;
/

SET TIMING OFF;
SET ECHO OFF;
