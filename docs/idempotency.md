# Idempotencia en el Sistema de Logging

Este documento explica cómo el sistema de logging implementa idempotencia para permitir múltiples ejecuciones sin errores.

## Generación del Paquete

Este proyecto utiliza la herramienta [mergeSourceFile](https://github.com/alegorico/mergeSourceFile) para generar archivos consolidados desde los componentes modulares. Para mas informacion dirigirse a la documentacion del proyecto.

### Comando de Generación

Desde el directorio raíz del proyecto:

```bash
py merge --skip-var -i deploy\generate.sql -o generated.sql
```

**Parámetros:**
- `--skip-var`: Omite el procesamiento de variables
- `-i deploy\generate.sql`: Archivo de entrada (script principal)
- `-o generated.sql`: Archivo de salida consolidado

### Requisitos

1. **Python**: Instalado en el sistema
2. **mergeSourceFile**: Clonado desde GitHub
   ```bash
   git clone https://github.com/alegorico/mergeSourceFile.git
   ```
3. **Estructura modular**: Archivos organizados en `src/`

## ¿Qué es Idempotencia?

La idempotencia significa que ejecutar el mismo script múltiples veces produce el mismo resultado sin errores, incluso si los objetos ya existen.

## Estrategias Implementadas

### 1. **Tablas** - Estrategia DROP/CREATE

```sql
-- Patrón implementado para tablas
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE &NOMBRE_TABLA_LOG';
EXCEPTION
    WHEN OTHERS THEN NULL;  -- Ignora errores si no existe
END;
/

CREATE TABLE &NOMBRE_TABLA_LOG (...);
```

**Ventajas:**
- Simple y efectivo
- Garantiza estructura actualizada
- Limpia datos existentes

**Consideraciones:**
- ⚠️ **Destruye datos existentes**
- Usar solo en desarrollo/testing
- Para producción, considerar estrategias de migración

### 2. **Índices** - Estrategia DROP/CREATE

```sql
-- Patrón implementado para índices
BEGIN
    EXECUTE IMMEDIATE 'DROP INDEX uq_upper_&NOMBRE_TABLA_CFG';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE UNIQUE INDEX uq_upper_&NOMBRE_TABLA_CFG ON...;
```

### 3. **Vistas** - CREATE OR REPLACE

```sql
-- Ya idempotente por defecto
CREATE OR REPLACE VIEW vw_&NOMBRE_TABLA_LOG._elapsed AS...
```

### 4. **Paquetes** - CREATE OR REPLACE

```sql
-- Ya idempotente por defecto
CREATE OR REPLACE PACKAGE &NOMBRE_PAQUETE AS...
CREATE OR REPLACE PACKAGE BODY &NOMBRE_PAQUETE AS...
```

## Archivos Modificados

### Archivos con Idempotencia Implementada:
- ✅ `src/tables/log_table.sql` - Tabla de logs
- ✅ `src/tables/config_table.sql` - Tabla de configuración  
- ✅ `src/indexs/config_index.sql` - Índice único

### Archivos Ya Idempotentes:
- ✅ `src/views/log_elapsed.sql` - Vista con tiempos
- ✅ `src/views/log_ordered.sql` - Vista ordenada
- ✅ `src/packages/pkg_logger.sql` - Paquete principal

## Uso Seguro

### Para Desarrollo/Testing:
```sql
-- Ejecución segura múltiples veces
@deploy/generate.sql
```

### Para Producción:
1. **Primera instalación**: Usar scripts normalmente
2. **Actualizaciones**: Considerar scripts de migración específicos
3. **Rollback**: Implementar scripts de reversión

## Estrategias Alternativas

### Verificación de Existencia (Para Producción):
```sql
-- Ejemplo para tablas en producción
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = UPPER('&NOMBRE_TABLA_LOG');
    
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE &NOMBRE_TABLA_LOG (...)';
    ELSE
        -- Aplicar ALTER TABLE si es necesario
        DBMS_OUTPUT.PUT_LINE('Tabla ya existe');
    END IF;
END;
/
```

### Migración Incremental:
```sql
-- Ejemplo de migración segura
DECLARE
    v_column_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_column_exists
    FROM user_tab_columns
    WHERE table_name = UPPER('&NOMBRE_TABLA_LOG')
    AND column_name = 'NEW_COLUMN';
    
    IF v_column_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE &NOMBRE_TABLA_LOG ADD new_column VARCHAR2(100)';
    END IF;
END;
/
```

## Recomendaciones

1. **Desarrollo**: Usar estrategia DROP/CREATE (implementada)
2. **Testing**: Usar estrategia DROP/CREATE (implementada)  
3. **Producción**: Evaluar estrategias de verificación/migración
4. **Backup**: Siempre hacer backup antes de ejecutar scripts
5. **Documentación**: Mantener log de cambios aplicados

## Beneficios de la Implementación

- ✅ **Ejecución repetible**: Sin errores por objetos existentes
- ✅ **Desarrollo ágil**: Iteración rápida sin cleanup manual
- ✅ **Testing confiable**: Estado limpio en cada ejecución
- ✅ **CI/CD friendly**: Compatible con pipelines automatizados
- ✅ **Debugging simplificado**: Estado conocido y consistente