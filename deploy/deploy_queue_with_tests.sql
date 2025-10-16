-- ================================================================
-- DEPLOY SCRIPT: QUEUE LOGGER CON PRUEBAS INCLUIDAS
-- ================================================================
-- Descripcion: Script de despliegue completo para la implementacion
--              de logging con colas Oracle AQ con suite de pruebas
-- Componentes: Sistema completo + scripts de pruebas
-- ================================================================

-- Configuracion especifica para implementacion de colas
@src/config/config_queue.sql

-- Tablas de configuracion
@src/tables/config_table.sql
@src/tables/queue_config_table.sql

-- Objetos de Oracle Advanced Queuing
@src/queues/queue_table.sql
@src/queues/queue_definition.sql
@src/queues/queue_grants.sql

-- Paquete de implementacion (incluye especificacion)
@src/packages/pkg_logger_spec.sql
@src/packages/pkg_logger_queue.sql

-- Scripts de pruebas
@tests/test_queue_simple.sql
@tests/test_queue_logger.sql