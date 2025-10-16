-- Especificación del paquete de logging (común para ambas implementaciones)
CREATE OR REPLACE PACKAGE &NOMBRE_PAQUETE AS
    FUNCTION start_execution(p_module_name VARCHAR2, p_ancestor_execution_id VARCHAR2 DEFAULT NULL) RETURN VARCHAR2;
    PROCEDURE end_execution;

    FUNCTION get_ancestor_execution RETURN VARCHAR2;
    FUNCTION get_parent_execution_id RETURN VARCHAR2;

    PROCEDURE log_debug(p_log_message VARCHAR2);
    PROCEDURE log_info(p_log_message VARCHAR2);
    PROCEDURE log_warn(p_log_message VARCHAR2);
    PROCEDURE log_error(p_error_code VARCHAR2, p_error_message VARCHAR2);
END;
/