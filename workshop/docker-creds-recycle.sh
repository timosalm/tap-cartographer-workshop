#!/usr/bin/env bash
set -ex
# https://steinbaugh.com/posts/docker-credential-pass.html

#  Docker login to local Harbor
docker logout harbor.svcs.az-tkglab.sprok8s.com
docker login harbor.svcs.az-tkglab.sprok8s.com -u admin -p VMware1!

exit
pass insert docker-credential-helpers/docker-pass-initialized-check
pass show docker-credential-helpers/docker-pass-initialized-check
docker-credential-pass list|jq
