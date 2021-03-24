- [Introduction](#introduction)
- [For the impatients](#for-the-impatients)
- [Environment Variables](#environment-variables)
  - [DB_HOST](#DB_HOST)
  - [DB_ROOT_PASSWORD](#DB_ROOT_PASSWORD)
  - [DB_PORT](#DB_PORT)
  - [KOHA_TRANSLATE_LANGUAGES](#KOHA_TRANSLATE_LANGUAGES)
  - [LIBRARY_NAME](#LIBRARY_NAME)
  - [SLEEP](#SLEEP)
  - [DOMAIN](#DOMAIN)
  - [INTRAPORT](#INTRAPORT)
  - [INTRAPREFIX](#INTRAPREFIX)
  - [INTRASUFFIX](#INTRASUFFIX)
  - [OPACPORT](#OPACPORT)
  - [OPACPREFIX](#OPACPREFIX)
  - [OPACSUFFIX](#OPACSUFFIX)
- [Allowed volumes](#allowed-volumes)
- [Example with reverse proxy](#example-with-reverse-proxy)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

# Introduction

Koha 

[Koha community](https://wiki.koha-community.org/) with below features:

* Supports external database
* Supports multiple translation installations
* Internal and external (OPAC) URLs completely customizable

# For the impatients

1. Start the containers

```
sudo docker-compose up -d --build --force-recreate
```

2. Get the username and password for the post-install part. See below entries in the docker compose output:

```
====================================================
IMPORTANT: credentials needed to post-installation through your browser
Username: koha_koha
Password: type 'docker exec -ti d21a7f723205 koha-passwd koha' to display it
====================================================
```

3. Point your browsert to:

http://localhost:8080

And introduce the credentials annotated at step 3

4. Follow the steps in the browser. At one step you will create the admin credentials. Please annotate them for later use

5. Once you finished the post-install steps, you can login to:

Admin

http://localhost:8080

Public (OPAC)

http://localhost

In both cases the credentials are the ones annotated at step 5

# Environment Variables

## DB_HOST

Mandatory. Name of the database server. Should be reachable by koha container.

This image has been tested with mariadb server.

Example:

```
-e DB_HOST=koha-db
```

## DB_ROOT_PASSWORD

Mandatory. Password of "root" account of "DB_HOST" database server.

Example:

```
-e DB_ROOT_PASSWORD=secretpassword
```

## DB_PORT

Optional, if not provided set up to "3306".

Port where "DB_HOST" database server is listening.

Example:

```
-e DB_PORT=3307
```

## KOHA_TRANSLATE_LANGUAGES

Optional, if not provided set up to empty value.

Comma separated list of koha translations to be installed.

To get a full list of available translations:

1. Start the koha docker container

2. Connect to it (in this example the docker koha container is named "koha")

```
docker exec -ti koha bash
```

3. Get the list

```
koha-translate --list --available
```

Expected output similar to:

```
am-Ethi
ar-Arab
as-IN
az-AZ
be-BY
bg-Cyrl
bn-IN
ca-ES
cs-CZ
cy-GB
da-DK
de-CH
de-DE
el-GR
en-GB
en-NZ
eo
es-ES
eu
fa-Arab
fi-FI
fo-FO
fr-CA
fr-FR
ga
gd
gl
he-Hebr
hi
hr-HR
hu-HU
hy-Armn
ia
id-ID
iq-CA
is-IS
it-IT
iu-CA
ja-Jpan-JP
ka
km-KH
kn-Knda
ko-Kore-KP
ku-Arab
lo-Laoo
lv
mi-NZ
ml
mon
mr
ms-MY
my
nb-NO
ne-NE
nl-BE
nl-NL
nn-NO
oc
pbr
pl-PL
prs
pt-BR
pt-PT
ro-RO
ru-RU
rw-RW
sd-PK
sk-SK
sl-SI
sq-AL
sr-Cyrl
sv-SE
sw-KE
ta-LK
ta
tet
th-TH
tl-PH
tr-TR
tvl
uk-UA
ur-Arab
vi-VN
zh-Hans-CN
zh-Hant-TW
```

Example:

```
-e KOHA_TRANSLATE_LANGUAGES="ca-ES,es-ES"
```

## LIBRARY_NAME

Optional, if not provided set up to "defaultlibraryname".

String containing the library name, used by "koha-create --create-db" command.

In case that you place a reverse proxy such as [jwilder/nginx-proxy](https://wiki.koha-community.org/) this value should match "VIRTUAL_HOST" (and "LETSENCRYPT_HOST" if you are using HTTPS).

Example:

```
-e LIBRARY_NAME=mylibrary
```

## SLEEP

Optional, if not provided set up to "45".

Time in seconds that the koha image is waiting on to retry connection to external database

Example:

```
-e SLEEP=3
```

## DOMAIN

Optional, if not provided set up to empty value.

String to build the internal and external (OPAC) URLs:

```
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
```

## INTRAPORT

Optional, if not provided set up to "8080".

String to build the internal and external (OPAC) URLs:

```
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
```

## INTRAPREFIX

Optional, if not provided set up to empty value.

String to build the internal and external (OPAC) URLs:

```
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
```

## INTRASUFFIX

Optional, if not provided set up to empty value.

String to build the internal and external (OPAC) URLs:

```
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
```

## OPACPORT

Optional, if not provided set up to "80".

String to build the internal and external (OPAC) URLs:

```
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
```

## OPACPREFIX

Optional, if not provided set up to empty value.

String to build the internal and external (OPAC) URLs:

```
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
```

## OPACSUFFIX

Optional, if not provided set up to empty value.

String to build the internal and external (OPAC) URLs:

```
# OPAC:  http://<OPACPREFIX><INSTANCE NAME><OPACSUFFIX><DOMAIN>:<OPACPORT>
# STAFF: http://<INTRAPREFIX><INSTANCE NAME><INTRASUFFIX><DOMAIN>:<INTRAPORT>
```

# Allowed volumes

We recommend to map "/var/lib/koha".

Example:

```
-v ~/koha:/var/lib/koha
```

# Example with reverse proxy

1.Go to examples

```
cd examples
```

2.Get a ".env" file

```
cp .env.example .env
```

And adjust some settings, for instance:

* APP_DOMAIN
* APP_VIRTUAL_HOST
* APP_LETSENCRYPT_HOST
* DB_MYSQL_ROOT_PASSWORD
* APP_DB_ROOT_PASSWORD

3.Start the environment

```
./start.sh
```

# Troubleshooting

**TODO**

# Credits

Some ideas has been taken from [QuantumObject/docker-koha](https://github.com/QuantumObject/docker-koha)


