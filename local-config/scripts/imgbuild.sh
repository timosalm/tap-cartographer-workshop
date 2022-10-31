#!/usr/bin/env bash
set -ex

IMAGE_REPO=harbor.services.demo.jg-aws.com

# echo "Reinitialize password manager"
# pass show docker-credential-helpers/docker-pass-initialized-check

# echo "Docker login"
# # docker login https://harbor.services.demo.jg-aws.com --username tap-workshop --password ''

echo "Building workshop image"
docker build . -t $IMAGE_REPO/tap-workshop/cartographer-workshop

echo "Pushing the workshop image"
docker push $IMAGE_REPO/tap-workshop/cartographer-workshop:latest
