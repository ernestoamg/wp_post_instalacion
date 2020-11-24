#!/bin/bash
#wp_post_instalacion.sh
# http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
red=`tput setaf 1`;
yellow=`tput setaf 3`;
green=`tput setaf 2`;
clear=`tput sgr0`;

#desproteger el wp-config.php para realizar cambios
chmod 644 wp-config.php

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


## borra contenido default
# posts/paginas de ejemplo
wp post delete 1 2 --force $allowroot

# plugins no deseados
wp plugin delete \
  akismet \
  hello $allowroot

# instala tema nuevo y elimina temas default
wp theme install wp-bootstrap-starter --activate $allowroot
wp theme delete \
  twentyseventeen \
  twentynineteen \
  twentytwenty $allowroot

##algunos ajustes default necesarios
wp option update blogdescription "" $allowroot
wp option update start_of_week 0 $allowroot
wp option update timezone_string "America/Panama" $allowroot
wp option update permalink_structure "/%postname%" $allowroot

##plugins default
wp plugin install \
  go-live-update-urls \
  mainwp-child \
  mainwp-child-reports \
  wp-fastest-cache \
  wp-reset \
  --activate $allowroot

read -p "${yellow}Instalar los plugins de seguridad PRO? [s/n]:${clear} " instalar_securitypro
if [ "$instalar_securitypro" == s ] ; then
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
else
	echo "Ok, instalando versión gratuita."
	wp plugin install better-wp-security $allowroot
	echo "Versión gratuita instalada."
fi

read -p "${yellow}Instalar editor clásico? [s/n]: ${clear}" instalar_editorclasico
if [ "$instalar_editorclasico" == s ] ; then
	wp plugin install classic-editor $allowroot
fi

#sección especial para instalar plugins de migracion
read -p "${yellow}Instalar plugins de migración PRO? [s/n]: ${clear}" instalar_migracion
if [ "$instalar_migracion" == s ] ; then
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
	wp plugin install https://undominio.com/unpluginespecial.zip $allowroot
else
	echo "Ok, instalando versión gratuita: all-in-one-wp-migration."
	wp plugin install all-in-one-wp-migration $allowroot
	echo "Versión gratuita instalada."
fi

echo "============================================================"
echo "ATENCIÓN: UTILICE ESTA SECCIÓN BAJO SU PROPIO RIESGO."
echo "Renombrar el prefijo de las tablas de la base de datos."
echo "Si algo sale mal, se puede dañar su sitio web."
echo "Antes de responder 's' asegúrese de terner backup del wp-config.php y su base de datos."
echo "============================================================"
echo ""
echo "Estas son sus tablas actuales:"
wp db tables $allowroot
echo ""

# Backup de la base de datos
read 'Desea hacer una copia de seguridad?' -n 1 -r
if [[ $REPLY =~ ^[Ss]$ ]]; then
  # Generamos dump, desplegamos resultados y guardamos nombre del archivo
  # NOTA: Se podría asignar un nombre predeterminado al dump usando:
  #       $ wp db export <filename>
  #       pero no encontré forma amigable de determinar el nombre de la base de
  #       datos para incluir en el nombre del archivo.
  DUMPNAME=$(wp db export --add-drop-table | tee /dev/tty | cut -d \' -f 2)
  ZIPPATH="$HOME/wp-backup"
  ZIPURI="$ZIPPATH/${DUMPNAME%.sql}".zip

  mkdir -p $ZIPPATH
  echo 'Generando zip con backup de la base de datos y wp-config.php...'
  zip "$ZIPURI" $DUMPNAME wp-config.php
  rm $DUMPNAME
  echo "Se creó el archivo de respaldo: $ZIPURI"
fi

#sección para renombrar cambiar el prefijo de las tablas de la base de datos
read -p "${yellow}¿Desea renombrar los prefijos de las tablas? [s/n]: ${clear}" renombrar_prefijos
if [ "$renombrar_prefijos" == s ] ; then
	echo "Instalando paquete..."
	wp package install iandunn/wp-cli-rename-db-prefix $allowroot
	echo ""
	echo "Se le preguntará si se procede con la operación:"
	read -p "Nuevo prefijo para sus tablas: " nuevo_prefijo
	wp rename-db-prefix $nuevo_prefijo $allowroot
else
	echo "Ok, saltando cambio de prefijo."
fi
echo "Tablas renombradas:"
wp db tables $allowroot
echo ""
read -n 1 -r -s -p $'${yellow}Verifique y presione una tecla para continuar o CTRL+C para cancelar...\n ${clear}'

clear
echo "============================================================"
echo "Opciones adicionales de seguridad"
echo "Las siguientes opciones agregan código al archivo .htaccess"
echo "Si ya ejecutó estas tareas, no las vuelva a ejecutar"
echo "============================================================"
echo ""
read -n 1 -r -s -p $'Presione una tecla para continuar o CTRL+C para cancelar...\n'
echo ""

echo "Borrando archivos: readme.html license.txt wp-config-sample.php..."
rm -rf readme.html license.txt wp-config-sample.php;

read -p "${yellow}¿Deseas crear un .htaccess default? [s/n]: ${clear}" instalar_htaccess
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

read -p "${yellow}¿Deseas ver el archivo .htaccess? [s/n]: ${clear}" ver_htaccess
if [ "$ver_htaccess" == s ] ; then
	cat .htaccess
fi

read -p "${yellow}¿Deseas bloquear el acceso al wp-config.php? [s/n]: ${clear}" bloquear_wp_config
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

read -p "${yellow}¿Deseas proteger la carpeta uploads? [s/n]: ${clear}" proteger_uploads
if [ "$proteger_uploads" == s ] ; then

	ht_file="wp-content/uploads/.htaccess"
	if [ ! -f "$ht_file" ]

		echo "protegiendo..."
		echo '
<Files ~ ".*\..*">
	Order Allow,Deny
	Deny from all
</Files>
<FilesMatch "\.(jpg|jpeg|jpe|gif|png|bmp|tif|tiff|doc|pdf|rtf|xls|numbers|odt|pages|key|mp3|mp4|webm|flv|webp)$">
	Order Deny,Allow
	Allow from all
</FilesMatch>' >> wp-content/uploads/.htaccess
		echo "Ok, carpeta uploads protegida."
	then
	    echo "${red} $0: El archivo'${ht_file}' ya existe, no se hicieron cambios.${clear}"
	fi
else
	echo "Ok, saltando protección de carpeta uploads."
fi

read -p "${yellow}¿Deshabilita la ejecución de archivos PHP en uploads? [s/n]: ${clear}" deshablita_php
if [ "$deshablita_php" == s ] ; then

	ht_file="wp-content/uploads/.htaccess"
	if [ ! -f "$ht_file" ]

		echo "deshabilitando..."
		echo "
<Files *.php>
deny from all
</Files>" >> wp-content/uploads/.htaccess
		echo "Ok, archivos PHP deshabilitados."
		then
		    echo "${red} $0: El archivo'${ht_file}' ya existe, no se hicieron cambios.${clear}"
		fi

	else
		echo "Ok, saltando archivos PHP deshabilitados."
	fi

read -p "${yellow}¿Deseas bloquear los pingbacks? [s/n]: ${clear}" bloquear_pingbacks
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

read -p "${yellow}¿Bloquear navegación de carpetas? [s/n]: ${clear}" navegacion_carpetas
if [ "$navegacion_carpetas" == s ] ; then
	echo "Bloqueando..."
	echo "Options -Indexes" >> .htaccess
	echo "Ok, bloqueo de navegación de carpetas realizado."
else
	echo "Ok, saltando bloqueo de navegación de carpetas."
fi

read -p "${yellow}¿Deseas bloquear el acceso al .htaccess? [s/n]: ${clear}" bloquear_htaccess
if [ "$bloquear_htaccess" == s ] ; then
	echo "Bloqueando..."
	echo "
<Files .htaccess>
order allow,deny
deny from all
</Files>" >> .htaccess
	echo "Ok, bloqueo del .htaccess realizado."
else
	echo "Ok, saltando bloqueo del .htaccess."
fi

echo "Protegiendo wp-config.php contra escritura..."
chmod 444 wp-config.php

echo "Proceso completado!"
