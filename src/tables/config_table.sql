-- Creacion idempotente de la tabla de configuracion para silenciar logs
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE &NOMBRE_TABLA_CFG';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE &NOMBRE_TABLA_CFG (
    module_name      VARCHAR2(100) NOT NULL,
    insertion_type   NUMBER,            -- NULL = silenciar todo el modulo
    module_name_upper VARCHAR2(100) GENERATED ALWAYS AS (UPPER(TRIM(module_name))) VIRTUAL
);
