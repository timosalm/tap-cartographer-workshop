#!/usr/bin/env bash
set -xe

echo "Deploying the workshop"
ytt template -f resources -f values.yaml --ignore-unknown-comments \
| kapp deploy -n tap-install -a cartographer-workshops -f- --diff-changes --yes

echo "Removing the learning center pod"
kubectl delete pod -l deployment=learningcenter-operator -n learningcenter
