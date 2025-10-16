
-- Configuracion especifica para implementacion de BD
@src/config/config_common.sql

-- Objetos de base de datos
@src/tables/log_table.sql
@src/tables/config_table.sql

-- Indices para optimizacion
@src/indexes/config_index.sql

-- Vistas para consultas
@src/views/log_elapsed.sql
@src/views/log_ordered.sql

-- Paquete de implementacion (incluye especificacion)
@src/packages/pkg_logger.sql
