-- ================================================================
-- DEPLOY SCRIPT: SOLO PRUEBAS PARA DATABASE LOGGER
-- ================================================================
-- Descripcion: Script que incluye solo las pruebas para el sistema
--              de logging de base de datos (sistema ya instalado)
-- Prerequisitos: Sistema de logging ya desplegado
-- ================================================================

-- Configuracion para que las pruebas usen las variables correctas
@src/config/config_database.sql

-- Scripts de pruebas para base de datos
@tests/test_database_simple.sql
@tests/test_database_logger.sql