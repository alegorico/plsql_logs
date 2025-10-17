-- ================================================================
-- SCRIPT DE PRUEBAS RAPIDAS PARA LOGGER CON BASE DE DATOS
-- ================================================================
-- Descripcion: Pruebas basicas y rapidas para validar funcionamiento
-- Uso: sqlplus usuario/password @test_database_simple.sql
-- ================================================================

SET SERVEROUTPUT ON;

PROMPT === PRUEBA RAPIDA DE LOGGER CON BASE DE DATOS ===

-- Limpiar datos previos
DELETE FROM &NOMBRE_TABLA_LOG WHERE module_name = 'QUICK_TEST';
COMMIT;

-- Ejecutar logging de prueba
DECLARE
    v_execution_id VARCHAR2(32);
BEGIN
    -- Iniciar ejecucion
    v_execution_id := &NOMBRE_PAQUETE.start_execution('QUICK_TEST');
    DBMS_OUTPUT.PUT_LINE('Execution ID: ' || v_execution_id);
    
    -- Generar logs de prueba
    &NOMBRE_PAQUETE.log_info('Prueba rapida - mensaje INFO');
    &NOMBRE_PAQUETE.log_warn('Prueba rapida - mensaje WARNING');
    &NOMBRE_PAQUETE.log_error('TEST001', 'Prueba rapida - mensaje ERROR');
    
    -- Finalizar
    &NOMBRE_PAQUETE.end_execution();
    DBMS_OUTPUT.PUT_LINE('Prueba completada');
END;
/

-- Verificar registros en tabla
SELECT COUNT(*) as "Registros en Tabla" FROM &NOMBRE_TABLA_LOG;

-- Ver ultimo registro
SELECT 
    TO_CHAR(log_timestamp, 'DD/MM HH24:MI:SS') as "Fecha",
    CASE insertion_type 
        WHEN 1 THEN 'DEBUG'
        WHEN 2 THEN 'INFO' 
        WHEN 3 THEN 'WARN'
        WHEN 4 THEN 'ERROR'
    END as "Nivel",
    SUBSTR(log_message, 1, 50) as "Mensaje"
FROM &NOMBRE_TABLA_LOG 
WHERE log_timestamp = (SELECT MAX(log_timestamp) FROM &NOMBRE_TABLA_LOG);

-- Limpiar
DELETE FROM &NOMBRE_TABLA_LOG WHERE module_name = 'QUICK_TEST';
COMMIT;

PROMPT === PRUEBA COMPLETADA ===