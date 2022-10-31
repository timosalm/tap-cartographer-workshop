#!/usr/bin/env bash
set -ex

#  Learning Center resources
# k api-resources --api-group=learningcenter.tanzu.vmware.com
# systemprofiles
# trainingportals
# workshopenvironments
# workshoprequests
# workshops
# workshopsessions

kubectl get systemprofiles,trainingportals,workshopenvironments,workshoprequests,workshops,workshopsessions