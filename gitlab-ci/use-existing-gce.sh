#!/usr/bin/env bash

docker-machine create --driver google \
  --google-project $PROJECT_ID \
  --google-zone europe-west1-b \
  --google-use-existing \
  gitlab-ce

eval $(docker-machine env gitlab-ce)
