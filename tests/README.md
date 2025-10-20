# Tests - Scripts de Pruebas del Logger

Esta carpeta contiene todos los scripts y documentación necesarios para probar el sistema de logging.

## Contenido

### Scripts de Pruebas para Base de Datos
- **`test_database_logger.sql`** - Batería completa de pruebas para implementación BD (9 pruebas exhaustivas)
- **`test_database_simple.sql`** - Pruebas rápidas para validación básica de BD

### Scripts de Pruebas para Colas
- **`test_queue_logger.sql`** - Batería completa de pruebas para implementación colas (10 pruebas exhaustivas)
- **`test_queue_simple.sql`** - Pruebas rápidas para validación básica de colas
- **`test_queue_monitor.sql`** - Monitor en tiempo real de la cola de logging

### Documentación
- **`TESTING_GUIDE.md`** - Guía completa de cómo ejecutar y usar las pruebas
- **`README.md`** - Este archivo

## Inicio Rápido

### 1. Para Implementación de Base de Datos

#### Prerequisitos
```sql
@../generated_table.sql
```

#### Prueba Básica
```sql
@test_database_simple.sql
```

#### Pruebas Completas
```sql
@test_database_logger.sql
```

### 2. Para Implementación de Colas

#### Prerequisitos
```sql
@../generated_queue_fixed.sql
```

#### Prueba Básica
```sql
@test_queue_simple.sql
```

#### Pruebas Completas
```sql
@test_queue_logger.sql
```

#### Monitoreo (opcional)
En una sesión separada:
```sql
@test_queue_monitor.sql
```

## Propósito de Cada Script

| Script | Tiempo | Propósito | Casos de Uso |
|--------|--------|-----------|--------------|
| `test_database_simple.sql` | ~30 segundos | Validación rápida BD | Verificar que el sistema BD funciona |
| `test_database_logger.sql` | ~2-3 minutos | Pruebas exhaustivas BD | Validación completa funcionalidades BD |
| `test_queue_simple.sql` | ~30 segundos | Validación rápida colas | Verificar que el sistema colas funciona |
| `test_queue_logger.sql` | ~2-3 minutos | Pruebas exhaustivas colas | Validación completa funcionalidades colas |
| `test_queue_monitor.sql` | Continuo | Monitoreo tiempo real | Debugging y observación de colas |

## Resultados Esperados

### ✅ Éxito para Base de Datos
- Todos los scripts ejecutan sin errores
- Los mensajes aparecen en la tabla `&NOMBRE_TABLA_LOG`
- La configuración de silenciamiento funciona correctamente
- Las ejecuciones anidadas mantienen trazabilidad
- Las vistas de tiempo transcurrido funcionan

### ✅ Éxito para Colas
- Todos los scripts ejecutan sin errores
- Los mensajes aparecen en la cola `qt_log_logger`
- La configuración de silenciamiento funciona correctamente
- Las ejecuciones anidadas mantienen trazabilidad
- Los mensajes JSON están bien formateados

### ❌ Posibles Problemas
- **Error de privilegios AQ**: Contactar DBA para otorgar permisos
- **Tabla no encontrada**: Ejecutar primero el script de deploy
- **Cola no funciona**: Verificar que Oracle AQ esté habilitado

## Estructura de Pruebas

```
tests/
├── README.md                    # Este archivo
├── TESTING_GUIDE.md            # Documentación detallada
├── test_database_simple.sql    # Pruebas básicas BD
├── test_database_logger.sql    # Pruebas completas BD
├── test_queue_simple.sql       # Pruebas básicas colas
├── test_queue_logger.sql       # Pruebas completas colas
└── test_queue_monitor.sql      # Monitor tiempo real colas
```

## Soporte

Para más detalles sobre cada script y troubleshooting, consulta `TESTING_GUIDE.md`.