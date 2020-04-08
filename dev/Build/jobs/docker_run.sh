#!/bin/bash

DOCKER_TAG=cron/handler

echo "Building cron image ..."
docker build --rm -t $DOCKER_TAG .

echo "Running cron container ..."
docker run -d -t $DOCKER_TAG

