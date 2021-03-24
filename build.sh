#!/bin/bash

# Script to build docker image

# ./build.sh --registry docker-registry.kedu.cat --image koha-community --version 0.0.1

set -e

DOCKERFILE=Dockerfile
PATH_BUILD_CONTEXT=.

# Each pair param/key count as 2
if [ "$#" -lt 3 ]; then
    printf "3 parameters are mandatory\nExample:\n./build.sh --registry docker-registry.kedu.cat --image koha-community --version 0.0.1\n"
    exit 1
else
    while [ $# -gt 0 ]; do
        if [[ $1 == *"--"* ]]; then
            v="${1/--/}"
            declare $v="$2"
        fi
        shift
    done
fi

LOCAL_TAG=localhost/$image:$version

docker login $registry

docker build -f $DOCKERFILE -t $LOCAL_TAG $PATH_BUILD_CONTEXT
docker tag $LOCAL_TAG $registry/$image:$version
docker push $registry/$image:$version
