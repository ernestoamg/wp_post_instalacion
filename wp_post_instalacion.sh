#!/bin/bash
clear

##verificamos primero si el usuario es ROOT, si es root entonces agrega el parámetro '--allow-root' para ejecutar los comandos
if [ "$EUID" -ne 0 ]; then
  allowroot=""
else
  echo "Corriendo en modo ROOT..."
  allowroot="--allow-root"
fi

##bash post instalación
echo "================================================"
echo "Ejecutando procesos post-instalacion"
echo "================================================"

read -n 1 -r -s -p $'Presione una tecla para iniciar...\n'

#sección especial para reinstalar, por terminar
#read -p "¿Desea resetear la Base de datos? ESTE PROCESO NO ES REVERSIBLE Y BORRA TODO [s/n]: " resetdb
#if [ "$ejecuta_resetdb" == s ] ; then
#	wp db reset --yes
#else
#	echo "Ok, saltando reinstalación."
#fi


## borra los posts/paginas de ejemplo, plugins no deseados y elimina temas default
wp post delete 1 2 --force $allowroot 
wp plugin delete akismet $allowroot
wp plugin delete hello $allowroot
wp theme delete twentyseventeen $allowroot
wp theme delete twentynineteen $allowroot
wp theme install popularfx --activate $allowroot
wp theme delete twentytwenty $allowroot

##algunos ajustes default necesarios
wp option update blogdescription "" $allowroot
wp option update start_of_week 0 $allowroot
wp option update timezone_string "America/Panama" $allowroot
wp option update permalink_structure "/%postname%" $allowroot

##plugins default
wp plugin install go-live-update-urls $allowroot
wp plugin install mainwp-child --activate $allowroot
wp plugin install mainwp-child-reports --activate $allowroot
wp plugin install wp-fastest-cache --activate $allowroot
wp plugin install wp-reset --activate $allowroot

read -p "Instalar los plugins de seguridad PRO? [s/n]: " instalar_securitypro
if [ "$instalar_securitypro" == s ] ; then
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
else
	echo "Ok, instalando versión gratuita."
	wp plugin install better-wp-security $allowroot
	echo "Versión gratuita instalada."
fi

read -p "Instalar editor clásico? [s/n]: " instalar_editorclasico
if [ "$instalar_editorclasico" == s ] ; then
	wp plugin install classic-editor $allowroot
fi

#sección especial para instalar plugins de 'migracion', usado como ejemplo.
read -p "Instalar los plugins de migración? [s/n]: " instalar_migracion
if [ "$instalar_migracion" == s ] ; then
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
else
	echo "Ok, saltando plugins de migración."
fi

clear

read -p "Instalar editor clásico? [s/n]: " instalar_htaccess
if [ "$instalar_htaccess" == s ] ; then
echo "Creando archivo .htaccess"
cat > .htaccess<<EOF
# BEGIN WordPress
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF
	echo "Ok, .htaccess creado."
else
	echo "Ok, saltando .htaccess nuevo."
fi

echo "================================================"
echo "Limpiando un poco..."
echo "================================================"
rm -rf readme.html license.txt wp-config-sample.php;
echo "Proceso completado!"
