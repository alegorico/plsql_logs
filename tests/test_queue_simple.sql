-- ================================================================
-- SCRIPT DE PRUEBAS RAPIDAS PARA LOGGER CON COLAS
-- ================================================================
-- Descripcion: Pruebas basicas y rapidas para validar funcionamiento
-- Uso: sqlplus usuario/password @test_queue_simple.sql
-- ================================================================

SET SERVEROUTPUT ON;

PROMPT === PRUEBA RAPIDA DE LOGGER CON COLAS ===

-- Configurar un modulo de prueba
INSERT INTO cfg_log_queue_logger (module_name, queue_enabled, queue_name) 
VALUES ('QUICK_TEST', 1, 'queue_log_logger');
COMMIT;

-- Ejecutar logging de prueba
DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    -- Iniciar ejecucion
    v_execution_id := zpkg_logger_logger.start_execution('QUICK_TEST');
    DBMS_OUTPUT.PUT_LINE('Execution ID: ' || v_execution_id);
    
    -- Generar logs de prueba
    zpkg_logger_logger.log_info('Prueba rapida - mensaje INFO');
    zpkg_logger_logger.log_warn('Prueba rapida - mensaje WARNING');
    zpkg_logger_logger.log_error('TEST001', 'Prueba rapida - mensaje ERROR');
    
    -- Finalizar
    zpkg_logger_logger.end_execution();
    DBMS_OUTPUT.PUT_LINE('Prueba completada');
END;
/

-- Verificar mensajes en cola
SELECT COUNT(*) as "Mensajes en Cola" FROM qt_log_logger;

-- Ver ultimo mensaje
SELECT 
    TO_CHAR(enq_time, 'DD/MM HH24:MI:SS') as "Fecha",
    priority as "Nivel",
    SUBSTR(user_data.text_vc, 1, 80) as "Mensaje JSON"
FROM qt_log_logger 
WHERE enq_time = (SELECT MAX(enq_time) FROM qt_log_logger);

-- Limpiar
DELETE FROM cfg_log_queue_logger WHERE module_name = 'QUICK_TEST';
COMMIT;

PROMPT === PRUEBA COMPLETADA ===
