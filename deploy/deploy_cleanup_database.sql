-- ================================================================
-- DEPLOY DE LIMPIEZA PARA LOGGER DE BASE DE DATOS
-- ================================================================
-- Descripcion: Script de deploy que incluye configuracion y
--              ejecuta la limpieza del sistema de base de datos
-- Uso: @deploy_cleanup_database.sql
-- ================================================================

SET ECHO ON;
SET FEEDBACK ON;
SET VERIFY OFF;

PROMPT ================================================================
PROMPT DEPLOY DE LIMPIEZA - SISTEMA LOGGER DE BASE DE DATOS
PROMPT ================================================================

-- Cargar configuracion comun
@@src/config/config_common.sql

-- Cargar configuracion especifica de base de datos
@@src/config/config_database.sql

-- Confirmar configuracion antes de eliminar
PROMPT Configuracion cargada:
PROMPT - Paquete: &NOMBRE_PAQUETE
PROMPT - Tabla de logs: &NOMBRE_TABLA_LOG
PROMPT - Tabla de config: &NOMBRE_TABLA_CFG

PROMPT ================================================================
PROMPT ATENCION: SE ELIMINARAN TODOS LOS OBJETOS Y DATOS
PROMPT Presiona ENTER para continuar o Ctrl+C para cancelar
PROMPT ================================================================
PAUSE

-- Ejecutar limpieza
@@src/cleanup/cleanup_database.sql

PROMPT ================================================================
PROMPT DEPLOY DE LIMPIEZA COMPLETADO
PROMPT ================================================================