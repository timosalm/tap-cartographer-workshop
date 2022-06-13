Before we define our resources, let's have a look at the **Workload** which is an **abstraction for developers** to configure things like the location of the source code repository, environment variables and service claims for an application to be delivered through the supply chain.
```editor:append-lines-to-file
file: workload.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: Workload
  metadata:
    labels:
      app.kubernetes.io/part-of: simple-app
      end2end.link/workshop-session: {{ session_namespace }}
    name: simple-app
  spec:
    source:
      git:
        ref:
          branch: main
        url: https://github.com/tsalm-pivotal/python-hello-world-workshop-example.git
```
For the matching of our Workload and Supply Chain we have to set the **label of our ClusterSupplyChain's label selector**. We also defined `app.kubernetes.io/part-of: simple-app` as a label which is required for the commercial Supply Chain Choreographer UI plugin. 
The location of an application's source code can be configured via the `spec.source` field. Here, we are using a branch of a GIT repository as source to be able to implement a **continous path to production** where every git commit to the codebase will trigger another execution of the Supply Chain and developers only have to apply a Workload only once if they start with a new application or microservice. 
For the to be deployed application, the Workload custom resource also provides configuration options for a **pre-built image in a registry** from e.g. an ISV via `spec.image` and, for a special functionality of the **tanzu CLI**, a **source code container image**, which will be created from source code in a local filesystem and pushed to a registry by the tanzu CLI via `spec.source.image`.

Other configuration options are available for resource constraints (`spec.limits`, `spec.requests`) and environment variables for the build resources in the supply chain (`spec.build.env`) and to be passed to the running application (`spec.env`).

Last but not least via (`.spec.params`), it's possible to overide default values of the additional parameters that are used in the Supply Chain but not part of the official Workload specification.

The detailed specification can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/workload/#workload
```