FROM debian:testing
MAINTAINER Kedu SCCL "info@kedu.coop"

RUN apt-get update && apt-get install -y \
  wget \
  gnupg

RUN wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -

RUN echo 'deb http://debian.koha-community.org/koha stable main' | tee /etc/apt/sources.list.d/koha.list

RUN apt-get update && apt-get install -y \
  koha-common

RUN    a2enmod rewrite \
           headers \
           proxy_http \
           cgi \
    && a2dissite 000-default

RUN mkdir /docker

COPY entrypoint.sh /docker/

COPY templates /docker/templates

RUN chmod +x /docker/entrypoint.sh

ENTRYPOINT ["/docker/entrypoint.sh"]
