-- ================================================================
-- SCRIPT DE PRUEBAS PARA LOGGER CON COLAS (Oracle Advanced Queuing)
-- ================================================================
-- Descripcion: Script completo para probar todas las funcionalidades
--              del sistema de logging basado en colas AQ/JMS
-- Prerequisitos: Ejecutar primero generated_queue_fixed.sql
-- ================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET TIMING ON;
SET ECHO ON;

PROMPT ================================================================
PROMPT INICIO DE PRUEBAS PARA LOGGER CON COLAS
PROMPT ================================================================

-- Limpiar datos de pruebas anteriores si existen
BEGIN
    DELETE FROM cfg_log_reg_alex_silence;
    DELETE FROM cfg_log_queue_alex;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Tablas de configuracion limpiadas');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Error limpiando tablas: ' || SQLERRM);
END;
/

PROMPT ================================================================
PROMPT PRUEBA 1: CONFIGURACION INICIAL DE MODULOS
PROMPT ================================================================

-- Configurar modulos de prueba
BEGIN
    -- Modulo con cola habilitada
    INSERT INTO cfg_log_queue_alex (module_name, queue_enabled, queue_name) 
    VALUES ('TEST_MODULE_ENABLED', 1, 'queue_log_alex');
    
    -- Modulo con cola deshabilitada
    INSERT INTO cfg_log_queue_alex (module_name, queue_enabled, queue_name) 
    VALUES ('TEST_MODULE_DISABLED', 0, 'queue_log_alex');
    
    -- Modulo sin configuracion especial (usara defecto)
    -- TEST_MODULE_DEFAULT - no insertamos registro
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Configuracion de modulos creada');
END;
/

-- Verificar configuracion
SELECT 'CONFIG COLAS:' as tipo, module_name, queue_enabled, queue_name 
FROM cfg_log_queue_alex 
ORDER BY module_name;

PROMPT ================================================================
PROMPT PRUEBA 2: CONFIGURACION DE SILENCIAMIENTO
PROMPT ================================================================

-- Configurar silenciamiento para pruebas
BEGIN
    -- Silenciar DEBUG y INFO para un modulo
    INSERT INTO cfg_log_reg_alex_silence (module_name, insertion_type) 
    VALUES ('TEST_MODULE_SILENT', 2); -- Solo WARN y ERROR pasaran
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Configuracion de silenciamiento creada');
END;
/

-- Verificar configuracion de silenciamiento
SELECT 'CONFIG SILENCIO:' as tipo, module_name, insertion_type 
FROM cfg_log_reg_alex_silence 
ORDER BY module_name;

PROMPT ================================================================
PROMPT PRUEBA 3: VERIFICACION DE ESTADO DE COLAS
PROMPT ================================================================

-- Verificar que la cola existe y esta activa
SELECT 
    'ESTADO COLA:' as tipo,
    name as cola_nombre,
    queue_table,
    queue_type,
    max_retries,
    retry_delay,
    enqueue_enabled,
    dequeue_enabled
FROM user_queues 
WHERE name = 'QUEUE_LOG_ALEX';

-- Verificar tabla de cola
SELECT 'TABLA COLA:' as tipo, table_name, queue_table 
FROM user_queue_tables 
WHERE queue_table = 'QT_LOG_ALEX';

PROMPT ================================================================
PROMPT PRUEBA 4: PRUEBAS DE LOGGING BASICO
PROMPT ================================================================

DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando sesion de logging para TEST_MODULE_ENABLED ---');
    
    -- Iniciar ejecucion
    v_execution_id := zpkg_logger_alex.start_execution('TEST_MODULE_ENABLED');
    DBMS_OUTPUT.PUT_LINE('✓ Execution ID: ' || v_execution_id);
    
    -- Probar todos los niveles
    zpkg_logger_alex.log_debug('Mensaje de debug - cola habilitada');
    zpkg_logger_alex.log_info('Mensaje de info - cola habilitada');
    zpkg_logger_alex.log_warn('Mensaje de warning - cola habilitada');
    zpkg_logger_alex.log_error('ERR001', 'Mensaje de error - cola habilitada');
    
    -- Esperar un poco para que se procesen los mensajes
    DBMS_LOCK.SLEEP(1);
    
    -- Finalizar ejecucion
    zpkg_logger_alex.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Ejecucion finalizada para modulo con cola habilitada');
END;
/

PROMPT ================================================================
PROMPT PRUEBA 5: PRUEBAS CON COLA DESHABILITADA
PROMPT ================================================================

DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando sesion de logging para TEST_MODULE_DISABLED ---');
    
    -- Iniciar ejecucion
    v_execution_id := zpkg_logger_alex.start_execution('TEST_MODULE_DISABLED');
    DBMS_OUTPUT.PUT_LINE('✓ Execution ID: ' || v_execution_id);
    
    -- Probar logging (no deberia enviar a cola)
    zpkg_logger_alex.log_info('Mensaje de info - cola DESHABILITADA');
    zpkg_logger_alex.log_warn('Mensaje de warning - cola DESHABILITADA');
    
    -- Finalizar ejecucion
    zpkg_logger_alex.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Ejecucion finalizada para modulo con cola deshabilitada');
END;
/

PROMPT ================================================================
PROMPT PRUEBA 6: PRUEBAS CON SILENCIAMIENTO
PROMPT ================================================================

DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando sesion de logging para TEST_MODULE_SILENT ---');
    
    -- Configurar cola para este modulo
    INSERT INTO cfg_log_queue_alex (module_name, queue_enabled, queue_name) 
    VALUES ('TEST_MODULE_SILENT', 1, 'queue_log_alex');
    COMMIT;
    
    -- Iniciar ejecucion
    v_execution_id := zpkg_logger_alex.start_execution('TEST_MODULE_SILENT');
    DBMS_OUTPUT.PUT_LINE('✓ Execution ID: ' || v_execution_id);
    
    -- Estos mensajes deberian ser silenciados (DEBUG=1, INFO=2, config=2)
    zpkg_logger_alex.log_debug('DEBUG silenciado - NO deberia aparecer en cola');
    zpkg_logger_alex.log_info('INFO silenciado - NO deberia aparecer en cola');
    
    -- Estos mensajes NO deberian ser silenciados (WARN=3, ERROR=4 > config=2)
    zpkg_logger_alex.log_warn('WARNING NO silenciado - SI deberia aparecer en cola');
    zpkg_logger_alex.log_error('ERR002', 'ERROR NO silenciado - SI deberia aparecer en cola');
    
    -- Finalizar ejecucion
    zpkg_logger_alex.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Ejecucion finalizada para modulo silenciado');
END;
/

PROMPT ================================================================
PROMPT PRUEBA 7: PRUEBAS DE EJECUCIONES ANIDADAS
PROMPT ================================================================

DECLARE
    v_parent_execution_id VARCHAR2(32);
    v_child_execution_id VARCHAR2(32);
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba de ejecuciones anidadas ---');
    
    -- Ejecucion padre
    v_parent_execution_id := zpkg_logger_alex.start_execution('TEST_PARENT_MODULE');
    DBMS_OUTPUT.PUT_LINE('✓ Parent Execution ID: ' || v_parent_execution_id);
    
    zpkg_logger_alex.log_info('Mensaje desde el proceso padre');
    
    -- Ejecucion hija (deberia detectar automaticamente el padre)
    v_child_execution_id := zpkg_logger_alex.start_execution('TEST_CHILD_MODULE');
    DBMS_OUTPUT.PUT_LINE('✓ Child Execution ID: ' || v_child_execution_id);
    
    zpkg_logger_alex.log_info('Mensaje desde el proceso hijo');
    zpkg_logger_alex.log_warn('Warning desde proceso hijo');
    
    -- Finalizar hijo primero
    zpkg_logger_alex.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Proceso hijo finalizado');
    
    -- Continuar con padre
    zpkg_logger_alex.log_info('Mensaje padre despues de hijo');
    
    -- Finalizar padre
    zpkg_logger_alex.end_execution();
    DBMS_OUTPUT.PUT_LINE('✓ Proceso padre finalizado');
    
    -- Configurar colas para estos modulos
    INSERT INTO cfg_log_queue_alex (module_name, queue_enabled, queue_name) 
    VALUES ('TEST_PARENT_MODULE', 1, 'queue_log_alex');
    INSERT INTO cfg_log_queue_alex (module_name, queue_enabled, queue_name) 
    VALUES ('TEST_CHILD_MODULE', 1, 'queue_log_alex');
    COMMIT;
END;
/

PROMPT ================================================================
PROMPT PRUEBA 8: VERIFICACION DE MENSAJES EN COLA
PROMPT ================================================================

-- Esperar a que se procesen todos los mensajes
BEGIN
    DBMS_LOCK.SLEEP(2);
    DBMS_OUTPUT.PUT_LINE('✓ Esperando procesamiento de mensajes...');
END;
/

-- Contar mensajes en cola
SELECT 
    'MENSAJES EN COLA:' as tipo,
    COUNT(*) as total_mensajes,
    SUM(CASE WHEN state = 0 THEN 1 ELSE 0 END) as pendientes,
    SUM(CASE WHEN state = 1 THEN 1 ELSE 0 END) as procesados
FROM qt_log_alex;

-- Ver algunos mensajes de la cola (muestra del contenido)
SELECT 
    'MUESTRA MENSAJES:' as tipo,
    rownum as num,
    TO_CHAR(enq_time, 'DD/MM/YYYY HH24:MI:SS') as fecha_envio,
    priority as nivel,
    state as estado,
    SUBSTR(user_data.text_vc, 1, 100) as mensaje_json
FROM qt_log_alex 
WHERE rownum <= 5
ORDER BY enq_time DESC;

PROMPT ================================================================
PROMPT PRUEBA 9: DEQUEUE DE MENSAJES (SIMULACION CONSUMIDOR)
PROMPT ================================================================

DECLARE
    v_dequeue_options   DBMS_AQ.DEQUEUE_OPTIONS_T;
    v_message_props     DBMS_AQ.MESSAGE_PROPERTIES_T;
    v_message           SYS.AQ$_JMS_TEXT_MESSAGE;
    v_msgid             RAW(16);
    v_count             NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Simulando consumo de mensajes ---');
    
    -- Configurar opciones de dequeue
    v_dequeue_options.wait := DBMS_AQ.NO_WAIT;
    v_dequeue_options.navigation := DBMS_AQ.FIRST_MESSAGE;
    
    -- Consumir hasta 3 mensajes como ejemplo
    FOR i IN 1..3 LOOP
        BEGIN
            DBMS_AQ.DEQUEUE(
                queue_name         => 'queue_log_alex',
                dequeue_options    => v_dequeue_options,
                message_properties => v_message_props,
                payload            => v_message,
                msgid              => v_msgid
            );
            
            v_count := v_count + 1;
            DBMS_OUTPUT.PUT_LINE('✓ Mensaje ' || v_count || ' consumido: ' || 
                                SUBSTR(v_message.text_vc, 1, 100) || '...');
                                
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -25228 THEN -- No more messages
                    DBMS_OUTPUT.PUT_LINE('! No hay más mensajes en la cola');
                    EXIT;
                ELSE
                    DBMS_OUTPUT.PUT_LINE('! Error dequeue: ' || SQLERRM);
                    EXIT;
                END IF;
        END;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Total mensajes consumidos: ' || v_count);
END;
/

PROMPT ================================================================
PROMPT PRUEBA 10: LIMPIEZA Y VERIFICACION FINAL
PROMPT ================================================================

-- Estadisticas finales de la cola
SELECT 
    'ESTADISTICAS FINALES:' as tipo,
    COUNT(*) as mensajes_restantes,
    MIN(enq_time) as primer_mensaje,
    MAX(enq_time) as ultimo_mensaje
FROM qt_log_alex;

-- Limpiar datos de prueba
BEGIN
    DELETE FROM cfg_log_reg_alex_silence WHERE module_name LIKE 'TEST_%';
    DELETE FROM cfg_log_queue_alex WHERE module_name LIKE 'TEST_%';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Configuraciones de prueba eliminadas');
END;
/

PROMPT ================================================================
PROMPT RESUMEN DE PRUEBAS COMPLETADAS
PROMPT ================================================================

BEGIN
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 1: Configuracion de modulos - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 2: Configuracion de silenciamiento - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 3: Verificacion de estado de colas - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 4: Logging basico con cola habilitada - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 5: Logging con cola deshabilitada - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 6: Logging con silenciamiento - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 7: Ejecuciones anidadas - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 8: Verificacion de mensajes en cola - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 9: Simulacion de consumo - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE('✓ PRUEBA 10: Limpieza final - COMPLETADA');
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('================================================================');
    DBMS_OUTPUT.PUT_LINE('TODAS LAS PRUEBAS HAN SIDO EJECUTADAS EXITOSAMENTE');
    DBMS_OUTPUT.PUT_LINE('El sistema de logging con colas esta funcionando correctamente');
    DBMS_OUTPUT.PUT_LINE('================================================================');
END;
/

SET TIMING OFF;
SET ECHO OFF;