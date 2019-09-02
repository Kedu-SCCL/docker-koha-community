#!/bin/bash

source .env

docker-compose down

remove_dir () {
    #if [ -d "$VOLUME_PATH/$DB_NAME" ]
    if [ -d "$1" ]
    then
        echo "Removing $1"
        read -p "Are you sure? [Y/y]" -n 1 -r
        echo    # (optional) move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            sudo rm -fr $1
        fi
    fi
}

remove_volume () {
    docker volume ls | grep $1
    exit_status=$?
    if [ $exit_status -eq 0 ]
    then
        docker volume rm $1
    fi
}

# proxy
remove_dir $VOLUME_PATH/$PROXY_NAME
remove_volume $VOLUME_PROXY_CONF
remove_volume $VOLUME_PROXY_VHOST
remove_volume $VOLUME_PROXY_HTML
remove_volume $VOLUME_PROXY_CERTS
remove_volume $VOLUME_PROXY_HTPASSWD

# db
remove_dir $VOLUME_PATH/$DB_NAME
remove_volume $VOLUME_DB_DATA

# app
remove_dir $VOLUME_PATH/$APP_NAME
remove_volume $APP_VOLUME_KOHA

