-- ================================================================
-- SCRIPT CONSOLIDADO DE LIMPIEZA PARA LOGGER DE BASE DE DATOS
-- ================================================================
-- Archivo generado automaticamente por mergeSourceFile
-- NO EDITAR MANUALMENTE - Regenerar desde fuentes
-- ================================================================

-- Configuracion comun
DEFINE ESQUEMA_PROPIETARIO = "CURRENT_SCHEMA";
DEFINE PREFIJO_TABLAS = "logs_";
DEFINE PREFIJO_PAQUETES = "zpkg_";

-- Configuracion especifica de base de datos
DEFINE NOMBRE_TABLA_LOG = "&PREFIJO_TABLAS.execution";
DEFINE NOMBRE_TABLA_CFG = "cfg_logger_silence";
DEFINE NOMBRE_PAQUETE = "&PREFIJO_PAQUETES.logger";

-- ================================================================
-- SCRIPT DE LIMPIEZA PARA LOGGER DE BASE DE DATOS
-- ================================================================
-- Descripcion: Elimina todos los objetos creados por el sistema
--              de logging de base de datos
-- ATENCION: Este script eliminara permanentemente todos los datos
-- ================================================================

SET ECHO ON;
SET FEEDBACK ON;

PROMPT ================================================================
PROMPT INICIANDO LIMPIEZA DEL SISTEMA LOGGER DE BASE DE DATOS
PROMPT ATENCION: Se eliminaran todos los objetos y datos
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

-- Eliminar vistas
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_&NOMBRE_TABLA_LOG._elapsed';
    DBMS_OUTPUT.PUT_LINE('✓ Vista vw_&NOMBRE_TABLA_LOG._elapsed eliminada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Vista vw_&NOMBRE_TABLA_LOG._elapsed no encontrada');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_&NOMBRE_TABLA_LOG._ordered';
    DBMS_OUTPUT.PUT_LINE('✓ Vista vw_&NOMBRE_TABLA_LOG._ordered eliminada');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Vista vw_&NOMBRE_TABLA_LOG._ordered no encontrada');
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

-- Eliminar tablas (los datos se perderan permanentemente)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE &NOMBRE_TABLA_LOG';
    DBMS_OUTPUT.PUT_LINE('✓ Tabla &NOMBRE_TABLA_LOG eliminada (DATOS PERDIDOS)');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('! Tabla &NOMBRE_TABLA_LOG no encontrada');
END;
/

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
   OR object_name LIKE '%' || REPLACE('&NOMBRE_TABLA_LOG', 'logs_', '') || '%'
   OR object_name LIKE '%' || REPLACE('&NOMBRE_TABLA_CFG', 'cfg_', '') || '%'
GROUP BY object_type
ORDER BY object_type;

PROMPT ================================================================
PROMPT LIMPIEZA DE BASE DE DATOS COMPLETADA
PROMPT Si aparecen objetos restantes arriba, pueden requerir
PROMPT eliminacion manual o pertenecer a otros sistemas
PROMPT ================================================================