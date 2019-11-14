# ivango812_microservices
ivango812 microservices repository



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

Create terraform file for instances creation:

```
```

```
sudo yarn cache clean
brew cleanup
```

Htlps to install terraform if you've got `Error: Permission denied @ apply2files - /usr/local/share/Library/Caches/Yarn/v4/npm...`

