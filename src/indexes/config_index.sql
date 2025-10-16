
-- Indice unico para garantizar unicidad de modulo y nivel (insensible a mayusculas y espacios)
CREATE UNIQUE INDEX uq_upper_&NOMBRE_TABLA_CFG ON &NOMBRE_TABLA_CFG (module_name_upper, insertion_type);
/
