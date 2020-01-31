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

# Lesson 25 - Kubenetes The Hard Way

Passed sucsessfuly through https://github.com/kelseyhightower/kubernetes-the-hard-way

All artefacts stored in `kubernetes/the_hard_way` directory

All app deployment manifests stored in `kubenetes/reddit` directory

# Lesson 26 - Minikube, GKE

### Minikube

Install `kubectl` first https://kubernetes.io/docs/tasks/tools/install-kubectl/

Install `minikube` https://kubernetes.io/docs/tasks/tools/install-minikube/

Run `minikube`:

```
minikube start
```

or with kubernetes version and vm-driver:

```
minikube start --vm-driver=virtualbox --kubernetes-version=v1.11.10
```

Check `minikube`:

```
kubectl get nodes

NAME      STATUS  ROLES   AGE   VERSION 
minikube  Ready   <none>  3h    v1.10.0
```

`kubectl` configuration is a context, context is a combination of:
* cluster
* user
* namespace

Information about `kubectl` context stored in `~/.kube/config` file

`~/.kube/config` it's the same kubenetes YAML-manifest.

`cluster` is:
* server - address of kubernetes API-server
* certificate-authority - the root certificate
* +name - for identification in config

An order of `kubectl` configuring the next:
1. Create *cluster*
```
kubectl config set-cluster ... cluster_name
```

2. Create *credentials*
```
kubectl config set-credentials ... user_name
```

3. Create *context*
```
kubectl config set-context context_name \
  --cluster=cluster_name \
  --user=user_name
```

4. Use *context*
```
kubectl config use-context context_name
```

To see current context:

```
kubectl config current-context
minikube
```

To see all context:

```
kubectl config get-contexts
```

To run component:
```
kubectl apply -f ui-deployment.yml
deployment "ui" created
```

To see deployments:
```
kubectl get deployment
NAME DESIRED CURRENT UP-TO-DATE AVAILABLE AGE ui 3 3 3 3 1m
```

To see pods with selector:
```
kubectl get pods --selector component=ui
```

For port forwarding:
```
kubectl port-forward <pod-name> 8080:9292
```

Then you can open in the browser http://localhost:8080

Let's create `post` component listening on the 5000/tcp port:

...

Let's create `service` component to have an endpoint to addressing to our application:
```
kubectl describe service comment | grep Endpoints

Endpoints: 172.17.0.9:5000
```

Let's check that our pod-name lookup works properly:
```
kubectl exec -ti <pod-name> nslookup comment
```

To see pod logs:
```
kubectl logs post-56bbbf6795-7btnm
```

To see all services list:
```
minikube services list
```

List of all addons:
```
minikube addons list
```

Kubernetes has 3 default namespases:

*default* - for objects if namespace doesn't set
*kube-system* - for object created by kubernetes and for managing kubernetes
*kube-public* - for objects that needs access from any point of cluster

To set namespace use flag `-n <namespace> or --namespace <namespace>`

Let's get our dashboard objects:
```
kubectl get all -n kube-system --selector k8s-app=kubernetes-dashboard
```

Let's run our dashboard:
```
minikube service kubernetes-dashboard -n kube-system
```




```
kubectl get all -n kube-system --selector k8s-app=kubernetes-dashboard
```




```
kubectl get deployment
NAME      DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
comment   3         3         3            3           3m
post      3         3         3            3           3m
ui        3         3         3            3           18m
```

Run `ui` app:

http://localhost:8080

```
Microservices Reddit in ui-56888989b5-9fcc8 container
...
```

Run `comment` app:

http://localhost:8080/healthcheck

```
{"status":0,"dependent_services":{"commentdb":0},"version":"0.0.3"}
```

Run `post` app:

http://localhost:8080/healthcheck
```
{"status": 0, "version": "0.0.2", "dependent_services": {"postdb": 0}}
```

Creating `Service` `comment`:

```
kubectl apply -f comment-service.yml
```

Viewing service PODs:

```
kubectl describe service comment | grep Endpoints
Endpoints:         172.17.0.7:9292,172.17.0.8:9292,172.17.0.9:9292
```


Run `dashboard`

```
minikube dashboard
```


## Kubernetes at GKE (Google Kubernetes Engine)

Create cluster in GUI GKE as described in `xxx-practice.PDF`

Connect to the GKE-cluster:

```
gcloud container clusters get-credentials kubenetes-2 --zone europe-north1-a --project docker-258721
```

To see current-context:
```
kubectl config current-context
```
Let's create namespace first:
```
kubectl apply -f ./kubernetes/reddit/dev-namespace.yml
```

And deploy all components:
```
kubectl apply -f ./kubernetes/reddit/ -n dev
```

Dont's forget to add firewall rule for:
target: all 
IP-addresses range: 0.0.0.0/0 
ports range: tcp:30000-32767


Let's see external IPs:
```
kubectl get nodes -o wide
```

And get a port of service publication:
```
kubectl describe service ui -n dev | grep NodePort
```

Open our app at: http://<node-ip>:<NodePort>



Reddit screenshot at GKE https://prnt.sc/qsoj3o


*Kubernetes dashboard*

Run

```
kubectl proxy
```

and open http://localhost:8001/ui

Let's set `cluster-admin` role to service account of dashboard using clusterrolebinding:

```
kubectl create clusterrolebinding kubernetes-dashboard   --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
```

And reload http://localhost:8001/ui


*Tasks with **

### Up kubernetes by terraform

Let's create cluster creation by terraform: https://github.com/Otus-DevOps-2019-08/ivango812_microservices/tree/kubernetes-2/kubernetes/terraform

Or use this module https://github.com/terraform-google-modules/terraform-google-kubernetes-engine


### Up kubernetes dashboard by YAML manifest

Let's create YAML manifest for dashboard deployment:

I found YAML for dashboard activate:
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

Save it to the our git:
https://github.com/Otus-DevOps-2019-08/ivango812_microservices/blob/kubernetes-2/kubernetes/dashboard.yaml

Run it:

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```
