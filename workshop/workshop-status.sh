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

k get systemprofiles,trainingportals,workshopenvironments,workshoprequests,workshops,workshopsessions