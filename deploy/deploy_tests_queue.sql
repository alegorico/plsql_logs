-- ================================================================
-- DEPLOY SCRIPT: SOLO PRUEBAS PARA QUEUE LOGGER
-- ================================================================
-- Descripcion: Script que incluye solo las pruebas para el sistema
--              de logging con colas (sistema ya instalado)
-- Prerequisitos: Sistema de logging ya desplegado
-- ================================================================

-- Configuracion para que las pruebas usen las variables correctas
@src/config/config_queue.sql

-- Scripts de pruebas para colas
@tests/test_queue_simple.sql
@tests/test_queue_logger.sql