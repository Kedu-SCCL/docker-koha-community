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
    echo "*** Modifying /etc/koha/koha-sites.conf"
    sed -i "s/_DOMAIN_/$DOMAIN/g" /etc/koha/koha-sites.conf
    sed -i "s/_INTRAPORT_/$INTRAPORT/g" /etc/koha/koha-sites.conf
    sed -i "s/_INTRAPREFIX_/$INTRAPREFIX/g" /etc/koha/koha-sites.conf
    sed -i "s/_INTRASUFFIX_/$INTRASUFFIX/g" /etc/koha/koha-sites.conf
    sed -i "s/_OPACPORT_/$OPACPORT/g" /etc/koha/koha-sites.conf
    sed -i "s/_OPACPREFIX_/$OPACPREFIX/g" /etc/koha/koha-sites.conf
    sed -i "s/_OPACSUFFIX_/$OPACSUFFIX/g" /etc/koha/koha-sites.conf
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
    sed -i "s/_DB_HOST_/$DB_HOST/g" /etc/mysql/koha-common.cnf
    sed -i "s/_DB_ROOT_PASSWORD_/$DB_ROOT_PASSWORD/g" /etc/mysql/koha-common.cnf
    sed -i "s/_DB_PORT_/$DB_PORT/g" /etc/mysql/koha-common.cnf
}

fix_database_permissions () {
    echo "*** Fixing database permissions to be able to use an external server"
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

install_koha_translate_languages () {
    echo "*** Installing koha translate languages defined by KOHA_TRANSLATE_LANGUAGES"
    IFS=',' read -ra LIST <<< "$KOHA_TRANSLATE_LANGUAGES"
    for i in "${LIST[@]}"; do
        koha-translate --install $i
    done
}

is_exists_db () {
    # TODO: fix hardcoded database name
    is_exists_db=`mysql -h $DB_HOST -u root -p$DB_ROOT_PASSWORD -e "show databases like 'koha_koha';"`
    if [ -z "$is_exists_db" ]
    then
        return 1
    else
        return 0
    fi
}

backup_db () {
    # TODO: review and fix it
    mysqldump -h $DB_HOST -u root -p$DB_ROOT_PASSWORD --databases koha_$LIBRARY_NAME > /root/backup.sql
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASSWORD -e "drop database koha_$LIBRARY_NAME;"
}

# 1st docker container execution
if [ ! -f /etc/configured ]; then
    echo "*** Running first time configuration..."
    echo "*** Installing koha translate languages..."
    install_koha_translate_languages
    update_koha_sites
    update_httpd_listening_ports
    update_koha_database_conf
    while ! mysqladmin ping -h"$DB_HOST" --silent; do
        echo "*** Database server still down. Waiting $SLEEP seconds until retry"
        sleep $SLEEP
    done
    if is_exists_db
    then
        echo "*** Database already exists"
        echo "*** TODO: provide a fix"
        # issue:
        # failed to load external entity "/etc/koha/sites/koha/koha-conf.xml"
        # date && time koha-mysql $LIBRARY_NAME < koha.sql
        # koha-upgrade-schema $LIBRARY_NAME
        # koha-rebuild-zebra -f -v $LIBRARY_NAME
        #echo "*** Backup of database..."
        #backup_db
    else
        echo "*** koha-create with db"
        koha-create --create-db $LIBRARY_NAME
    fi
    fix_database_permissions
    a2dissite 000-default
    rm -R /var/www/html/
    service apache2 reload
    log_database_credentials
    date > /etc/configured
    # Needed because 'koha-create' restarts apache and puts process in background"
    service apache2 stop
: <<'END_COMMENT'
    # TODO: review and fix it
    if is_exists_db
    then
        # +- 5'
        echo "*** Restoring backup. It cant take up 5 minutes..."
        koha-mysql $LIBRARY_NAME < /root/backup.sql
        echo "*** Upgrading schema..."
        koha-upgrade-schema $LIBRARY_NAME
        echo "*** Rebuilding zebra..."
        koha-rebuild-zebra -f -v $LIBRARY_NAME
    fi 
END_COMMENT
     
else
    # 2nd+ executions
    echo "*** Looks already configured"
    echo "*** Starting zebra..."
    koha-zebra --start $LIBRARY_NAME
    echo "*** Starting zebra indexer..."
    koha-indexer --start $LIBRARY_NAME 
fi

# Common
echo "*** Starting apache in foreground..."
apachectl -D FOREGROUND


