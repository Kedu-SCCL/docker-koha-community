#!/bin/bash

function check_env_file {
if [ -e .env ]; then
    source .env
else
    echo "Please set up your .env file before starting your environment."
    exit 1
fi
}

function update_nginx_template {
    FILE_NOT_FOUND="404: Not Found"
    TMP_PATH=/tmp/$VOLUME_PROXY_TEMPLATE_FILE
    curl ${PROXY_TEMPLATE_DOWNLOAD_URL} > $TMP_PATH
    if ! grep -q "$FILE_NOT_FOUND" $TMP_PATH; then
        sudo mv $TMP_PATH $VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_TEMPLATE_FILE
    else
        echo "Unable to download new version of Nginx template, using old one"
    fi
}

function start_proxy {
if [ ! -d "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_CONF" ]
then
    sudo mkdir -p "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_CONF"
fi
if [ ! -d "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_VHOST" ]
then
    sudo mkdir -p "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_VHOST"
fi
if [ ! -d "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_HTML" ]
then
    sudo mkdir -p "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_HTML"
fi
if [ ! -d "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_CERTS" ]
then
    sudo mkdir -p "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_CERTS"
fi
if [ ! -d "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_HTPASSWD" ]
then
    sudo mkdir -p "$VOLUME_PATH/$PROXY_NAME/$VOLUME_PROXY_HTPASSWD"
fi

# Download the latest version of nginx.tmpl
update_nginx_template
}

function start_db {
if [ ! -d "$VOLUME_PATH/$DB_NAME/$VOLUME_DB_DATA" ]
then
    sudo mkdir -p "$VOLUME_PATH/$DB_NAME/$VOLUME_DB_DATA"
fi
}

function start_db {
if [ ! -d "$VOLUME_PATH/$DB_NAME/$VOLUME_DB_DATA" ]
then
    sudo mkdir -p "$VOLUME_PATH/$DB_NAME/$VOLUME_DB_DATA"
fi
}

function start_app {
# app
if [ ! -d "$VOLUME_PATH/$APP_NAME/$APP_VOLUME_KOHA" ]
then
    sudo mkdir -p "$VOLUME_PATH/$APP_NAME/$APP_VOLUME_KOHA"
fi
}

########################################

check_env_file

start_proxy

start_db

start_app

docker-compose up -d
