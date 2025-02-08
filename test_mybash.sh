#!/bin/zsh

# Script para probar todas las funcionalidades de mybash
echo "Iniciando pruebas de mybash..."

# 1. Probar `cpwd`
echo "\n--- Probando cpwd ---"
mkdir -p ~/test_cpwd
cd ~/test_cpwd
cpwd
echo "El directorio actual debe estar copiado en el portapapeles."

# 2. Probar `largefiles`
echo "\n--- Probando largefiles ---"
dd if=/dev/zero of=~/test_cpwd/largefile bs=1M count=10 2>/dev/null
largefiles
echo "Deberías ver 'largefile' en la lista de archivos grandes."

# 3. Probar `opendir`
echo "\n--- Probando opendir ---"
opendir
echo "Se debería abrir el directorio actual en Finder (macOS) o File Explorer (Linux)."

# 4. Probar `mkcd`
echo "\n--- Probando mkcd ---"
mkcd ~/test_mkcd
pwd
echo "Deberías estar en el directorio ~/test_mkcd."

# 5. Probar `myip`
echo "\n--- Probando myip ---"
myip
echo "Deberías ver tu dirección IP local."

# 6. Probar `bkm` (agregar, listar, navegar, eliminar)
echo "\n--- Probando bkm ---"
bkm add test_bkm ~/test_cpwd
echo "Bookmark 'test_bkm' agregado."
bkm list
echo "Deberías ver el bookmark 'test_bkm'."
bkm test_bkm
pwd
echo "Deberías estar en ~/test_cpwd."
bkm remove test_bkm
echo "Bookmark 'test_bkm' eliminado."

# 7. Probar `cmd` (agregar, listar, ejecutar, eliminar)
echo "\n--- Probando cmd ---"
cmd add test_cmd "echo 'Hola desde cmd'"
echo "Comando 'test_cmd' agregado."
cmd list
echo "Deberías ver el comando 'test_cmd'."
cmd test_cmd
echo "Deberías ver 'Hola desde cmd'."
cmd remove test_cmd
echo "Comando 'test_cmd' eliminado."

# 8. Probar `export` y `import`
echo "\n--- Probando export e import ---"
mb export
EXPORT_DIR=~/Documents/mybash/export
TIMESTAMP=$(ls "$EXPORT_DIR" | tail -n 1)
echo "Datos exportados a $EXPORT_DIR/$TIMESTAMP."
mb import
echo "Selecciona el último folder exportado."
echo "Los datos deben ser restaurados correctamente."

# 9. Probar `empty`
echo "\n--- Probando empty ---"
touch ~/test_empty.txt
echo "Contenido inicial" > ~/test_empty.txt
cat ~/test_empty.txt
empty ~/test_empty.txt
cat ~/test_empty.txt
echo "El archivo ~/test_empty.txt debería estar vacío."

# 10. Probar `clean`
echo "\n--- Probando clean ---"
touch ~/test_clean.txt
echo "Contenido inicial" > ~/test_clean.txt
cat ~/test_clean.txt
clean ~/test_clean.txt
cat ~/test_clean.txt
echo "El archivo ~/test_clean.txt debería estar vacío."

# Limpieza
echo "\n--- Limpiando archivos de prueba ---"
rm -rf ~/test_cpwd ~/test_mkcd ~/test_empty.txt ~/test_clean.txt
echo "Archivos de prueba eliminados."

echo "\nPruebas completadas. ¡Revisa los resultados!"
