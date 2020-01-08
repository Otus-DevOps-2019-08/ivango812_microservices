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


Установить активную машину:

```
eval $(docker-machine env gitlab-ce)
docker-machine ls  
```
где gitlab-ce - хост с докером, который нужно сделать активным


Запуск и Регистрация раннера:

--restart always \

docker run -d -it --rm \
--name docker-runner2 \
-v /srv/gitlab-runner-machine/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner register \
  --non-interactive \
  --url "http://35.205.182.43/" \
  --registration-token "Cif78nZbx34bniAwvp2L" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner" \
  --tag-list "docker,linux,xenial,ubuntu" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"


docker run -d --name gitlab-runner-machine --restart always \
-v /srv/gitlab-runner-machine/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest

docker exec -it gitlab-runner-machine gitlab-runner register --run-untagged --locked=false

docker exec gitlab-runner-machine \
gitlab-runner register \
  --non-interactive \
  --url "http://35.205.182.43/" \
  --registration-token "Cif78nZbx34bniAwvp2L" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner" \
  --tag-list "docker,linux,xenial,ubuntu" \
  --run-untagged="true" \
  --locked="false" \
  --access-level="not_protected"

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

# Lesson 21 - Monitoring-2

Docker container monitoring.
Metrics visualisation.
Collecting app & business metrics.
Alerting configuring and checking.

Create `docker-host` as in the previous lesson.

Let's split `docker-compose.yml` file onto two files:
In the `docker-compose.yml` leave app services,
All monitoring services removed into `docker-compose-monitoring.yml` file.

Now to run monitoring use:
```shell script
docker-compose -f docker-compose-monitoring.yml up -d
```

To check our docker containers state we'll use [`cAdvisor`](https://github.com/google/cadvisor)
Let's add cAdvisor into `docker-compose-monitoring.yml`:
```shell script
services:
  ...
  cadvisor:
    image: google/cadvisor:v0.29.0 
    volumes:
      - '/:/rootfs:ro'
      - '/var/run:/var/run:rw'
      - '/sys:/sys:ro'
      - '/var/lib/docker/:/var/lib/docker:ro'
    ports:
      - '8080:8080'
```

Add our new service into prometheus config `prometheus.yml`:

```shell script
scrape_configs:
  ...
  - job_name: 'cadvisor' 
    static_configs:
      - targets:
        - 'cadvisor:8080'
```

Rebuild monitoring image with new service:

```shell script
export USER_NAME=username # where username - your Docker Hub Login
docker build -t $USER_NAME/prometheus .
```

Up our services:
```shell script
docker-compose up -d
docker-compose -f docker-compose-monitoring.yml up -d
```

Open cAdvisor UI http://<docker-machine-host-ip>:8080

Click `Docker Containers` at the bottom of the page to see all containers.

Here you can see utilization info about:
- CPU usage
- Memory usage
- Network utilization

At the http://<docker-host>:8080/metrics you can see what exporter pass to the prometheus.

### Grafana

Grafana - visualisation tool for Prometheus.

Grafana service config example:

```shell script
services:

  grafana:
    image: grafana/grafana:5.0.0
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=secret
    depends_on:
      - prometheus
    ports:
      - 3000:3000

volumes:
  grafana_data:
```
 
Let's run the new service:

```shell script
docker-compose -f docker-compose-monitoring.yml up -d grafana
```

And open grafana http://<docker-machine-host-ip>:3000

Grafana dashboard configuring you can find in PDF-file.

Let's add `post` service to prometheus config:
```shell script
scrape_configs:
  ...
  - job_name: 'post' 
    static_configs:
      - targets:
        - 'post:5000'
```

Rebuild service.

Rerun monitoring services:

```shell script
docker-compose -f docker-compose-monitoring.yml down
docker-compose -f docker-compose-monitoring.yml up -d
```

Results of Services monitoring dashboard config:
[UI_Service_Monitoring.json](https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/monitoring-2/monitoring/grafana/dashboards/UI_Service_Monitoring.json)

Results of Business Logic monitoring dashboard config:
[Business_Logic_Monitoring.json](https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/monitoring-2/monitoring/grafana/dashboards/Business_Logic_Monitoring.json)

### Alerting

Alertmanager

Create next files in the `monitoring/alertmanager`:

`config.yml`:

```shell script
global:
  slack_api_url: 'https://hooks.slack.com/services/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'

route:
  receiver: 'slack-notifications'

receivers:
- name: 'slack-notifications'
  slack_configs:
  - channel: '#userchannel'
```

`Dockerfile`

```shell script
FROM prom/alertmanager:v0.14.0 
ADD config.yml /etc/alertmanager/
```

Build alertmanager image:

```shell script
docker build -t $USER_NAME/alertmanager .
```

Add new service into `docker-compose-monitoring.yml`:
```shell script
services:
  ...
  alertmanager:
    image: ${USER_NAME}/alertmanager 
    command:
      - '--config.file=/etc/alertmanager/config.yml' 
    ports:
      - 9093:9093
```

Create Alert rules.

Create file `alerts.yml` in `monitoring/prometheus` dir:

```shell script
groups:
  - name: alert.rules
    rules:
    - alert: InstanceDown
      expr: up == 0
      for: 1m
      labels:
        severity: page
      annotations:
        description: '{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute'
        summary: 'Instance {{ $labels.instance }} down'
```

Add this file coping into `Dockerfile`:
```shell script
ADD alerts.yml /etc/prometheus/
```

Add alerting rules into prometheus config `prometheus.yml`:
```shell script
rule_files:
  - "alerts.yml"

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets:
      - "alertmanager:9093"
```

Rebuild Prometheus image:
```shell script
docker build -t $USER_NAME/prometheus .
```

Down and Up monitoring infra:
```shell script
docker-compose -f docker-compose-monitoring.yml down 
docker-compose -f docker-compose-monitoring.yml up -d
```

Check alerting by stopping some app service and get Slack message.

Don't forget push all images to Docker Hub


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
