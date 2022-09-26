#!/usr/bin/env bash
set -ex
echo "Building workshop image"
docker build . -t harbor.svcs.az-tkglab.sprok8s.com/tap-workshop/cartographer-workshop

echo "Pushing the workshop image"
docker push harbor.svcs.az-tkglab.sprok8s.com/tap-workshop/cartographer-workshop:latest
