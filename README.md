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

...

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

Then open `http://<gitlab host ip>`

Create password for `root` account.

Go to `Settings` turn off `Sign up enabled`.

Create new `Group` - `homework`

Create new `Project` in this group - `example`

Add `repository` we just created to our local project git:

```shell script
git remote add gitlab http://<your-vm-ip>/homework/example.git
```

### Create runner

```shell script
docker run -d --name gitlab-runner --restart always \ 
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \ 
  -v /var/run/docker.sock:/var/run/docker.sock \ 
  gitlab/gitlab-runner:latest
```

Register Runner

Manually:
```shell script
docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false
```

Not manually:
```shell script
docker exec gitlab-runner \
  gitlab-runner register \
  --non-interactive \
  --url "http://35.205.182.43/" \
  --registration-token "TOKEN" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner" \
  --tag-list "docker,linux,xenial,ubuntu" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"
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

Script to create new host: [gitlab-ci/infra/nginx/create-new-site.sh](https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/gitlab-ci-1/gitlab-ci/infra/nginx/create-new-site.sh)

Script to remove existing host: [gitlab-ci/infra/nginx/remove-site.sh](https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/gitlab-ci-1/gitlab-ci/infra/nginx/remove-site.sh)

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
`YAML anchors` doc: https://docs.gitlab.com/ee/ci/yaml/#anchors

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


#### Helpful features in `gitlab-ci.yml`


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



# Lesson 23 - Logging


Elastic Stack (aka ELK)

* ElasticSearch (TSDB and search engine for storing logs) 
* Logstash (for aggregate and transform logs)
* Kibana (for logs visualization)

But instead of `Logstach` we use `Fluentd`.

Create `docker-compose-logging.yml` for up ELK components.

I've got errors in `elasticsearch` container:

```shell script
elasticsearch_1  | ERROR: [2] bootstrap checks failed
elasticsearch_1  | [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
elasticsearch_1  | [2]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured
```

to fix the first one run:

```shell script
docker-machine ssh logging
sudo sysctl -w vm.max_map_count=262144
exit
```

to fix the second one add `environment` variables and `ulimits` to fluentd container:

```shell script
    environment:
      - node.name=elasticsearch
      - cluster.name=docker-cluster
      - node.master=true
      - cluster.initial_master_nodes=elasticsearch
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ulimits:
      memlock:
        soft: -1
        hard: -1
```
I've googled this solution.

Then add `fluentd`

## Fluentd

Create [`logginh/fluentd/fluent.conf`]()

Add `logging` section to services you want to handle logs:

```shell script
    logging:
      driver: "fluentd"
      options:
        fluentd-address: localhost:24224
        tag: service.ui
```
[`docker/docker-compose.yml`]()


### Structured logs

`fluent.conf`:

```shell script
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<filter service.post>
    @type parser
    format json
    key_name log
</filter>

<filter service.ui>
  @type parser
  key_name log
  format grok
  grok_pattern %{RUBY_LOGGER}
</filter>

<match *.**>
  @type copy
  <store>
    @type elasticsearch
    host elasticsearch
    port 9200
    logstash_format true
    logstash_prefix fluentd
    logstash_dateformat %Y%m%d
    include_tag_key true
    type_name access_log
    tag_key @log_name
    flush_interval 1s
  </store>
  <store>
    @type stdout
  </store>
</match>
```

### Unstructured logs

Fluentd `grok` docs: https://github.com/fluent/fluent-plugin-grok-parser/blob/master/README.md


Parsing гnstructured logs:

`fluent.conf` for Homework with *:
```
...
<filter service.ui>
  @type parser
  format grok
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  grok_pattern service=%{WORD:service} \| event=%{WORD:event} \| path=%{URIPATH:path} \| request_id=%{GREEDYDATA:request_id} \| remote_addr=%{IP:remote_addr} \| method= %{WORD:message} \| response_status=%{INT:response_status}
  key_name message
  reserve_data true
</filter>
...
```

## Zipkin

Zipkin is a distributed tracing system - https://zipkin.io

Add `zipkin` service into `docker-compose-logging.yml`:

```shell script
...
services:
  zipkin:
    image: openzipkin/zipkin
    ports:
      - "9411:9411"
    networks:
      - reddit
...
```

Don't forget add network to zipkin service where your services run.

Add `environment` variable into services we want to handle logs:

```shell script
services:
  ui:
...
    environment:
      - ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
...
```

Add 
```shell script
ZIPKIN_ENABLED=true
```
into `.env` file

Homework with * - Fixing https://github.com/Artemmkin/bugged-code

The first bug:
https://github.com/Artemmkin/bugged-code/blob/master/ui/Dockerfile
doesn't contain variables with service names, so we need to add them into 
`docker-compose.yml`

```shell script
service:
  ui:
    environment:
      APP_HOME: ${UI_APP_HOME}
      ZIPKIN_ENABLED: ${ZIPKIN_ENABLED}
      POST_SERVICE_HOST: post
      POST_SERVICE_PORT: 5000
      COMMENT_SERVICE_HOST: comment
      COMMENT_SERVICE_PORT: 9292
    image: ${USERNAME}/ui:${UI_VERSION}
```

The second bug:
Page with a post opens too slow - about 3 sec. But original version of service takes only 0.1 sec
We can ask developers to fix it. ;)

# Lesson 20 - Monitoring-1 

Prometheus - configuring, UI, microservices monitoring, using exporter.

Create docker-host first:

```shell script
docker-machine create --driver google \
  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \ 
  --google-machine-type n1-standard-1 \ 
  --google-zone europe-west1-b \ 
  docker-host

eval $(docker-machine env docker-host)
```

Install prometheus using docker image `prom/prometheus:v2.1.0`

```shell script
docker run --rm -p 9090:9090 -d --name prometheus prom/ prometheus:v2.1.0
docker-machine ip docker-host
```

Open UI: http://<docker-host-ip>:9090/graph

Click on "insert metric at cursor" and select `prometheus_build_info`, Execute.

We'll get:

```shell script
prometheus_build_info{branch="HEAD",goversion="go1.9.1",instance="localhost:9090", 
job="prometheus", revision= "3a7c51ab70fc7615cd318204d3aa7c078b7c5b20",version="1.8.1"} 1
```

Where:

prometheus_build_info - metrics name
branch, goversion, instance, job, revision, version - label
1 - value

### Prometheus Targets

Select in the Menu: Status -> Targets

We'll get `endpoints` and its state or errors if it rises.

We can take a look at microservice metrics that collects prometheus, open: http://<microservice-ip>:9090/metrics

Rearrange directories according PDF with practice.

### Prometheus Configuring

Prometheus configuring via *.yml files.

Create file [`prometheus.yml`](https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/monitoring-1/monitoring/prometheus/prometheus.yml)

```shell script
export USER_NAME=username
```

where `USER_NAME` is docker hub login

```shell script
docker build -t $USER_NAME/prometheus .
```

Then let's build all microservices images:

```shell script
cd /src
cd /ui && bash docker_build.sh /src/post-py && cd ..
cd /post-py && bash docker_build.sh /src/comment  && cd ..
cd /comment && bash docker_build.sh && cd ..
cd ..
```

or

```shell script
for i in ui post-py comment; do cd src/$i; bash docker_build.sh; cd -; done
```

Add a new service `prometheus` to [`docker-compose.yml`](https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/monitoring-1/docker/docker-compose.yml)

And add `.env` file with ENVIRONMENT VARIABLES for `docker-compose.yml` and `.env.example` for git

Up all our services:

```shell script
docker-compose up -d
```

Check http://<docker-host-ip>:9090/targets
All services should be in `UP` state.

### Prometheus Healthchecks

If service is healthy it should return `status = 1`, if not `status = 0`

At Prometheus UI try to find metric by `ui_health`.

We see that all services are healthy - return `1`

Then let's try tu down one service and check the chart again, it should be set at `0`.
Turn the service on back and metric will be back too.

### Prometheus Exporters

It's a program that helps prometheus collecting metrics.

Let's try to use `Node exporter` to collect metrics about Docker host working.
Add `node-exporter` service into `docker-compose.yml` and add next block into `prometheus.yml`

```shell script
scrape_configs: 
  
  ...

  - job_name: 'node' 
    static_configs:
      - targets:
        - 'node-exporter:9100'
```

Don't forget to rebuild:

```shell script
docker build -t $USER_NAME/prometheus .
```

Recreate our services:

```shell script
docker-compose down 
docker-compose up -d
```

Check http://<docker-host-ip>:9090/targets and find new endpoint `node` 
where we can see: CPU usage, memory, etc...

We can load this host to check how this metric works:

```shell script
yes > /dev/null
```

Don't forget to push all images:

```shell script
docker login
docker push $USER_NAME/ui
docker push $USER_NAME/comment
docker push $USER_NAME/post
docker push $USER_NAME/prometheus
```

```shell script
docker-machine rm docker-host
```
