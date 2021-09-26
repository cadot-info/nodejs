#!/usr/bin/env bash

set -e

# See:
# - Doc: https://docs.docker.com/engine/reference/builder/#entrypoint
# - Example: https://github.com/docker-library/mariadb/blob/master/10.1/docker-entrypoint.sh
#
# Example use:
# ./docker-entrypoint.sh php-fpm

## Clear container on start by default
if [ "$NO_FORCE_SF_CONTAINER_REFRESH" != "" ]; then
    logger "NO_FORCE_SF_CONTAINER_REFRESH set, skipping Symfony container clearing on startup."
elif [ -d var/cache ]; then
    logger "Symfony 3.x structure detected, container is not cleared on startup, use 3.2+ env variables support and warmup container during build."
elif [ -d ezpublish/cache ]; then
    logger "Deleting ezpublish/cache/*/*ProjectContainer.php to make sure environment variables are picked up"
    rm -f ezpublish/cache/*/*ProjectContainer.php
elif [ -d app/cache ]; then
    logger "Deleting app/cache/*/*ProjectContainer.php to make sure environment variables are picked up"
    rm -f app/cache/*/*ProjectContainer.php
fi


# Scan for environment variables prefixed with PHP_INI_ENV_ and inject those into ${PHP_INI_DIR}/zzz_custom_settings.ini
# Environment variable names cannot contain dots, so use two underscores in that case:
# PHP_INI_ENV_session__gc_maxlifetime=2592000  --> session.gc_maxlifetime=2592000
if [ -f ${PHP_INI_DIR}/zzz_custom_settings.ini ]; then rm ${PHP_INI_DIR}/zzz_custom_settings.ini; fi
env | while IFS='=' read -r name value; do
    if (echo $name | grep -E "^PHP_INI_ENV" >/dev/null); then
        # remove PHP_INI_ENV_ prefix
        name=$(echo $name | cut -f 4- -d "_")
        # Replace __ with .
        name=${name//__/.}
        echo $name=$value >>${PHP_INI_DIR}/zzz_custom_settings.ini
    fi
done

# Scan for environment variables prefixed with PHP_FPM_INI_ENV_ and inject those into /usr/local/etc/php-fpm.d/zzz_custom_settings.conf
# Environment variable names cannot contain dots, so use two underscores in that case:
# PHP_FPM_INI_ENV_pm__max_children=10  --> pm.max_children=10
if [ -f /usr/local/etc/php-fpm.d/zzz_custom_settings.conf ]; then rm /usr/local/etc/php-fpm.d/zzz_custom_settings.conf; fi
echo '[www]' >/usr/local/etc/php-fpm.d/zzz_custom_settings.conf
env | while IFS='=' read -r name value; do
    if (echo $name | grep -E "^PHP_FPM_INI_ENV" >/dev/null); then
        # remove PHP_FPM_INI_ENV_ prefix
        name=$(echo $name | cut -f 5- -d "_")
        # Replace __ with .
        name=${name//__/.}
        echo $name=$value >>/usr/local/etc/php-fpm.d/zzz_custom_settings.conf
    fi
done

exec "$@"
