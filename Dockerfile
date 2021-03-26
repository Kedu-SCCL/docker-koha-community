# Debian testing koha package buggy, for instance REST API not working out of the box
FROM debian:buster
MAINTAINER Kedu SCCL "info@kedu.coop"

ARG KOHA_VERSION=20.11
ARG PKG_URL=https://debian.koha-community.org/koha

RUN apt-get update && apt-get install -y \
  wget \
  gnupg

RUN if [ "${PKG_URL}" = "https://debian.koha-community.org/koha" ]; then \
        wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -; \
    fi

RUN echo "deb ${PKG_URL} ${KOHA_VERSION} main" | tee /etc/apt/sources.list.d/koha.list

RUN apt-get update && apt-get install -y \
  koha-common

RUN  a2enmod rewrite \
           headers \
           proxy_http \
           cgi \
    && a2dissite 000-default

RUN mkdir /docker

COPY entrypoint.sh /docker/

COPY templates /docker/templates

RUN chmod +x /docker/entrypoint.sh

ENTRYPOINT ["/docker/entrypoint.sh"]
