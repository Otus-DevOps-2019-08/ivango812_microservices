# ivango812_microservices
ivango812 microservices repository

# Lesson 15

Studying Docker - basics.

```
docker images - Images list
docker images -a - All images list
docker ps # Containers list running
docker ps -a # Containers list all

docker build -t <repo>:<tag> <path to Dockerfile> # Build image from Dockerfile
docker commit <u_container_id> <image_name> # create image from container

docker run -rm <image> # Run container from image and remove container after stop
docker start <container_id>
docker stop <container_id> 
dcoker attach <u_container_id> # attach terminal to running container
docker exec -it -rm <container_id> <command> # Run command inside container in interactive mode

docker rm <container_id> # Remove container
docker rm -f <container_id> # Force container remove
docker rmi <image_name> # Remove image
docker rmi -f <image_name> # Force remove image
docker rm $(docker ps -q) # remove all running containers
docker rm $(docker ps -a -q) # remove all containers (running and stopped)
docker rmi $(docker images) # remove all images

docker login
docker tag reddit:latest <your-login>/otus-reddit:1.0 # add tag to the image
docker push <your-login>/otus-reddit:1.0 # push to docker hub

docker inspect <your-login>/otus-reddit:1.0 # inspect image

docker run --name reddit -d -p 9292:9292 <your-login>/otus-reddit:1.0 # expose port 9292 and map in on 9292 external port
```

Change GCP PROJECT

```
export GOOGLE_PROJECT=docker-258721
```

Create host with docker engine in GCP:

```
docker-machine create --driver google --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts --google-machine-type n1-standard-1 --google-zone europe-west1-b docker-host
```


```
docker-machine env docker-host
docker-machine ls
```

Export VARIABLES into ENVIRONMENT to work with the docker-host we just created:

```
eval $(docker-machine env docker-host)
```

Compare difference of process tree of docker container and docker host machine:

```
docker run --rm -ti tehbilly/htop
docker run --rm --pid host -ti tehbilly/htop
```

Docker container has isolated PIDs, main PID=1 when at the docker host is not =1 (PID=618 for example) and container doesn't see other processes only PID=1 and its children.

```
gcloud compute firewall-rules create reddit-app --project=<project_id> --allow tcp:9292 --target-tags=docker-machine --description="Allow PUMA connections" --direction=INGRESS
```

Create terraform file for instances creation https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/docker-2/docker-monolith/infra/main.tf


Helps to install terraform if you've got on macOS Catalina `Error: Permission denied @ apply2files - /usr/local/share/Library/Caches/Yarn/v4/npm...`

```
sudo yarn cache clean
brew cleanup
brew install terraform
```

# Lesson 16

Docker-3


## Environment variables


Define enironment variable in Dockerfile:

```
...
ENV COMMENT_DATABASE_HOST comment_db 
...
```

Redefine environment variable as the container run:

```
docker run -d --network=reddit --network-alias=comment -e COMMENT_DATABASE_HOST=comment_db2 ivango/comment:1.0
```

## Optimizition Dockerfile

Change base image for `ui`

from

```
FROM ubuntu:16.04 

RUN apt-get update \
    && apt-get install -y ruby-full ruby-dev build-essential \ 
    && gem install bundler --no-ri --no-rdoc
...
```

on

```
FROM alpine:3.7

RUN apk update && apk upgrade \
    && apk add --update --no-cache build-base ruby ruby-json ruby-bundler ruby-dev \
    && rm -rf /var/cache/apk/* \
    && gem install bundler --no-ri --no-rdoc
...
```

## Linter

Install linter https://github.com/hadolint/hadolint

```
brew install hadolint
```

Run

```
hadolint ui/Dockerfile
```

Fixing Dockerfile according with linter recomedations (ui/Dockerfile)[https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/docker-3/src/ui/Dockerfile]

## Networks

Create a new `bridge`-type network:

```
docker network create reddit
dcoker network ls
```

Run container in the created network:
```
docker run -d --network=reddit --network-alias=post_db --network-alias=comment_db mongo:latest
```


## Volumes

Create volume

```
docker volune create reddit_db
```

Run container with volume

```
docker run -d --network-alias=comment_db -v reddit_db:/data/db mongo:latest
```

## Delete comtainers & images

```
docker rm $(docker ps -q)
```

```
docker rmi $(docker images -q)
```


# Lesson 17

Studying Docker Networks & Docker Compose


## Docker Networks

Network drivers:

`Bridge` - Default network driver.

`Host` - For standalone containers, remove network isolation between the container and the Docker host, and use the host’s networking directly.

`Overlay` - Overlay networks connect multiple Docker daemons together and enable swarm services to communicate with each other. You can also use overlay networks to facilitate communication between a swarm service and a standalone container, or between two standalone containers on different Docker daemons. This strategy removes the need to do OS-level routing between these containers.

`Macvlan` - Macvlan networks allow you to assign a MAC address to a container, making it appear as a physical device on your network. The Docker daemon routes traffic to containers by their MAC addresses. Using the macvlan driver is sometimes the best choice when dealing with legacy applications that expect to be directly connected to the physical network, rather than routed through the Docker host’s network stack.

`None` - For this container, disable all networking. Usually used in conjunction with a custom network driver.


```
docker network

Usage:	docker network COMMAND

Manage networks

Commands:
  connect     Connect a container to a network
  create      Create a network
  disconnect  Disconnect a container from a network
  inspect     Display detailed information on one or more networks
  ls          List networks
  prune       Remove all unused networks
  rm          Remove one or more networks
```


## Docker Volumes


https://docs.docker.com/storage/volumes/

```
$ docker volume 

Usage:	docker volume COMMAND

Manage volumes

Commands:
  create      Create a volume
  inspect     Display detailed information on one or more volumes
  ls          List volumes
  prune       Remove all unused local volumes
  rm          Remove one or more volumes
```

`Dockerfile`

```
container_name:
  volumes:
    - volume_name:/path/inside/container:rw

volumes:
  volume_name:
```

`rw` means read & write mode
`ro` means readonly mode

Also you can mount volume while `docker run` commad:
```
docker run -v nginx-vol:/usr/share/nginx/html:ro <container_id>
# or
docker run --volume -v nginx-vol:/usr/share/nginx/html:ro
```

```
docker run --mount source=myvol2,target=/app
```

## Docker Compose

Version in `docker-compose.yml` file shows which Compose file versions support specific Docker releases: https://docs.docker.com/compose/compose-file/

If we want to set project name (container prefix) for running containers use:

```
docker-compose -p micro up -d
# or
docker-compose --project-name micro up -d
```
Set project-name `micro`


## Difference between CMD and ENTRYPOINT

https://habr.com/ru/company/southbridge/blog/329138/

```
FROM ubuntu:16.04
ENTRYPOINT ["/bin/echo"]
CMD ["Hello"]
```

Produce:

```
$ docker build -t test .
$ docker run test
Hello
```

Default command for `ENTRYPOINT` - `/bin/sh -c`

In other words - `ENTRYPOINT` it's a command, `CMD` - arguments for this command.


## Difference betweeen COPY and ADD

`ADD` do more then `COPY`
`ADD` can copy from `url` or unpack archive file (identity, gzip, bzip2 или xz)

Use `COPY` if you don't need `ADD` magic

`docker-compose.override.yml` docker reads after `docker-compose.yml` and overrides options, so you don't need to dublicate parameners from `docker-compose.yml` in `docker-compose.override.yml`


# Lesson 19


Create GCP instance for Gitlab

```
terraform apply -auto-approve
```

Install Docker and attach to docker-machine

```
docker-machine create --driver google \
  --google-project docker-258721 \
  --google-zone europe-west1-b \
  --google-use-existing \
  gitlab-ce

export GITLAB_EXTERNAL_IP=35.205.182.43
docker-compose config

eval $(docker-machine env gitlab-ce)
docker-machine ssh gitlab-ce
exit

docker-compose up -d
```

Create runner

```
docker run -d --name gitlab-runner --restart always \ 
-v /srv/gitlab-runner/config:/etc/gitlab-runner \ 
-v /var/run/docker.sock:/var/run/docker.sock \ 
gitlab/gitlab-runner:latest
```

Register Runner

```
docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false
```

## Dynamic environment




## Deployment

Settings > CI/CD > Variables

File
GOOGLE_APPLICATION_CREDENTIALS
credentials.json content


Для сборки образа нужно изменить конфиг раннера `config.toml`

Заходим на хост gitlab-ci
Заходим в контейнер раннера
Находим файл `config.toml`


```
[[runners]]
  executor = "docker"
  [runners.docker]
    privileged = true
```


## Deploy

Создать хост с докером
Запустить контейнер
Настроить домен


Как удалять старые артефакты?
Как прибивать старые хосты?
Когда нужно собирать новый образ?


При запуске без оркестратора через `docker-compose up`, если docker container выел весь проц/память, то VM может стать совсем недоступным, поможет только ребут

В случае с оркестрацией можно использовать:

`docker-compose.yml`
```
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 50M
        reservations:
          cpus: '0.25'
          memory: 20M
```


Подключение к удаленной docker-машине

нужно в окружение gitlab закинуть TSL сертификаты:

```
docker-machine config staging-docker
--tlsverify
--tlscacert="/Users/me/.docker/machine/machines/staging-docker/ca.pem"
--tlscert="/Users/me/.docker/machine/machines/staging-docker/cert.pem"
--tlskey="/Users/me/.docker/machine/machines/staging-docker/key.pem"
-H=tcp://104.155.2.98:2376
```

```
 variables:
    DOCKER_HOST: tcp://104.155.2.98:2376
    DOCKER_TLS_VERIFY: 1
    DOCKER_CERT_PATH: "/certs"
  script:
    - echo 'Deploy' 
    - echo "$TLSCACERT" > $DOCKER_CERT_PATH/ca.pem
    - echo "$TLSCERT" > $DOCKER_CERT_PATH/cert.pem
    - echo "$TLSKEY" > $DOCKER_CERT_PATH/key.pem
    - docker run -d -p 9292:9292 $REGISTRY_USER/reddit:$CI_COMMIT_SHORT_SHA
```



apt update && apt install -y procps nano telnet net-tools iputils-ping

cd /etc/nginx/
mkdir sites-available sites-enabled

nano sites-available/branch_name
```
server {
    listen 80;
    server_name branch_name.dev.domain.com;
    location / {
        #proxy_pass http://172.17.0.2:9292;
        proxy_pass http://container_name:9292;
    }
}
```
ln -s /etc/nginx/sites-available/test.site /etc/nginx/sites-enabled/test.site

add to nginx.conf

nano nginx.conf
```
    include /etc/nginx/sites-enabled/*;
```
nginx -s reload


```
docker network create staging
```

docker-compose -f docker-compose-nginx.yml up -d


nginx.conf

server {
    listen 80;
    server_name branch_name.dev.domain.com;
    location / {
        proxy_pass http://reddit-f719612a:9292;
        #proxy_pass http://container_name:9292;
    }
}

дефолтная сеть не резолвит контейнеры по именам, доступ только по ip
нужно создать свою сеть чтобы можно было обращаться по именам контейнеров
