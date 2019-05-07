# docker-koha-community

Build docker image to install Koha Community

## Install

Below the quick and dirty instructions to have a local docker image up and running


1.(Optional) Cleanup

```
docker stop koha && docker rm koha
```

2.Start the container

```
docker run --name koha \
  --network=network-mariadb \
  -ti \
  --cap-add=SYS_NICE \
  --cap-add=DAC_READ_SEARCH \
  -d debian:testing
```

3.Connect to the container

```
docker exec -ti koha bash
```

4.Install packages

```
apt-get update

apt-get install wget gnupg vim

wget -q -O- https://debian.koha-community.org/koha/gpg.asc | apt-key add -

echo 'deb http://debian.koha-community.org/koha stable main' | tee /etc/apt/sources.list.d/koha.list

apt-get update
```

This last step takes a lot of time:

```
apt-get install koha-common
```

5.(Optional) Just in case commit the image

```
exit

docker ps | grep koha
```

Expected output similar to:

```
09799371eeed        debian:testing      "bash"                   8 minutes ago       Up 7 minutes                            koha
```

Commit the image:

```
docker commit 09799371eeed localhost/koha:0.1
```

In case that we want to restart the whole installation process but from this point:

```
docker run --name koha \
  --network=network-mariadb \
  -ti \
  --cap-add=SYS_NICE \
  --cap-add=DAC_READ_SEARCH \
  -d localhost/koha:0.1
```

6.Koha community post installation (command line)

```
docker exec -ti koha bash

cp /etc/koha/koha-sites.conf /etc/koha/koha-sites.conf.bak
```

At the moment we will **NOT** change this file

```
a2enmod rewrite cgi

service apache2 restart
```

7.Install mariadb server

```
apt-get install mariadb-server

/usr/bin/mysqld_safe 2>&1&

mysql_secure_installation
```

Accept all the proposed options

```
vim /etc/mysql/koha-common.cnf
```

Add password created in the "mysql_secure_installation" step

8.Koha post installation (command line)

Create the library, in this case we will use **libraryname**

```
koha-create --create-db libraryname
```

Expected output similar to:

```
...
Koha instance is empty, no staff user created.
[....] Restarting Apache httpd web server: apache2AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 172.28.0.3. Set the 'ServerName' directive globally to suppress this message
. ok
[ ok ] Starting Koha indexing daemon for libraryname:.

```

Create the password, take note of the output

```
koha-passwd libraryname
```

Expected output similar to:

```
WPZmVwqI5BQvyIEl
```

So in this case:

**Username**: koha_libraryname
**Password**: WPZmVwqI5BQvyIEl

9.Install perl package

```
install JSON::Validator
install Mojolicious::Plugin::OpenAPI
```

10.Configure DNS

In this case we will edit the docker host "/etc/hosts" file to match the previous step settings

Get docker container private IP address

```
docker inspect koha | grep IPAddress
```

Output similar to:

```
            "SecondaryIPAddresses": null,
            "IPAddress": "",
                    "IPAddress": "172.28.0.3",
```

Edit file:

```
sudo vim /etc/hosts
```

And add:

```
172.28.0.3      libraryname.myDNSname.org
172.28.0.3      libraryname-intra.myDNSname.org
```

11.Koha configuration (browser)

http://libraryname-intra.myDNSname.org

Introduce the credentials of step 8

Accept all the options presented

12.Test fronend

http://libraryname.myDNSname.org

## Manually start services

In case that we need to start the image again we need to follow below steps:

1.Start the container

```
docker start koha
```

2. Connect to the container

```
docker exec -ti koha bash
```

3. Start database

```
/usr/bin/mysqld_safe 2>&1&
```

4. Start apache

```
service apache2 start
```

5. Test it

http://libraryname-intra.myDNSname.org
http://libraryname.myDNSname.org


