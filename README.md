# django-k8s
Deploying Django v5 using Kubernetes on Digital Ocean

### Docker Compose

Using `docker compose` we can define and run multi container applications. For example we want to run our Django application as well as 
our PostgreSQL database then we can define multiple services in *docker-compose.yml* file and run them simultaneously in multiple 
containers.

A *docker-compose.yml* file consists of services, in our case there would be two services as of now,

1. Django project itself running through gunicorn & asgi
2. PostgreSQL DB connecting with Django project

We can later on add more services and do `docker compose up --build` and that build and make our defined services up and running.

For running our Django project we have defined some bash scripts like,

1. *migrate.sh* -> For running our Django migrations everytime we spawn a new container.
2. *entrypoint.sh* -> For actually running our Django application using gunicorn

We can either define all these files in the *Dockerfile* in `RUN` commands as `chmod +x /app/migrate.sh && chmod +x /app/entrypoint.sh 
& sh /app/migrate.sh && sh /app/entrypoint.sh` but these seems too much in a place and if anything breaks then it will be hard to debug, so we will be running the migrate(setup commands) and the actual entrypoint of our app(gunicorn server) separately inside 
*docker-compose.yml*

Now to be able to run these commands from *docker-compose.yml* we need to use some lines of *yml* syntax that will allow us to run 
multiple bash commands,

```
version: "3.9"

services:
  web:
    depends_on: postgres_db
    build:
      dockerfile: Dockerfile
      context: ./web
    image: django-k8s:1.10  # custom name of our image
    env_file:
      - web/.env
    environment:
      - PORT=8080
    ports:
      - 8000:8080
    command:
      - /bin/sh
      - -c
      - |
        chmod +x /app/migrate.sh
        sh /app/migrate.sh
        sh /app/entrypoint.sh

  postgres_db:
    image: postgres
    ...
```

The main attraction in the above *docker-compose.yml* contents are,

```
    command:
      - /bin/sh
      - -c
      - |
        chmod +x /app/migrate.sh
        sh /app/migrate.sh
        sh /app/entrypoint.sh

```

This was something that I struggled with earlier on how to write multiple bash commands in a single `command` clause in the compose 
file, then I took reference from [https://www.baeldung.com/ops/docker-compose-multiple-commands](https://www.baeldung.com/ops/docker-compose-multiple-commands), there are few other ways listed on this link which can help with writing multi-line command
in compose file.

### PostgreSQL Docker Service

Some of the major points to notice in the postgres image of the docker compose services are,

1. environment variables
2. `healthcheck` command

We will go through both the points.

First of all the environment variables, so PostgreSQL image on [Docker Hub](https://hub.docker.com/_/postgres) allows us to provision a 
whole database just using some environment variables and few key value pairs in yml file.

Environment variables are,

1. `POSTGRES_DB`
2. `POSTGRES_USER`
3. `POSTGRES_PASSWORD`
4. `POSTGRES_HOST`
5. `POSTGRES_PORT`

Without these environment variables, *postgres* image on Docker won't create the database and won't even start the PostgreSQL server
to connect to in our other apps. Note that these variables name are case sensitive and any mistake in spelling can make you wonder what
went wrong when things are not working.

Second is the `healthcheck` command, this is very useful when you have other services depending upon your `postgres` DB service,
suppose you have a web application that consumes the Postgres Database, in that case you want your DB to up and running first and then
all the other services which uses Postgres to get up after. Now you might be wondering then this is what the docker compose 
`depends_on` provides us with but here is a catch, PostgreSQL DB service would be marked as up as soon as the container is spawned but 
starting the PostgreSQL DB server and healtchecks takes a little time and there might be cases where the other services would start 
earlier and would try connecting with the DB and fail at that time, so to avoid such situation, we need to make sure that we wait until
all health checks in postgres are done and then service is up.

For this we will use the `pg_ready` healthcheck command,

```
services:
  postgres_db:
    image: postgres
    restart: always
    ports:
      - 5432:5432
    env_file:
      - web/.env
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: pg_isready -h postgres_db
      interval: 1s
      timeout: 5s
      retries: 10s

volumes:
  postgres_data:
    driver: local
```

Docker compose provides us with `healthcheck` which can be used to run commands for this particular service to know the health status
and until this passes the service won't be marked as up.

To break down the `healthcheck` key,

1. `test` -> the actual command to run which postgres already provides - `pg_isready` and the `-h postgres_db` is the hostname arg
telling to use the config of the same postgres db which is `postgres_db`

2. `interval` -> intervals at which this test command will run

3. `timeout` -> time in seconds after which if a command does not respond then it will be marked as failed

4. `retries` -> number of times to retry this test command for this service's healthcheck

Some other important points are,

1. `ports:` this actually is a mapping of target and published port which tells which port to open in the container and which one to target in the host machine(our local computer or server on which docker container is running)

2. `volumes:` this makes sure that the database data is intact even if the service goes down because the volume is not affected if any
of the service in the docker goes down which is very obvious, we won't want our data to be effected if the DB is down or crashes.

3. `restart:` this tells when and at what triggers to restart the service, in our case we have defined `always` which basically tells
whenever the service goes down or crashes or is shutdown, keep restarting the *postgres_db* service. There are other options as well 
like `unless-stopped`
