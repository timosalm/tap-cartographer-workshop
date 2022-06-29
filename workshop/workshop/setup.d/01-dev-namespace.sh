#!/bin/bash
set -x
set +e

REGISTRY_PASSWORD=$CONTAINER_REGISTRY_PASSWORD kp secret create registry-credentials --registry ${CONTAINER_REGISTRY_HOSTNAME} --registry-user ${CONTAINER_REGISTRY_USERNAME}
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registry-credentials"}, {"name": "tanzu-net-credentials"}]}'

git clone https://github.com/tsalm-pivotal/tap-cartographer-workshop.git

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

cat << \EOF | kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: developer-defined-tekton-pipeline
  labels:
    apps.tanzu.vmware.com/pipeline: test     # (!) required
spec:
  params:
    - name: source-url                       # (!) required
    - name: source-revision                  # (!) required
  tasks:
    - name: test
      params:
        - name: source-url
          value: $(params.source-url)
        - name: source-revision
          value: $(params.source-revision)
      taskSpec:
        params:
          - name: source-url
          - name: source-revision
        steps:
          - name: test
            image: maven:3-openjdk-11
            script: |-
              cd `mktemp -d`
              wget -qO- $(params.source-url) | tar xvz -m
              mvn test
EOF
cat << EOF | kubectl apply -f -
apiVersion: carto.run/v1alpha1
kind: Workload
metadata:
  labels:
    app.kubernetes.io/part-of: ootb-sc-demo
    apps.tanzu.vmware.com/has-tests: "true"
    apps.tanzu.vmware.com/workload-type: web
  name: ootb-sc-demo
spec:
  source:
    git:
      ref:
        branch: main
      url: https://github.com/tsalm-pivotal/spring-boot-hello-world.git
EOF