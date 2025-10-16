-- Creación idempotente de la tabla de logs
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE &NOMBRE_TABLA_LOG';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE &NOMBRE_TABLA_LOG (
    execution_id          VARCHAR2(100),
    ancestor_execution_id VARCHAR2(100),
    session_id            VARCHAR2(100),
    user_name             VARCHAR2(100),
    module_name           VARCHAR2(100),
    log_timestamp         TIMESTAMP DEFAULT SYSTIMESTAMP,
    insertion_type        VARCHAR2(20),
    log_message           VARCHAR2(4000),
    error_code            VARCHAR2(50),
    error_message         VARCHAR2(4000)
);
