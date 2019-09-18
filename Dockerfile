#name of container: docker-koha-community
#versison of container: 0.1
FROM debian:testing
MAINTAINER Kedu SCCL "info@kedu.coop"

RUN apt-get update && apt-get install -y \
  wget \
  gnupg \
  mariadb-client-10.3 \
  perlbrew

RUN wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -

RUN echo 'deb http://debian.koha-community.org/koha stable main' | tee /etc/apt/sources.list.d/koha.list

RUN apt-get update && apt-get install -y \
  koha-common

RUN perlbrew install-cpanm

RUN /root/perl5/perlbrew/bin/cpanm install JSON::Validator

RUN /root/perl5/perlbrew/bin/cpanm install Mojolicious::Plugin::OpenAPI

RUN a2enmod rewrite cgi mpm_itk

# Koha specific stuff

COPY koha-sites.conf /etc/koha/koha-sites.conf

COPY koha-common.cnf /etc/mysql/koha-common.cnf

# TODO: create a ENV variable and move it to entrypoint.sh
#RUN koha-translate --install ca-ES

# TODO: see how this can be coordinated with $INTRAPORT and $OPACPORT
#EXPOSE 80 8080

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
