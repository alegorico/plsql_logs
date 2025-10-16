
-- Vista con tiempo transcurrido desde el registro anterior
CREATE OR REPLACE VIEW vw_&NOMBRE_TABLA_LOG._elapsed AS
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
        error_message,
        EXTRACT(
            SECOND FROM (log_timestamp -
                LAG(log_timestamp) OVER (
                    PARTITION BY execution_id, session_id
                    ORDER BY log_timestamp
                )
            )
        )
        + 60*EXTRACT(
            MINUTE FROM (log_timestamp -
                LAG(log_timestamp) OVER (
                    PARTITION BY execution_id, session_id
                    ORDER BY log_timestamp
                )
            )
        )
        + 3600*EXTRACT(
            HOUR FROM (log_timestamp -
                LAG(log_timestamp) OVER (
                    PARTITION BY execution_id, session_id
                    ORDER BY log_timestamp
                )
            )
        )
        AS elapsed_seconds_since_prev
    FROM
        &NOMBRE_TABLA_LOG
    ORDER BY
        execution_id,
        session_id,
        log_timestamp,
        insertion_type;
