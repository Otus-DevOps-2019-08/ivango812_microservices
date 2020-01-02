#!/usr/bin/env bash

export GITLAB_EXTERNAL_IP=$(docker-machine ip gitlab-ce)

docker-machine ssh gitlab-ce mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs
