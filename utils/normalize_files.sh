    #!/bin/bash

    # Directorio base
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Archivos y directorios a excluir
    EXCLUDE_PATTERNS=(".png" ".db" ".jpg" ".jpeg" ".gif" ".ico" ".svg")

    # Función para verificar si un archivo debe ser excluido
    should_exclude() {
        local file="$1"
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if [[ "$file" == *"$pattern" ]]; then
                return 0 # Excluir
            fi
        done
        return 1 # No excluir
    }

    # Función para normalizar archivos
    normalize_files() {
        echo "Normalizando archivos en: $BASE_DIR"
        find "$BASE_DIR" -type f | while read -r file; do
            if should_exclude "$file"; then
                echo "Ignorando archivo binario o no deseado: $file"
                continue
            fi

            echo "Normalizando archivo: $file"
            if dos2unix "$file" 2>/dev/null; then
                echo "Archivo normalizado: $file"
            else
                echo "Error al normalizar archivo: $file"
            fi
        done
    }

    # Verificar si dos2unix está instalado
    if ! command -v dos2unix &>/dev/null; then
        echo "Error: 'dos2unix' no está instalado. Por favor, instálalo antes de ejecutar este script."
        exit 1
    fi

    # Ejecutar la normalización
    normalize_files

    echo "Proceso de normalización completado."