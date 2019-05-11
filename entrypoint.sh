#!/bin/bash

# Default values for environment variables
LIBRARY_NAME="${LIBRARY_NAME:-defaultlibraryname}"
SLEEP="${SLEEP:-45}"
DOMAIN="${DOMAIN:-}"
INTRAPORT="${INTRAPORT:-8080}"
INTRAPREFIX="${INTRAPREFIX:-}"
INTRASUFFIX="${INTRASUFFIX:-}"
OPACPORT="${OPACPORT:-80}"
OPACPREFIX="${OPACPREFIX:-}"
OPACSUFFIX="${OPACSUFFIX:-}"
DB_PORT="${DB_PORT:-3306}"

update_koha_sites () {
    echo "Modifying /etc/koha/koha-sites.conf"
    sed -i "s/_DOMAIN_/$DOMAIN/g" /etc/koha/koha-sites.conf
    sed -i "s/_INTRAPORT_/$INTRAPORT/g" /etc/koha/koha-sites.conf
    sed -i "s/_INTRAPREFIX_/$INTRAPREFIX/g" /etc/koha/koha-sites.conf
    sed -i "s/_INTRASUFFIX_/$INTRASUFFIX/g" /etc/koha/koha-sites.conf
    sed -i "s/_OPACPORT_/$OPACPORT/g" /etc/koha/koha-sites.conf
    sed -i "s/_OPACPREFIX_/$OPACPREFIX/g" /etc/koha/koha-sites.conf
    sed -i "s/_OPACSUFFIX_/$OPACSUFFIX/g" /etc/koha/koha-sites.conf
}

update_httpd_listening_ports () {
    echo "Fixing apache2 listening ports"
    if [ "80" != "$INTRAPORT" ]; then
        echo "Listen $INTRAPORT" >> /etc/apache2/ports.conf
    fi
    if [ "80" != "$OPACPORT" ] && [ $INTRAPORT != $OPACPORT ]; then
        echo "Listen $OPACPORT" >> /etc/apache2/ports.conf
    fi
}

update_koha_database_conf () {
    echo "Modifying /etc/mysql/koha-common.cnf"
    sed -i "s/_DB_HOST_/$DB_HOST/g" /etc/mysql/koha-common.cnf
    sed -i "s/_DB_ROOT_PASSWORD_/$DB_ROOT_PASSWORD/g" /etc/mysql/koha-common.cnf
    sed -i "s/_DB_PORT_/$DB_PORT/g" /etc/mysql/koha-common.cnf
}

fix_database_permissions () {
    echo "Fixing database permissions to be able to use an external server"
    # TODO: restrict to the docker container private IP
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

# 1st docker container execution
if [ ! -f /etc/configured ]; then
    #code that need to run only one time ....
    while ! mysqladmin ping -h"$DB_HOST" --silent; do
        echo "Database server still down. Waiting $SLEEP seconds until retry"
        sleep $SLEEP
    done
    update_koha_sites
    update_httpd_listening_ports
    update_koha_database_conf
    echo "Creating user and database"
    koha-create --create-db $LIBRARY_NAME
    fix_database_permissions
    a2dissite 000-default
    rm -R /var/www/html/
    # Let's make OPAC more easy to access
    sed -i 's/Include\ \/etc\/koha\/apache-shared-opac.conf/Include\ \/etc\/koha\/apache-shared-opac.conf\n\ \ \ Serveralias\ \*/g' /etc/apache2/sites-available/$LIBRARY_NAME.conf
    service apache2 reload
    log_database_credentials
    date > /etc/configured
    while true
    do
        # Needed because 'koha-create' restarts apache and puts process in background"
        sleep 3600
    done
fi

# 2nd+ executions
echo "Looks already configured"
log_database_credentials 
apachectl -D FOREGROUND
