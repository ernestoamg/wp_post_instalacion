# wp_post_instalacion
Script para tareas y acciones post instalación de instancia nueva de WordPress.  Este bash realiza algunas tareas post instalación, cuando la instancia ha sido recién instalada y es una muestra de las labores que se pueden realizar con el WP CLI.

Este bash ejecuta las siguientes tareas:
- Borra los archivos readme.html license.txt wp-config-sample.php
- Elimina posts default
- Elimina plugins de askimet y hello
- Elimina temas innecesarios
- Instala tema default propularfx (se puede cambiar por el que sea)
- Ajusta opciones del blog, timezone, etc
- Instala plugins default como: cache, seguridad, cambiar url, etc. (ejemplos)
- Pregunta por acciones adicionales como:
  - instalar editor clásico
  - instalar plugins de migración
- Gestionar seguridad default mediante ajustes al .htaccess
  - crea un .htaccess default
  - regla de bloqueo de wp-config.php
  - regla para proteger carpeta uploads
  - regla para rechazar pingbacks
- Cambiar permisos en el wp-config.php

Usted debe modificar las secciones de:
- Instalar los plugins de seguridad PRO: solo si tiene una opción PRO para instalar, al contestar "no", se instala "better-wp-security"
- Instalar los plugins de migración: usted debe proveer los archivos de instalación de su versió PRO, de otro modo instalará "all-in-one-wp-migration"

Modificar el resto a su gusto.
