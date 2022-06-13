#!/bin/bash
set -x
set +e

REGISTRY_PASSWORD=$CONTAINER_REGISTRY_PASSWORD kp secret create registry-credentials --registry ${CONTAINER_REGISTRY_HOSTNAME} --registry-user ${CONTAINER_REGISTRY_USERNAME}
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-credentials"}, {"name": "tanzu-net-credentials"}]}'

kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-cli/0.3/git-cli.yaml

git_hostname=$(echo $GITOPS_REPOSITORY | grep -oP '(?<=https://).*?(?=/)')

cat <<EOF | kubectl apply -f -
kind: Secret
apiVersion: v1
metadata:
  name: tekton-basic-access-auth
type: Opaque
stringData:
  .gitconfig: |
    [credential "https://$git_hostname"]
      helper = store
  .git-credentials: |
    https://$GITOPS_REPOSITORY_USERNAME:$GITOPS_REPOSITORY_PASSWORD@$git_hostname
EOF

cat <<EOF | kubectl apply -f -
kind: Secret
apiVersion: v1
metadata:
  name: flux-basic-access-auth
data:
  username: $(echo $GITOPS_REPOSITORY_USERNAME | base64)
  password: $(echo $GITOPS_REPOSITORY_PASSWORD | base64)
EOF