-- ================================================================
-- MONITOR DE COLA DE LOGGING EN TIEMPO REAL
-- ================================================================
-- Descripcion: Script para monitorear mensajes en la cola de logging
-- Uso: Ejecutar en una sesion separada mientras se hacen pruebas
-- ================================================================

SET PAGESIZE 50;
SET LINESIZE 120;
SET SERVEROUTPUT ON;

PROMPT ================================================================
PROMPT MONITOR DE COLA DE LOGGING - queue_log_logger
PROMPT Presiona Ctrl+C para salir
PROMPT ================================================================

-- Loop infinito para monitoreo continuo
DECLARE
    v_count NUMBER;
    v_last_count NUMBER := -1;
BEGIN
    LOOP
        -- Contar mensajes actuales
        SELECT COUNT(*) INTO v_count FROM qt_log_logger;
        
        -- Solo mostrar si hay cambios
        IF v_count != v_last_count THEN
            DBMS_OUTPUT.PUT_LINE(TO_CHAR(SYSDATE, 'DD/MM/YY HH24:MI:SS') || 
                               ' - Mensajes en cola: ' || v_count);
            v_last_count := v_count;
        END IF;
        
        -- Esperar 2 segundos
        DBMS_LOCK.SLEEP(2);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Monitor detenido: ' || SQLERRM);
END;
/

-- Consultas adicionales utiles para debugging

PROMPT ================================================================
PROMPT CONSULTAS UTILES PARA DEBUGGING DE COLAS
PROMPT ================================================================

-- Estado actual de la cola
SELECT 
    'Estado actual de la cola:' as info,
    name as cola_nombre,
    enqueue_enabled,
    dequeue_enabled,
    retention_time,
    max_retries
FROM user_queues 
WHERE name = 'QUEUE_LOG_logger';

-- Mensajes por nivel de prioridad
SELECT 
    'Mensajes por nivel:' as info,
    priority as nivel,
    CASE priority 
        WHEN 1 THEN 'DEBUG'
        WHEN 2 THEN 'INFO' 
        WHEN 3 THEN 'WARN'
        WHEN 4 THEN 'ERROR'
        ELSE 'UNKNOWN'
    END as nivel_texto,
    COUNT(*) as cantidad
FROM qt_log_logger 
GROUP BY priority 
ORDER BY priority;

-- Ultimos 5 mensajes
SELECT 
    'Ultimos mensajes:' as info,
    TO_CHAR(enq_time, 'DD/MM HH24:MI:SS') as fecha,
    priority as nivel,
    state as estado,
    SUBSTR(user_data.text_vc, 1, 60) as mensaje_preview
FROM (
    SELECT * FROM qt_log_logger 
    ORDER BY enq_time DESC
) 
WHERE rownum <= 5;

-- Configuracion de modulos con cola habilitada
SELECT 
    'Modulos con cola habilitada:' as info,
    module_name,
    queue_enabled,
    queue_name
FROM cfg_log_queue_logger 
WHERE queue_enabled = 1;

PROMPT ================================================================
PROMPT Para usar el monitor, ejecuta:
PROMPT @test_queue_monitor.sql
PROMPT ================================================================
