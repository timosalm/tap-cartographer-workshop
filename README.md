# tap-cartographer-workshop

## Prerequisites
kapp deploy -a tekton-triggers -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.6/git-clone.yaml

## Content
- Design and Philosophy
- Choreography vs Orchestration
- Templates and other CRDs that make up Cartographer
- OOTB Supply Chains walkthrough (30 min) / https://github.com/pivotal/docs-tap/blob/main/scc/authoring-supply-chains.md#-live-modification-of-supply-chains-and-templates
- HANDS-ON MODULE: Building a custom Supply Chain (90 min)
  - Building and using a new custom Supplychain from scratch for a python app (Snyk, Kaniko, Kubernetes deployment)
- WRAP-UP DISCUSSION (30 min)




## TMP 

First we looked for existing controllers, unfortunately we didn’t find anything
Next, we’re developing a tekton task (or more than one) to do the job, but if it get’s more complex we will look at building, or instigation the creation of, a controller for the job.


## Controller
https://github.com/kubernetes-client/java/blob/master/examples/examples-release-15/src/main/java/io/kubernetes/client/examples/SpringControllerExample.java
https://github.com/kubernetes-client/java/blob/master/docs/java-controller-tutorial-rewrite-rs-controller.md

