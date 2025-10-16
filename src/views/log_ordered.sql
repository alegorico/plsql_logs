
-- Vista ordenada
CREATE OR REPLACE VIEW vw_&NOMBRE_TABLA_LOG._ordered AS
    SELECT
        execution_id,
        session_id,
        ancestor_execution_id,
        user_name,
        module_name,
        log_timestamp,
        insertion_type,
        log_message,
        error_code,
        error_message
    FROM
        &NOMBRE_TABLA_LOG
    ORDER BY
        execution_id,
        session_id,
        log_timestamp,
        insertion_type;
/
 