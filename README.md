# docker-koha-community

Build docker image to install Koha Community

## Install local environment

Below the quick and dirty instructions to have a local docker image up and running

1.(Optional) cleanup

```
docker stop koha && docker rm koha
```

2.Create container

```
docker run --name koha \
  -ti \
  --cap-add=SYS_NICE \
  --cap-add=DAC_READ_SEARCH \
  -d debian:testing
```

3.Install packages

```
docker exec -ti koha bash

apt-get update

apt-get install -y wget gnupg vim

wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -

echo 'deb http://debian.koha-community.org/koha stable main' | tee /etc/apt/sources.list.d/koha.list

apt-get update
```

This step will take around 14':

```
apt-get install -y koha-common
```

4.More install and configuration

```
cp /etc/koha/koha-sites.conf /etc/koha/koha-sites.conf.bak

vim /etc/koha/koha-sites.conf
```

Content:

```
# NOTE: for a complete list of valid options please read koha-create(8)

## Apache virtual hosts creation variables
#
# Please note that the URLs are built like this:
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
DOMAIN=".kedu.cat"
INTRAPORT="80"
INTRAPREFIX=""
INTRASUFFIX=".admin"
OPACPORT="80"
OPACPREFIX=""
OPACSUFFIX=""

## Default data to be loaded
#
# DEFAULTSQL: filename
# Specify an SQL file with default data to load during instance creation
# The SQL file can be optionally compressed with gzip
# default: (empty)
DEFAULTSQL=""

## Zebra global configuration variables
#
# ZEBRA_MARC_FORMAT: 'marc21' | 'normarc' | 'unimarc'
# Specifies the MARC records format for indexing
# default: 'marc21'
ZEBRA_MARC_FORMAT="marc21"

# ZEBRA_LANGUAGE: 'cs' | 'en' | 'es' | 'fr' | 'gr' | 'nb' | 'ru' | 'uk'
# Primary language for Zebra indexing
# default: 'en'
ZEBRA_LANGUAGE="en"

## Memcached global configuration variables
#
# USE_MEMCACHED: 'yes' | 'no'
# Make the created instance use memcached. Can be altered later.
# default: 'yes'
USE_MEMCACHED="no"

# MEMCACHED_SERVERS: comma separated list of memcached servers (ip:port)
# Specify a list of memcached servers for the Koha instance
# default: '127.0.0.1:11211'
#MEMCACHED_SERVERS="127.0.0.1:11211"

# MEMCACHED_PREFIX:
# Specify a string to be used as prefix for defining the memcached namespace
# for the created instance.
# default: 'koha_'
#MEMCACHED_PREFIX="koha_"
```

More commands:

```
a2enmod rewrite cgi

service apache2 restart

apt-get install -y mariadb-server

/usr/bin/mysqld_safe 2>&1&
```

5.Create database

```
koha-create --create-db koha
```

Expected output similar to:

```
Koha instance is empty, no staff user created.
[....] Restarting Apache httpd web server: apache2AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.28.0.3. Set the 'ServerName' directive globally to suppress this message
. ok 
[ ok ] Starting Koha indexing daemon for libraryname:.
```

The username of the database connection will be **koha_koha**

6.Get database credentials password

```
koha-passwd koha
```

Take note of the output:

```
LlS1mOdJRtqRP0PX
```

And press 'Enter'

7.Install translation

```
koha-translate --install ca-ES
```

8.Install needed perl packages

```
apt-get install -y perlbrew

perlbrew install-cpanm
```

Output similar to:

```
/root/perl5/perlbrew/bin/cpanm
```

Install perl packages

```
/root/perl5/perlbrew/bin/cpanm install JSON::Validator
/root/perl5/perlbrew/bin/cpanm install Mojolicious::Plugin::OpenAPI
```

9.Exit

```
exit
```

TODO: clean this section

docker inspect --format '{{ .NetworkSettings.IPAddress }}' koha

	172.17.0.2

sudo vim /etc/hosts

172.17.0.2      koha.myDNSname.org
172.17.0.2      koha-intra.myDNSname.org

sudo service dnsmasq restart

	Test it

http://koha.myDNSname.org
http://koha-intra.myDNSname.org


User: koha_koha
Password: LlS1mOdJRtqRP0PX
Click "Login"

Select "ca-ES"
Click "Continue..."

Click "Continue..."

Click "Continue..."

Click "Continue..."

Click "Continue..."

Click "Continue..."

Click "Continue..."

Select "Marc21"
Click "Continue..."

Select all
Click "Import"

4'

Error:
[Thu May 9 13:53:14 2019] install.pl: DBD::mysql::st execute failed: Incorrect integer value: '' for column `koha_koha`.`auth_subfield_structure`.`linkid` at row 148 at /usr/share/perl5/DBIx/RunSQL.pm line 278, <$args{...}> chunk 1. 
Click "setup...."

Congratulations message
Click link

Full admin data
IMPORTANT: here you setup the account
Library: Centerville
Patron category: Board
Click "Envia"

Leave default values
Click "Envia"

Click "Start using koha"







