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
