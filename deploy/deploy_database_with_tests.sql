-- ================================================================
-- DEPLOY SCRIPT: DATABASE LOGGER CON PRUEBAS INCLUIDAS
-- ================================================================
-- Descripcion: Script de despliegue completo para la implementacion
--              de logging de base de datos con suite de pruebas
-- Componentes: Sistema completo + scripts de pruebas
-- ================================================================

-- Configuracion especifica para implementacion de BD
@src/config/config_database.sql

-- Objetos de base de datos
@src/tables/log_table.sql
@src/tables/config_table.sql

-- Indices para optimizacion
@src/indexes/config_index.sql

-- Vistas para consultas
@src/views/log_elapsed.sql
@src/views/log_ordered.sql

-- Paquete de implementacion (incluye especificacion)
@src/packages/pkg_logger_spec.sql
@src/packages/pkg_logger_database.sql

-- Scripts de pruebas
@tests/test_database_simple.sql
@tests/test_database_logger.sql