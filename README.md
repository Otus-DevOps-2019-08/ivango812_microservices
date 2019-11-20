# ivango812_microservices
ivango812 microservices repository


# Lesson 15

Studying Docker

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

Change PROJECT

```
export GOOGLE_PROJECT=docker-258721
```

Create host with docker engine:

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
