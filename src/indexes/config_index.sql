
-- Creacion idempotente del indice unico para garantizar unicidad de modulo y nivel
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX uq_upper_&NOMBRE_TABLA_CFG';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE UNIQUE INDEX uq_upper_&NOMBRE_TABLA_CFG ON &NOMBRE_TABLA_CFG (module_name_upper, insertion_type);

