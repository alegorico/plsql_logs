-- ================================================================
-- SCRIPT DE LIMPIEZA PARA LOGGER CON COLA JMS
-- ================================================================
-- Descripcion: Elimina todos los objetos creados por el sistema
--              de logging con cola JMS/AQ
-- ATENCION: Este script eliminara permanentemente todos los datos
--           y la cola de mensajes
-- ================================================================

SET ECHO ON;
SET FEEDBACK ON;

PROMPT ================================================================
PROMPT INICIANDO LIMPIEZA DEL SISTEMA LOGGER CON COLA JMS
PROMPT ATENCION: Se eliminaran todos los objetos, datos y mensajes
PROMPT ================================================================

-- Eliminar paquete
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE &NOMBRE_PAQUETE';
    DBMS_OUTPUT.PUT_LINE('✓ Paquete &NOMBRE_PAQUETE eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Paquete &NOMBRE_PAQUETE no encontrado o ya eliminado');
END;
/

-- Parar y eliminar la cola AQ
BEGIN
    DBMS_AQADM.STOP_QUEUE(queue_name => '&NOMBRE_COLA_LOG');
    DBMS_OUTPUT.PUT_LINE('✓ Cola &NOMBRE_COLA_LOG parada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Cola &NOMBRE_COLA_LOG ya estaba parada o no existe');
END;
/

BEGIN
    DBMS_AQADM.DROP_QUEUE(queue_name => '&NOMBRE_COLA_LOG');
    DBMS_OUTPUT.PUT_LINE('✓ Cola &NOMBRE_COLA_LOG eliminada (MENSAJES PERDIDOS)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Cola &NOMBRE_COLA_LOG no encontrada');
END;
/

-- Eliminar tabla de cola
BEGIN
    DBMS_AQADM.DROP_QUEUE_TABLE(queue_table => '&NOMBRE_TABLA_COLA');
    DBMS_OUTPUT.PUT_LINE('✓ Tabla de cola &NOMBRE_TABLA_COLA eliminada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Tabla de cola &NOMBRE_TABLA_COLA no encontrada');
END;
/

-- Eliminar tipo de objeto para mensajes
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE &TIPO_MENSAJE_LOG';
    DBMS_OUTPUT.PUT_LINE('✓ Tipo &TIPO_MENSAJE_LOG eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Tipo &TIPO_MENSAJE_LOG no encontrado');
END;
/

-- Eliminar vistas de monitoreo
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_&NOMBRE_COLA_LOG._status';
    DBMS_OUTPUT.PUT_LINE('✓ Vista vw_&NOMBRE_COLA_LOG._status eliminada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Vista vw_&NOMBRE_COLA_LOG._status no encontrada');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_&NOMBRE_COLA_LOG._messages';
    DBMS_OUTPUT.PUT_LINE('✓ Vista vw_&NOMBRE_COLA_LOG._messages eliminada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Vista vw_&NOMBRE_COLA_LOG._messages no encontrada');
END;
/

-- Eliminar indices
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX uq_upper_&NOMBRE_TABLA_CFG';
    DBMS_OUTPUT.PUT_LINE('✓ Indice uq_upper_&NOMBRE_TABLA_CFG eliminado');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Indice uq_upper_&NOMBRE_TABLA_CFG no encontrado');
END;
/

-- Eliminar tabla de configuracion
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE &NOMBRE_TABLA_CFG';
    DBMS_OUTPUT.PUT_LINE('✓ Tabla &NOMBRE_TABLA_CFG eliminada (CONFIGURACION PERDIDA)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Tabla &NOMBRE_TABLA_CFG no encontrada');
END;
/

-- Verificar limpieza
PROMPT ================================================================
PROMPT VERIFICANDO LIMPIEZA...
PROMPT ================================================================

-- Contar objetos restantes relacionados con el logger
SELECT 
    'OBJETOS RESTANTES:' as info,
    object_type,
    COUNT(*) as cantidad
FROM user_objects 
WHERE object_name LIKE '%' || REPLACE('&NOMBRE_PAQUETE', 'zpkg_', '') || '%'
   OR object_name LIKE '%' || REPLACE('&NOMBRE_COLA_LOG', 'log_', '') || '%'
   OR object_name LIKE '%' || REPLACE('&NOMBRE_TABLA_CFG', 'cfg_', '') || '%'
   OR object_name LIKE '%' || REPLACE('&TIPO_MENSAJE_LOG', 't_', '') || '%'
GROUP BY object_type
ORDER BY object_type;

-- Verificar colas AQ restantes
SELECT queue_name, queue_table 
FROM user_queues 
WHERE queue_name LIKE '%' || REPLACE('&NOMBRE_COLA_LOG', 'log_', '') || '%';

PROMPT ================================================================
PROMPT LIMPIEZA DE SISTEMA CON COLA JMS COMPLETADA
PROMPT Si aparecen objetos restantes arriba, pueden requerir
PROMPT eliminacion manual o pertenecer a otros sistemas
PROMPT ================================================================