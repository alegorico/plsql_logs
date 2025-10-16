# Proceso de Generación - Sistema de Logging PL/SQL

Este documento describe el proceso completo para generar archivos consolidados desde los componentes modulares del sistema de logging.

## Herramienta Utilizada

**mergeSourceFile**: Utilidad de línea de comandos para consolidar archivos SQL modulares.

- **Repositorio**: https://github.com/alegorico/mergeSourceFile
- **Propósito**: Combinar múltiples archivos SQL en un único archivo ejecutable
- **Lenguaje**: Python

## Instalación de la Herramienta

### 1. Prerrequisitos
```bash
# Verificar Python instalado
python --version
# o
py --version
```

### 2. Obtener mergeSourceFile
```bash
git clone https://github.com/alegorico/mergeSourceFile.git
cd mergeSourceFile
```

### 3. Configurar PATH (Opcional)
Agregar el directorio de la herramienta al PATH del sistema para usarla desde cualquier ubicación.

## Proceso de Generación

### Comando Principal
```bash
# Ejecutar desde el directorio raíz del proyecto plsql-project
py merge --skip-var -i deploy\generate.sql -o generated.sql
```

### Explicación de Parámetros

| Parámetro | Descripción |
|-----------|-------------|
| `py merge` | Ejecuta la herramienta mergeSourceFile |
| `--skip-var` | Omite el procesamiento de variables DEFINE |
| `-i deploy\generate.sql` | Archivo de entrada (script principal) |
| `-o generated.sql` | Archivo de salida consolidado |

### Flujo de Procesamiento

1. **Lectura**: La herramienta lee `deploy/generate.sql`
2. **Resolución**: Procesa las directivas `@` para incluir archivos
3. **Consolidación**: Combina todos los archivos referenciados
4. **Generación**: Crea `generated.sql` con todo el código

### Estructura de Entrada

El archivo `deploy/generate.sql` actúa como "índice" de los componentes:

```sql
@src/config.sql
@src/tables/log_table.sql
@src/tables/config_table.sql
@src/indexs/config_index.sql
@src/views/log_elapsed.sql
@src/views/log_ordered.sql
@src/packages/pkg_logger.sql
```

### Resultado

El archivo `generated.sql` contendrá:
- Todas las variables de configuración
- Definiciones de tablas con idempotencia
- Índices con idempotencia
- Vistas
- Paquetes completos
- En el orden correcto de ejecución

## Ventajas del Enfoque Modular

### Desarrollo
- **Separación de responsabilidades**: Cada archivo tiene un propósito específico
- **Mantenimiento fácil**: Cambios aislados por componente
- **Reutilización**: Componentes pueden usarse independientemente
- **Control de versiones**: Historial granular de cambios

### Despliegue
- **Archivo único**: `generated.sql` contiene todo el sistema
- **Orden garantizado**: Dependencias resueltas automáticamente
- **Distribución simple**: Un solo archivo para enviar
- **Ejecución directa**: `@generated.sql` instala todo

## Flujo de Trabajo Recomendado

### 1. Desarrollo
```bash
# Trabajar en archivos modulares
edit src/tables/log_table.sql
edit src/packages/pkg_logger.sql
```

### 2. Testing Local
```sql
-- Probar componente individual
@src/tables/log_table.sql

-- Probar instalación completa modular
@deploy/generate.sql
```

### 3. Generación para Distribución
```bash
# Generar archivo consolidado
py merge --skip-var -i deploy\generate.sql -o generated.sql
```

### 4. Distribución
```bash
# Enviar archivo único
scp generated.sql server:/path/to/deploy/
```

### 5. Instalación en Destino
```sql
-- En el servidor destino
@generated.sql
```

## Casos de Uso

### Desarrollo Iterativo
- Modificar archivos modulares
- Probar con `@deploy/generate.sql`
- Regenerar cuando sea necesario

### Releases
- Generar `generated.sql` para cada versión
- Versionar el archivo consolidado
- Distribuir release único

### Entornos Múltiples
- Diferentes configuraciones en `src/config.sql`
- Generar archivos específicos por entorno
- Mantener trazabilidad de versiones

## Troubleshooting

### Error: "py no reconocido"
```bash
# Usar python en lugar de py
python merge --skip-var -i deploy\generate.sql -o generated.sql
```

### Error: "No such file merge"
```bash
# Verificar que mergeSourceFile está en PATH o usar ruta completa
C:\path\to\mergeSourceFile\merge.py --skip-var -i deploy\generate.sql -o generated.sql
```

### Error en archivo generado
1. Verificar que `deploy/generate.sql` está correcto
2. Comprobar que todos los archivos referenciados existen
3. Validar sintaxis de archivos modulares
4. Regenerar el archivo consolidado

## Integración con CI/CD

### Ejemplo para GitHub Actions
```yaml
- name: Generate consolidated SQL
  run: |
    git clone https://github.com/alegorico/mergeSourceFile.git
    python mergeSourceFile/merge.py --skip-var -i deploy/generate.sql -o generated.sql
    
- name: Upload artifact
  uses: actions/upload-artifact@v2
  with:
    name: consolidated-sql
    path: generated.sql
```

### Ejemplo para Jenkins
```groovy
stage('Generate SQL') {
    steps {
        sh 'python merge.py --skip-var -i deploy/generate.sql -o generated.sql'
        archiveArtifacts 'generated.sql'
    }
}
```