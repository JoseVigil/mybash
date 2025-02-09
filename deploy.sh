#!/bin/zsh

# Variables
DEV_DIR="\$HOME/repos/mybash"
PROD_DIR="\$HOME/mybash"

# Confirmación
read -q "?Are you sure you want to deploy the development version to production? (y/n) "
echo
if [[ \$? -ne 0 ]]; then
    echo "Deployment canceled."
    exit 1
fi

# Sincronizar archivos
echo "Deploying changes from \$DEV_DIR to \$PROD_DIR..."
rsync -av --exclude='.git/' "\$DEV_DIR/" "\$PROD_DIR/"

# Copiar archivo .env específico para producción
cp "\$DEV_DIR/.env.production" "\$PROD_DIR/.env"

# Recargar configuración
echo "Reloading shell configuration..."
source ~/.zshrc

echo "Deployment complete!"
