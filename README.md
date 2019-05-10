# docker-koha-community

Build docker image to install Koha Community

## (Temporary) Build the image

1.Get the code

```
cd ~
git clone git@gitlab.kedu.cat:kedu/docker-koha-community.git
```

2.Build the image, in this case we will name it "**localhost/koha:0.1**"

```
cd ~/docker-koha-community
docker build . -t localhost/koha:0.1
```

## Start docker containers and configure Koha

1.Create a **docker-compose.yaml** (one is provided) with below content:

```
version: '3.7'

services:

  koha-db:
    container_name: koha-db
    image: mariadb
    environment:
      MYSQL_ROOT_PASSWORD: koha

  koha:
    container_name: koha
    image: localhost/koha:0.1
    cap_add:
        - SYS_NICE
        - DAC_READ_SEARCH
    depends_on:
        - koha-db
    environment:
      LIBRARY_NAME: mylibrary
      SLEEP: 3
      INTRAPORT: 8080
      DB_HOST: koha-db
      DB_ROOT_PASSWORD: koha
    ports:
      - "80:80"
      - "8080:8080"
```

2.Start the containers

```
docker-compose up
```

3.Get the username and password for the post-install part. See below entries in the docker compose output:

```
====================================================
IMPORTANT: credentials needed to post-installation through your browser
Username: koha_mylibrary
Password: type 'docker exec -ti d21a7f723205 koha-passwd mylibrary' to display it
====================================================
```

4.Point your browsert to:

http://localhost:8080

And introduce the credentials annotated at step 3

5.Follow the steps in the browser. At one step you will create the admin credentials. Please annotate them for later use

6.Once you finished the post-install steps, you can login to:

Admin

http://localhost:8080

Public (OPAC)

http://localhost

In both cases the credentials are the ones annotated at step 5
