-- Creacion idempotente de la tabla de configuracion para colas
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE &NOMBRE_TABLA_QUEUE_CFG';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE &NOMBRE_TABLA_QUEUE_CFG (
    module_name      VARCHAR2(100) NOT NULL,
    queue_enabled    NUMBER(1) DEFAULT 1,
    queue_name       VARCHAR2(100) DEFAULT '&NOMBRE_COLA_JMS',
    module_name_upper VARCHAR2(100) GENERATED ALWAYS AS (UPPER(TRIM(module_name))) VIRTUAL
);

-- Indice unico para la tabla de configuracion de colas
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX uq_upper_&NOMBRE_TABLA_QUEUE_CFG';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE UNIQUE INDEX uq_upper_&NOMBRE_TABLA_QUEUE_CFG ON &NOMBRE_TABLA_QUEUE_CFG (module_name_upper);