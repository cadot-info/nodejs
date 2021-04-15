!/bin/bash

## Enable xdebug if ENABLE_XDEBUG env is defined
if [ ! -f ${PHP_INI_DIR}/conf.d/xdebug.ini ] && [ "${ENABLE_XDEBUG}" != "" ]; then
    logger "Enabling xdebug"
    mv ${PHP_INI_DIR}/conf.d/xdebug.ini.disabled ${PHP_INI_DIR}/conf.d/xdebug.ini
fi

## Auto adjust log folder for xdebug if enabled
if [ ! -d app ] && [ -f ${PHP_INI_DIR}/conf.d/xdebug.ini ]; then
    if [ -d ezpublish/log ]; then
        logger "Auto adjusting xdebug settings to log in ezpublish/log"
        sed -i "s@/var/www/app/log@/var/www/ezpublish/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
    elif [ -d var/log ]; then
        logger "Auto adjusting xdebug settings to log in var/log"
        sed -i "s@/var/www/app/log@/var/www/var/log@" ${PHP_INI_DIR}/conf.d/xdebug.ini
    fi
fi
