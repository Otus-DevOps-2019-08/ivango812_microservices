#!/usr/bin/env bash
docker-machine create --driver google \
  --google-project $PROJECT_ID \
  --google-zone europe-west1-b \
  --google-machine-type n1-standard-1 \
  --google-disk-size 100 \
  --google-machine-image https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/family/ubuntu-1604-lts \
  gitlab-ce
