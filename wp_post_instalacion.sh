#!/bin/bash
#wp_post_instalacion.sh

clear

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

read -n 1 -r -s -p $'Presione una tecla para iniciar o CTRL+C para cancelar...\n'

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

#sección especial para instalar plugins de migracion
read -p "Instalar los plugins de migración? [s/n]: " instalar_migracion
if [ "$instalar_migracion" == s ] ; then
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
else
	echo "Ok, saltando plugins de migración."
fi

clear

read -p "Deseas crear un .htaccess default? [s/n]: " instalar_htaccess
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

echo "============================================================"
echo "Opciones adicionales de seguridad"
echo "Las siguientes opciones agregan código al archivo .htaccess"
echo "Si ya ejecutó estas tareas, no las vuelva a ejecutar"
echo "============================================================"
echo ""
read -n 1 -r -s -p $'Presione una tecla para iniciar o CTRL+C para cancelar...\n'
echo ""

echo "Borrando archivos: readme.html license.txt wp-config-sample.php..."
rm -rf readme.html license.txt wp-config-sample.php;

read -p "Deseas ver el archivo .htaccess? [s/n]: " ver_htaccess
if [ "$ver_htaccess" == s ] ; then
	cat .htaccess
fi

read -p "Deseas bloquear el acceso al wp-config.php? [s/n]: " bloquear_wp_config
if [ "$bloquear_wp_config" == s ] ; then
	echo "Bloqueando..."
	echo "
<Files wp-config.php>
order allow,deny
deny from all
</Files>" >> .htaccess
	echo "Ok, bloqueo del wp-config.php realizado."
else
	echo "Ok, saltando bloqueo del wp-config.php."
fi

read -p "Deseas proteger la carpeta uploads? [s/n]: " proteger_uploads
if [ "$proteger_uploads" == s ] ; then
	echo "protegiendo..."
	echo '
<Files ~ ".*\..*">
	Order Allow,Deny
	Deny from all
</Files>
<FilesMatch "\.(jpg|jpeg|jpe|gif|png|bmp|tif|tiff|doc|pdf|rtf|xls|numbers|odt|pages|key|mp3|mp4|webm|flv|webp)$">
	Order Deny,Allow
	Allow from all
</FilesMatch>' >> .htaccess
	echo "Ok, carpeta uploads protegida."
else
	echo "Ok, saltando protección de carpeta uploads."
fi

read -p "Deseas bloquear los pingbacks? [s/n]: " bloquear_pingbacks
if [ "$bloquear_pingbacks" == s ] ; then
	echo "Bloqueando..."
	echo "
<Files xmlrpc.php>
	Order Deny,Allow
	Deny from all
</Files>" >> .htaccess
	echo "Ok, bloqueo de pingbacks realizado."
else
	echo "Ok, saltando bloqueo de pingbacks."
fi

echo "Protegiendo wp-config.php contra escritura..."
chmod 444 wp-config.php

echo "Proceso completado!"
