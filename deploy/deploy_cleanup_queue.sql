-- ================================================================
-- DEPLOY DE LIMPIEZA PARA LOGGER CON COLA JMS
-- ================================================================
-- Descripcion: Script de deploy que incluye configuracion y
--              ejecuta la limpieza del sistema con cola JMS
-- Uso: @deploy_cleanup_queue.sql
-- ================================================================

SET ECHO ON;
SET FEEDBACK ON;
SET VERIFY OFF;

PROMPT ================================================================
PROMPT DEPLOY DE LIMPIEZA - SISTEMA LOGGER CON COLA JMS
PROMPT ================================================================

-- Cargar configuracion comun
@@src/config/config_common.sql

-- Cargar configuracion especifica de cola
@@src/config/config_queue.sql

-- Confirmar configuracion antes de eliminar
PROMPT Configuracion cargada:
PROMPT - Paquete: &NOMBRE_PAQUETE
PROMPT - Cola: &NOMBRE_COLA_LOG
PROMPT - Tabla de cola: &NOMBRE_TABLA_COLA
PROMPT - Tipo de mensaje: &TIPO_MENSAJE_LOG
PROMPT - Tabla de config: &NOMBRE_TABLA_CFG

PROMPT ================================================================
PROMPT ATENCION: SE ELIMINARAN TODOS LOS OBJETOS, DATOS Y MENSAJES
PROMPT Presiona ENTER para continuar o Ctrl+C para cancelar
PROMPT ================================================================
PAUSE

-- Ejecutar limpieza
@@src/cleanup/cleanup_queue.sql

PROMPT ================================================================
PROMPT DEPLOY DE LIMPIEZA COMPLETADO
PROMPT ================================================================