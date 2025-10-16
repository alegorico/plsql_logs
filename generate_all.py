#!/usr/bin/env python3
"""
================================================================
SCRIPT DE GENERACIÓN DE ARCHIVOS CONSOLIDADOS
================================================================
Descripción: Script para generar todos los archivos consolidados
             del sistema de logging con sus respectivas pruebas
Uso: python generate_all.py [opciones]
================================================================
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
from typing import Dict, List, Tuple


class LoggerGenerator:
    """Generador de scripts consolidados del sistema de logging"""
    
    def __init__(self, base_path: Path = None):
        self.base_path = base_path or Path.cwd()
        self.deploy_path = self.base_path / "deploy"
        self.scripts_path = self.base_path / "scripts"
        
        # Configuración de archivos a generar
        self.configs = {
            "database": {
                "input": "deploy_database_logger.sql",
                "output": "output_database.sql",
                "description": "Sistema BD"
            },
            "database_with_tests": {
                "input": "deploy_database_with_tests.sql",
                "output": "output_database_with_tests.sql",
                "description": "Sistema BD + Pruebas"
            },
            "queue": {
                "input": "deploy_queue_logger.sql",
                "output": "output_queue.sql", 
                "description": "Sistema Colas"
            },
            "queue_with_tests": {
                "input": "deploy_queue_with_tests.sql",
                "output": "output_queue_with_tests.sql",
                "description": "Sistema Colas + Pruebas"
            },
            "tests_database": {
                "input": "deploy_tests_database.sql",
                "output": "output_tests_database.sql",
                "description": "Solo Pruebas BD"
            },
            "tests_queue": {
                "input": "deploy_tests_queue.sql", 
                "output": "output_tests_queue.sql",
                "description": "Solo Pruebas Colas"
            },
            "cleanup_database": {
                "input": "deploy_cleanup_database.sql",
                "output": "output_cleanup_database.sql",
                "description": "Limpieza BD"
            },
            "cleanup_queue": {
                "input": "deploy_cleanup_queue.sql",
                "output": "output_cleanup_queue.sql", 
                "description": "Limpieza Colas"
            }
        }
        
    def find_merge_tool(self) -> str:
        """Encuentra la herramienta MergeSourceFile"""
        # Opciones de comando en orden de preferencia
        commands = [
            "MergeSourceFile",           # Instalado globalmente
            "python -m MergeSourceFile", # Módulo Python
            "py -m MergeSourceFile",     # Windows py launcher
            f"python {self.scripts_path / 'mergeSourceFile.py'}"  # Local
        ]
        
        for cmd in commands:
            try:
                # Probar si el comando funciona
                result = subprocess.run(
                    f"{cmd} --help", 
                    shell=True, 
                    capture_output=True, 
                    text=True,
                    timeout=10
                )
                if result.returncode == 0:
                    return cmd
            except (subprocess.TimeoutExpired, subprocess.SubprocessError):
                continue
                
        raise RuntimeError(
            "No se pudo encontrar MergeSourceFile. "
            "Instálalo con: pip install MergeSourceFile"
        )
    
    def generate_file(self, key: str, config: Dict[str, str]) -> Tuple[bool, str]:
        """Genera un archivo específico"""
        input_file = self.deploy_path / config["input"]
        output_file = self.base_path / config["output"]
        
        # Verificar que el archivo de entrada existe
        if not input_file.exists():
            return False, f"Archivo de entrada no encontrado: {input_file}"
        
        try:
            merge_cmd = self.find_merge_tool()
            cmd = f'{merge_cmd} -i "{input_file}" -o "{output_file}"'
            
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                return True, f"✓ {config['output']} generado exitosamente"
            else:
                error_msg = result.stderr.strip() if result.stderr else "Error desconocido"
                return False, f"✗ Error generando {config['output']}: {error_msg}"
                
        except subprocess.TimeoutExpired:
            return False, f"✗ Timeout generando {config['output']}"
        except Exception as e:
            return False, f"✗ Error generando {config['output']}: {str(e)}"
    
    def generate_all(self, targets: List[str] = None) -> None:
        """Genera todos los archivos o solo los especificados"""
        print("=" * 64)
        print("GENERANDO SCRIPTS CONSOLIDADOS DEL LOGGER")
        print("=" * 64)
        
        # Determinar qué archivos generar
        if targets:
            configs_to_generate = {k: v for k, v in self.configs.items() if k in targets}
            if not configs_to_generate:
                print(f"✗ No se encontraron targets válidos: {targets}")
                return
        else:
            configs_to_generate = self.configs
        
        results = []
        
        # Generar cada archivo
        for i, (key, config) in enumerate(configs_to_generate.items(), 1):
            print(f"\n{i}. Generando {config['description']}...")
            success, message = self.generate_file(key, config)
            results.append((key, config, success, message))
            print(f"   {message}")
        
        # Resumen
        self.print_summary(results)
        
    def print_summary(self, results: List[Tuple[str, Dict, bool, str]]) -> None:
        """Imprime resumen de archivos generados"""
        print("\n" + "=" * 64)
        print("RESUMEN DE ARCHIVOS GENERADOS:")
        print("=" * 64)
        
        successful = []
        failed = []
        
        for key, config, success, message in results:
            output_file = self.base_path / config["output"]
            if success and output_file.exists():
                successful.append(f"✓ {config['output']} - {config['description']}")
            else:
                failed.append(f"✗ {config['output']} - {config['description']}")
        
        for line in successful:
            print(line)
        
        if failed:
            print("\nARCHIVOS NO GENERADOS:")
            for line in failed:
                print(line)
        
        if successful:
            print("\n" + "=" * 64)
            print("INSTRUCCIONES DE USO:")
            print("=" * 64)
            print("INSTALACIÓN:")
            print("1. Para instalar sistema de BD:          @output_database.sql")
            print("2. Para instalar BD con pruebas:         @output_database_with_tests.sql")
            print("3. Para instalar sistema de Colas:       @output_queue.sql")
            print("4. Para instalar Colas con pruebas:      @output_queue_with_tests.sql")
            print("\nPRUEBAS:")
            print("5. Para ejecutar solo pruebas BD:        @output_tests_database.sql")
            print("6. Para ejecutar solo pruebas Colas:     @output_tests_queue.sql")
            print("\nLIMPIEZA (ELIMINA TODO):")
            print("7. Para limpiar sistema de BD:           @output_cleanup_database.sql")
            print("8. Para limpiar sistema de Colas:        @output_cleanup_queue.sql")
            print("=" * 64)
    
    def list_targets(self) -> None:
        """Lista todos los targets disponibles"""
        print("Targets disponibles:")
        for key, config in self.configs.items():
            print(f"  {key:<20} - {config['description']}")


def main():
    """Función principal"""
    parser = argparse.ArgumentParser(
        description="Generador de scripts consolidados del sistema de logging",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python generate_all.py                    # Generar todos los archivos
  python generate_all.py database queue     # Solo BD y colas básicas
  python generate_all.py --list             # Listar targets disponibles
  python generate_all.py cleanup_database   # Solo limpieza de BD
        """
    )
    
    parser.add_argument(
        "targets", 
        nargs="*", 
        help="Targets específicos a generar (por defecto: todos)"
    )
    
    parser.add_argument(
        "--list", 
        action="store_true", 
        help="Listar todos los targets disponibles"
    )
    
    parser.add_argument(
        "--path",
        type=Path,
        default=Path.cwd(),
        help="Ruta base del proyecto (por defecto: directorio actual)"
    )
    
    args = parser.parse_args()
    
    try:
        generator = LoggerGenerator(args.path)
        
        if args.list:
            generator.list_targets()
            return
        
        generator.generate_all(args.targets if args.targets else None)
        
    except Exception as e:
        print(f"✗ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()