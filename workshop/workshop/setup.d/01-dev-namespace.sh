#!/bin/bash
set -x
set +e

git clone https://github.com/tsalm-pivotal/tap-cartographer-workshop.git

REGISTRY_PASSWORD=$CONTAINER_REGISTRY_PASSWORD kp secret create registry-credentials --registry ${CONTAINER_REGISTRY_HOSTNAME} --registry-user ${CONTAINER_REGISTRY_USERNAME}
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-credentials"}, {"name": "tanzu-net-credentials"}]}'
