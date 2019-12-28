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


# Lesson 19 - Gitlab CI


### Create GCP instance with Docker for Gitlab

Get the list of available OS images in GCE
```shell script
gcloud compute images list --uri | grep ubuntu
```

Create GCP instance with Docker

```shell script
export PROJECT_ID="docker-258721"
docker-machine create --driver google \
  --google-zone europe-west3-c \
  --google-machine-type n1-standard-1 \
  --google-disk-size 100 \
  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-1604-xenial-v20170721 \
  --google-project $PROJECT_ID \
  gitlab-ce
```

Or create GCP Instance first (with terraform) and install Docker onto it: 

```shell script
docker-machine create --driver google \
  --google-project $PROJECT_ID \
  --google-zone europe-west1-b \
  --google-use-existing \
  gitlab-ce
```

Get IP of the docker-host we just created:

```shell script
docker-machine env gitlab-ce
```

Install and run Gitlab:

```shell script
mkdir gitlab-ci && cd gitlab-ci
export GITLAB_EXTERNAL_IP=$(docker-machine env gitlab-ce)
docker-compose config

eval $(docker-machine env gitlab-ce)
docker-machine ssh gitlab-ce
exit

docker-compose up -d
```

Then open http://<gitlab host ip>
Create password for `root` account.
Go to `Settings` turn off `Sign up enabled`.

Create new `Group` - `homework`
Create new `Project` in this group - `example`

Add `repository` we just created to our local project git:

```shell script
git remote add gitlab http://<your-vm-ip>/homework/example.git
```

### Create runner

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

## Create `.gitlab-ci.yml`

Then create `.gitlab-ci.yml` for our CI/CD pipeline:

### Stage `Build`

Use DinD(Docker in Docker) service to build app image:
Build image and push in to the registry in `hub.docker.com`

```shell script
...
build:
  image: docker:18.09
  stage: build
  only:
    - /^\d+\.\d+\.\d+/
    - branches
  services:
      - docker:18.09-dind
  variables:
    DOCKER_HOST: tcp://docker:2375/
    DOCKER_DRIVER: overlay2
  script:
    - docker --version
    - echo 'Building'
    - docker login -u $REGISTRY_USER -p $REGISTRY_PASSWORD
    - docker build -t $REGISTRY_USER/reddit:$CI_COMMIT_SHORT_SHA .
    - docker push $REGISTRY_USER/reddit:$CI_COMMIT_SHORT_SHA
...
```

### Stage `Test`

```shell script
...
before_script:
  - cd reddit
...
test_unit_job: 
  stage: test 
  services:
    - mongo:latest 
  script:
    - bundle install
    - ruby simpletest.rb
...
```

### Stage `Stage`

Let's create separated stage host for each git branch.

Create wildcard domain record for `*.dev.domain.com` which points on docker-host with `nginx`

Then add `nginx` container that plays role of `http-proxy` for each stage host

`gitlab-ci/infra/nginx/docker-compose-nginx.yml`:

```shell script
version: '3.3'
services:
  comment:
    image: nginx
    container_name: nginx
    ports:
        - 80:80
        # - 443:443
    volumes:
      # - "/etc/nginx/sites-enabled"
      - "/etc/nginx"
      - "/etc/nginx/certs"
      - "/var/log/nginx"
    networks:
      - staging

networks:
  staging:

```

Let's run `nginx` container

```shell script
docker-compose -f gitlab-ci/infra/nginx/docker-compose-nginx.yml up -d
```

Configure `nginx` to work with virtual sites:

```shell script
docker-machine ssh nginx
apt update && apt install -y procps nano telnet net-tools iputils-ping
cd /etc/nginx/ && mkdir sites-available sites-enabled
exit
```

```shell script
nano /etc/nging/nginx.conf

# add line
#    include /etc/nginx/sites-enabled/*;

nginx -s reload
```

Script to create new host: [gitlab-ci/infra/nginx/create-new-site.sh]()

Script to remove existing host: [gitlab-ci/infra/nginx/remove-site.sh]()

Deploy on stage host each branch:

```shell script
staging: 
  image: docker:18.09
  stage: stage
  when: manual
  only:
    - /^\d+\.\d+\.\d+/
    - branches
  variables:
    *docker_vars
  script:
    - echo 'Deploy' 
    - *docker_cert
    - docker rm -f $CONTAINER_NAME || true
    - docker run -d --name $CONTAINER_NAME --network ivango812_microservices_staging $REGISTRY_USER/reddit:$CI_COMMIT_SHORT_SHA
    - docker ps
    - docker exec nginx /srv/create-new-site.sh $CI_COMMIT_REF_NAME
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: http://$CI_COMMIT_REF_NAME.dev.newbusinesslogic.com

```

Where `docker_vars` and `docker_cert` are `YAML anchors` and content placed in section:

```shell script
.docker_conf: 
  variables: &docker_vars
    DOCKER_HOST: tcp://104.155.2.98:2376
    DOCKER_TLS_VERIFY: 1
    DOCKER_CERT_PATH: "/certs"
    CONTAINER_NAME: branch-$CI_COMMIT_REF_NAME
  script: &docker_cert
    - echo "$TLSCACERT" > $DOCKER_CERT_PATH/ca.pem
    - echo "$TLSCERT" > $DOCKER_CERT_PATH/cert.pem
    - echo "$TLSKEY" > $DOCKER_CERT_PATH/key.pem
```
It describes docs here: https://docs.gitlab.com/ee/ci/yaml/#anchors
You need to put TLS certs into Gitlab environment variables first:
* TLSCACERT
* TLSCACERT
* TLSKEY

We create container with name by template `branch-$CI_COMMIT_REF_NAME`
And create domain name by template `http://$CI_COMMIT_REF_NAME.dev.newbusinesslogic.com`

Environment for stage:

```shell script
...
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: http://$CI_COMMIT_REF_NAME.dev.newbusinesslogic.com
...
```

If we need to see all branches as one stage environment in Gitlab UI use prefix like `review/` in example above. 


#### Remove stage

If don't need stage host anymore we can remove it manually by add manual step to stage `stage`

```shell script
stage remove:
  image: docker:18.09
  stage: stage
  when: manual
  variables:
    *docker_vars
  script:
    - echo 'Removing staging' 
    - *docker_cert
    - docker exec nginx /srv/remove-site.sh $CI_COMMIT_REF_NAME
    - docker rm -f $CONTAINER_NAME
  environment:
    name: review/$CI_COMMIT_REF_NAME
    action: stop
```

where we remove host from `nginx` proxy first and then delete the container with our app.




Helpful features in `gitlab-ci.yml`


Whole [gitlab-ci.yml]():

```shell script
image: ruby:2.4.2

stages:
  - build
  - test
  - review
  - stage
  - production


variables:
  DATABASE_URL: 'mongodb://mongo/user_posts'

before_script:
  - cd reddit

.docker_conf: 
  variables: &docker_vars
    DOCKER_HOST: tcp://104.155.2.98:2376
    DOCKER_TLS_VERIFY: 1
    DOCKER_CERT_PATH: "/certs"
    CONTAINER_NAME: branch-$CI_COMMIT_REF_NAME
  script: &docker_cert
    - echo "$TLSCACERT" > $DOCKER_CERT_PATH/ca.pem
    - echo "$TLSCERT" > $DOCKER_CERT_PATH/cert.pem
    - echo "$TLSKEY" > $DOCKER_CERT_PATH/key.pem

build:
  image: docker:18.09
  stage: build
  only:
    - /^\d+\.\d+\.\d+/
    - branches
  services:
      - docker:18.09-dind
  variables:
    DOCKER_HOST: tcp://docker:2375/
    DOCKER_DRIVER: overlay2
  script:
    - docker --version
    - echo 'Building'
    - docker login -u $REGISTRY_USER -p $REGISTRY_PASSWORD
    - docker build -t $REGISTRY_USER/reddit:$CI_COMMIT_SHORT_SHA .
    - docker push $REGISTRY_USER/reddit:$CI_COMMIT_SHORT_SHA

test_unit_job: 
  stage: test 
  services:
    - mongo:latest 
  script:
    - bundle install
    - ruby simpletest.rb

test_integration_job:
  stage: test
  script:
    - echo 'Integration Tests'

branch review:
  stage: review
  script: echo "Deploy to $CI_ENVIRONMENT_SLUG"
  environment:
    name: branch/$CI_COMMIT_REF_NAME
    url: http://$CI_ENVIRONMENT_SLUG.example.com 
  only:
    - /^feature-.*/
  except:
    - master

staging: 
  image: docker:18.09
  stage: stage
  when: manual
  only:
    - /^\d+\.\d+\.\d+/
    - branches
  variables:
    *docker_vars
  script:
    - echo 'Deploy' 
    - *docker_cert
    - docker rm -f $CONTAINER_NAME || true
    - docker run -d --name $CONTAINER_NAME --network ivango812_microservices_staging $REGISTRY_USER/reddit:$CI_COMMIT_SHORT_SHA
    - docker ps
    - docker exec nginx /srv/create-new-site.sh $CI_COMMIT_REF_NAME
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: http://$CI_COMMIT_REF_NAME.dev.newbusinesslogic.com

stage remove:
  image: docker:18.09
  stage: stage
  when: manual
  variables:
    *docker_vars
  script:
    - echo 'Removing staging' 
    - *docker_cert
    - docker exec nginx /srv/remove-site.sh $CI_COMMIT_REF_NAME
    - docker rm -f $CONTAINER_NAME
  environment:
    name: review/$CI_COMMIT_REF_NAME
    action: stop

production: 
  stage: production 
  when: manual
  only:
    - /^\d+\.\d+\.\d+/
  script:
    - echo 'Deploy' 
  environment:
    name: production
    url: https://project.com

```


#### Some notes:


1. If docker container instantly eats memory, you can limits it using orchestrator by `docker-compose.yml`
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

2. `Default` docker network doesn't resolve hosts by hostname only by local IP, 
so we need to create custom network `staging` to have an ability to resolve containers by hostname.


3. If you need to connect to the remote docker-host, it needs to put TLS certs into it:

```
docker-machine config staging-docker
--tlsverify
--tlscacert="/Users/me/.docker/machine/machines/staging-docker/ca.pem"
--tlscert="/Users/me/.docker/machine/machines/staging-docker/cert.pem"
--tlskey="/Users/me/.docker/machine/machines/staging-docker/key.pem"
-H=tcp://104.155.2.98:2376
```


4. How to run `cron` in docker: https://ivan.bessarabov.ru/blog/how-to-run-cron-in-docker


### Gitlab - Slack integration

`Settings -> Integrations -> Slack Notifications`
Add webhook url configure triggers checkboxes.

Or you can notify from `gitlab-runner` by:

```shell script
curl -X POST -H 'Content-type: application/json' --data '{"text":"Allow me to reintroduce myself!"}' https://hooks.slack.com/services/<webhook-key>
```

Slack message markup doc: https://api.slack.com/docs/message-formatting
