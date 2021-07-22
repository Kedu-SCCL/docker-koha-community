#!/bin/bash

# Default values for environment variables
export DB_PORT="${DB_PORT:-3306}"
export DOMAIN="${DOMAIN:-}"
export INTRAPORT="${INTRAPORT:-8080}"
export INTRAPREFIX="${INTRAPREFIX:-}"
export INTRASUFFIX="${INTRASUFFIX:-}"
export LIBRARY_NAME="${LIBRARY_NAME:-defaultlibraryname}"
export MEMCACHED_PREFIX=${MEMCACHED_PREFIX:-koha_}
export MEMCACHED_SERVERS=${MEMCACHED_SERVERS:-memcached:11211}
export OPACPORT="${OPACPORT:-80}"
export OPACPREFIX="${OPACPREFIX:-}"
export OPACSUFFIX="${OPACSUFFIX:-}"
export SLEEP="${SLEEP:-3}"
export USE_MEMCACHED=${USE_MEMCACHED:-yes}
export ZEBRA_MARC_FORMAT=${ZEBRA_MARC_FORMAT:-marc21}

update_koha_sites () {
    echo "*** Modifying /etc/koha/koha-sites.conf"
    envsubst < /docker/templates/koha-sites.conf > /etc/koha/koha-sites.conf
}

update_httpd_listening_ports () {
    echo "*** Fixing apache2 listening ports"
    if [ "80" != "$INTRAPORT" ]; then
        echo "Listen $INTRAPORT" >> /etc/apache2/ports.conf
    fi
    if [ "80" != "$OPACPORT" ] && [ $INTRAPORT != $OPACPORT ]; then
        echo "Listen $OPACPORT" >> /etc/apache2/ports.conf
    fi
}

update_koha_database_conf () {
    echo "*** Modifying /etc/mysql/koha-common.cnf"
    envsubst < /docker/templates/koha-common.cnf > /etc/mysql/koha-common.cnf
}

fix_database_permissions () {
    echo "*** Fixing database permissions to be able to use an external server"
    # TODO: restrict to the docker container private IP
    # TODO: investigate how to change hardcoded 'koha_' preffix in database name and username creatingg '/etc/koha/sites/${LIBRARY_NAME}/koha-conf.xml.in'
    mysql -h $DB_HOST -u root -p${DB_ROOT_PASSWORD} -e "update mysql.user set Host='%' where Host='localhost' and User='koha_$LIBRARY_NAME';"
    mysql -h $DB_HOST -u root -p${DB_ROOT_PASSWORD} -e "flush privileges;"
    mysql -h $DB_HOST -u root -p${DB_ROOT_PASSWORD} -e "grant all on koha_$LIBRARY_NAME.* to 'koha_$LIBRARY_NAME'@'%';"
}

log_database_credentials () {
    echo "===================================================="
    echo "IMPORTANT: credentials needed to post-installation through your browser"
    echo "Username: koha_$LIBRARY_NAME"
    echo "Password: type 'docker exec -ti `hostname` koha-passwd $LIBRARY_NAME'" to display it
    echo "===================================================="
}

install_koha_translate_languages () {
    echo "*** Installing koha translate languages defined by KOHA_TRANSLATE_LANGUAGES"
    IFS=',' read -ra LIST <<< "$KOHA_TRANSLATE_LANGUAGES"
    for i in "${LIST[@]}"; do
        koha-translate --install $i
    done
}

is_exists_db () {
    # TODO: fix hardcoded database name
    is_exists_db=`mysql -h $DB_HOST -u root -p$DB_ROOT_PASSWORD -e "show databases like 'koha_$LIBRARY_NAME';"`
    if [ -z "$is_exists_db" ]
    then
        return 1
    else
        return 0
    fi
}

update_apache2_conf () {
    echo "*** Creating /etc/apache2/sites-available/${LIBRARY_NAME}.conf"
    if [ -n "$DOMAIN" ]
    then
        # Default script will always put 'InstanceName':
        # http://{INTRAPREFIX}{InstanceName}{INTRASUFFIX}{DOMAIN}:{INTRAPORT}
        # Below function does NOT covers all cases, but it works for a simple one:
        # OPAC => https://library.example.com
        # Intra => https://library.admin.example.com

        envsubst < /docker/templates/koha.conf > /etc/apache2/sites-available/${LIBRARY_NAME}.conf
    else 
        # TODO1: understand why whith this new version the automatic generation of config file looks like not working, even thouth 'INTRAPORT' variable is good
        # TODO2: remove hardvoded values of 'templates/koha.conf' and unify it with 'templates/koha-no-domain.conf'
        envsubst < /docker/templates/koha-no-domain.conf > /etc/apache2/sites-available/${LIBRARY_NAME}.conf
    fi
    a2ensite ${LIBRARY_NAME}
}

create_db () {
    echo "*** Creating database..."
    while ! mysqladmin ping -h"$DB_HOST" --silent; do
        echo "*** Database server still down. Waiting $SLEEP seconds until retry"
        sleep $SLEEP
    done
    if is_exists_db
    then
        echo "*** Database already exists"
        echo "$LIBRARY_NAME:root:$DB_ROOT_PASSWORD:koha_$LIBRARY_NAME:$DB_HOST" > /etc/koha-passwd
        koha-create --use-db $LIBRARY_NAME --passwdfile /etc/koha-passwd
        rm -fr /etc/koha-passwd
        # Needed because 'koha-create' restarts apache and puts process in background"
        service apache2 stop
        echo "*** Manual indexing is needed..."
        koha-rebuild-zebra -v --full $(/usr/sbin/koha-list)
    else
        echo "*** koha-create with db"
        koha-create --create-db $LIBRARY_NAME
        # Needed because 'koha-create' restarts apache and puts process in background"
        service apache2 stop
        fix_database_permissions
    fi
}

enable_httpd_modules () {
    echo "*** Enabling httpd modules..."
    rm -R /var/www/html/
    a2enmod rewrite \
      cgi \
      headers \
      proxy_http \
      && a2dissite 000-default
}

enable_plack () {
    echo "*** Enabling and starting plack..."
    koha-plack --enable ${LIBRARY_NAME}
}

start_koha() {
    echo "*** Starting koha with plack..."
    koha-plack --start $LIBRARY_NAME
    echo "*** Starting indexer..."
    koha-indexer --start $LIBRARY_NAME 
    echo "*** Starting zebra..."
    koha-zebra --start $LIBRARY_NAME
    echo "*** Starting apache in foreground..."
    apachectl -D FOREGROUND
}

# 1st docker container execution
if [ ! -f /etc/configured ]; then
    echo "*** Running first time configuration..."
    enable_httpd_modules
    update_koha_database_conf
    create_db
    enable_plack
    update_koha_sites
    update_httpd_listening_ports
    install_koha_translate_languages

    update_apache2_conf
    log_database_credentials
    date > /etc/configured
else
    # 2nd+ executions
    echo "*** Looks already configured"
fi

start_koha
