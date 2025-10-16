-- ================================================================
-- DEPLOY SCRIPT: QUEUE LOGGER IMPLEMENTATION  
-- ================================================================
-- Descripcion: Script de despliegue completo para la implementacion
--              de logging basada en Oracle Advanced Queuing (JMS)
-- Arquitectura: Almacenamiento en colas AQ para integracion externa
-- Componentes: Tablas config, colas AQ, grants y paquete queue
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