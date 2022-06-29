The easiest way to get started with building a custom supply chain is to copy one of the out of the box supply chains from the cluster, change the `metadata.name` and add an unique selector by e.g. adding a label to the `spec.selector` configuration.

For this exercise, we will build one from scratch and discover the three ways of providing an implementation for a template:
- Using a Kuberentes custom resource that is already available for the functionality we are looking for
- Leverage a Kubernetes native CI/CD solution like Tekton to do the job, which is part of TAP
- For more **complex and asynchronous functionalities**, we have to **implement our own [Kubernetes Controller](https://kubernetes.io/docs/concepts/architecture/controller/)**.

You are invited to implement the custom supply chain yourself based on the information and basic templates which you have use to **avoid conflicts with other workshop sessions**. Due to the complexity. it's not part of the workshop as of rigth now to build a custom Kubernetes controller and therefore, we will just have a look at an example.
You can make the solution for a specific step visible by clicking on the **Solution sections**.

Let's now start the implementation with the following supply chain skeleton.
```terminal:execute
command: mkdir custom-supply-chain
```
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSupplyChain
  metadata:
    name: custom-supplychain-{{ session_namespace }}
  spec:
    selector:
      end2end.link/workshop-session: {{ session_namespace }}
      end2end.link/is-custom: "true"
    resources: []
```

As with the other supply chains you already saw, the **first task** for our custom supply chain is also to **provide the latest version of a source code in a Git repository to subsequent steps**.
In the simple and ootb supply chains we used the [Flux](https://fluxcd.io) Source Controller for it. 
If there is as far as I know no real alternative available, and the goal is to practive all three ways on how to provide an implementation for a template, I've **built a custom Kubernetes Controller for it**.

The Kubernetes Controller is built with Spring Boot, but I could have implemented it easily with other programming languages/frameworks, where a [Kubernetes client library](https://kubernetes.io/docs/reference/using-api/client-libraries/) is available for.
The first dependency is the official Java Kubernetes client library.
```editor:open-file
file: tap-cartographer-workshop/github-source-controller/pom.xml
line: 29
```

It provides a REST API for a GitHub Webhook that sends a POST request to it on every new commit after configuring it for a specific repository. 
```editor:open-file
file: tap-cartographer-workshop/github-source-controller/src/main/java/com/example/GitHubWebhookResource.java
```

Based on the provided information, the Kubernetes Controller generates a tarball url for the source code version that can be used by subsequent steps to download it and stores it in a HashMap.
```editor:open-file
file: tap-cartographer-workshop/github-source-controller/src/main/java/com/example/GitHubSourceApplicationService.java
```

Now it's getting a little bit more complex.
**Controllers** are the core of Kubernetes.
It’s a controller’s job to ensure that, for any given object, the actual state of the world (both the cluster state, and potentially external state like running containers for Kubelet or loadbalancers for a cloud provider) matches the desired state in the object. Each controller focuses on one root Kubernetes resource, but may interact with other Kubernetes resources. We call this process **reconciling**.
In our case the Kubernetes resource is a custom resource definition called `GitHubRepository`.
```editor:open-file
file: tap-cartographer-workshop/github-source-controller/k8s/crds/github-repository-crd.yaml
```

Let's now have a look at our reconcile function.
```editor:open-file
file: tap-cartographer-workshop/github-source-controller/src/main/java/com/example/GitHubSourceReconciler.java
```
It's passed a reconciliation request that includes information about a custom resource of the type `GitHubRepository` which's state has to be matched to the actual state of the world (in our example every 30 seconds). The `status.artifact` information of the custom resource will be updated with the latest revision (`status.artifact.revision`) and tarball url (`status.artifact.url`) from the HashMap for the configured Git repository and branch if available.

To have actual instances of the Reconciler and Controller running in our application, we have to register them as Beans and provide all the required parameters via additional configuration.
```editor:open-file
file: tap-cartographer-workshop/github-source-controller/src/main/java/com/example/ControllerConfiguration.java
```

The application then has to be packaged in a container, deployed to Kubernetes and exposed to be reachable by the GitHub Webhook of a Git repository that also has to be configured - which is already done for you.

Based on the provided information it's now your turn to implement the `ClusterSourceTemplate` and add it as the first resource to the ClusterSupplyChain.
```editor:append-lines-to-file
file: custom-supply-chain/source-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: custom-source-template-{{ session_namespace }}
  spec:
    urlPath: ""
    revisionPath: ""
    template: {}
```

```section:begin
title: Solution ClusterSourceTemplate
```

```editor:select-matching-text
file: custom-supply-chain/supply-chain.yaml
text: "  resources: []"
```

```editor:replace-text-selection
file: custom-supply-chain/supply-chain.yaml
text: |2
    resources:
    - name: source-provider
      templateRef:
        kind: ClusterSourceTemplate
        name: custom-source-template-{{ session_namespace }}
```

```editor:select-matching-text
file: custom-supply-chain/source-template.yaml
text: "  template: {}"
```
```editor:replace-text-selection
file: custom-supply-chain/source-template.yaml
text: |2
    template:
      apiVersion: timosalm.de/v1
      kind: GitHubRepository
      metadata:
        name: $(workload.metadata.name)$
      spec:
        url: $(workload.spec.source.git.url)$
        branch: $(workload.spec.source.git.ref.branch)$
```

```editor:select-matching-text
file: custom-supply-chain/source-template.yaml
text: "  urlPath: \"\""
after: 1
```
```editor:replace-text-selection
file: custom-supply-chain/source-template.yaml
text: |2
    urlPath: .status.artifact.url
    revisionPath: .status.artifact.revision
```
```section:end
```

As with our simple supply chain, the **second step** is responsible for building of a container out of the provided source-code by the first step. 
In addition to kpack, with our custom supply chain we want to provide a solution that builds a container image based on a **Dockerfile**. 
**[kaniko](https://github.com/GoogleContainerTools/kaniko)** is the solution we'll use for it. It's a tool to build container images from a Dockerfile, inside a container or Kubernetes cluster. 
Because there is **no official Kubernetes CRD** for it available, we will use **Tekton** to run it in a container.

Let's first create the skeleton for our new `ClusterImageTemplate`. As you can se we also added an additional ytt function that generates the context sub-path out of the Git url and revision which we need for our custom implementation.
```editor:append-lines-to-file
file: custom-supply-chain/image-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterImageTemplate
  metadata:
    name: custom-image-template-{{ session_namespace }}
  spec:
    params:
      - name: registry
        default: {}
    imagePath: ""
    ytt: |
      #@ load("@ytt:data", "data")

      #@ def image():
      #@   return "/".join([
      #@    data.values.params.registry.server,
      #@    data.values.params.registry.repository,
      #@    "-".join([
      #@      data.values.workload.metadata.name,
      #@      data.values.workload.metadata.namespace,
      #@    ])
      #@   ])
      #@ end

      #@ def context_sub_path():
      #@   return data.values.workload.spec.source.git.url.replace("https://github.com/","").replace(".git","").replace("/","-") + "-" + data.values.source.revision[0:7]
      #@ end
```

We can reuse the relevant part of the simple supply chain for it but the goal is to switch between our different implementations (kpack and kaniko) based on a selector - in this case whether the `dockerfile` parameter in the Workload is set or not.
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2
    - name: image-builder
      templateRef:
        kind: ClusterImageTemplate
        name: kpack-template
      sources:
      - name: source
        resource: source-provider
      params:
      - name: registry
        value:
          server: harbor.emea.end2end.link
          repository: tap-wkld
```
This is possible via the `spec.resources[*].templateRef.options`. The documentation is available here:
```dashboard:open-url
url: https://cartographer.sh/docs/v0.4.0/reference/workload/#clustersupplychain
```

Due to the complexity, here is the ClusterRunTemplate which you have to reference from a Runnable that you have to define with its inputs in the ClusterImageTemplate. You can for sure also try to implement it yourself but please with the name "custom-kaniko-run-template-{{ session_namespace }}"
```editor:append-lines-to-file
file: custom-supply-chain/kaniko-run-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: ClusterRunTemplate
    metadata:
      name: custom-kaniko-run-template-{{ session_namespace }}
    spec:
      outputs:
        latest-image: .status.taskResults[?(@.name=="latest-image")].value
      template:
        apiVersion: tekton.dev/v1beta1
        kind: TaskRun
        metadata:
          generateName: $(runnable.metadata.name)$-
        spec:
          taskSpec:
            results:
            - name: latest-image
            steps:
            - name: download-and-unpack-tarball
              image: alpine
              script: |-
                cd `mktemp -d`
                wget -qO- $(runnable.spec.inputs.source-url)$ | tar xvz -m

                cp -a $(runnable.spec.inputs.source-subpath)$/. /source
              volumeMounts:
              - name: source-dir
                mountPath: /source
            - image: gcr.io/kaniko-project/executor:latest
              name: build-container-and-push
              args:
              - --dockerfile=$(runnable.spec.inputs.dockerfile)$
              - --context=dir:///source
              - --destination=$(runnable.spec.inputs.image)$
              - --digest-file=/tekton/results/digest-file
              securityContext:
                runAsUser: 0
              volumeMounts:
                - name: source-dir
                  mountPath: /source
                - name: kaniko-secret
                  mountPath: /kaniko/.docker
            - name: write-image-ref
              image: alpine
              script: |
                image=$(runnable.spec.inputs.image)$
                digest_path=/tekton/results/digest-file
                digest="$(cat ${digest_path})"

                echo -n "${image}@${digest}" | tee /tekton/results/latest-image
            volumes:
              - name: source-dir
                emptyDir: {}
              - name: kaniko-secret
                secret:
                  secretName: registry-credentials
                  items:
                    - key: .dockerconfigjson
                      path: config.json
```

```section:begin
title: Solution ClusterImageTemplate
```
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2
    - name: image-builder
      templateRef:
        kind: ClusterImageTemplate
        options:
        - name: kpack-template
          selector:
            matchFields:
              - key: spec.params[?(@.name=="dockerfile")]
                operator: DoesNotExist
        - name: custom-image-template-{{ session_namespace }}
          selector:
            matchFields:
              - key: spec.params[?(@.name=="dockerfile")]
                operator: Exists
      sources:
      - name: source
        resource: source-provider
      params:
      - name: registry
        value:
          server: harbor.emea.end2end.link
          repository: tap-wkld
      - name: dockerfile
        default: ""
```
```editor:append-lines-to-file
file: custom-supply-chain/image-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: Runnable
    metadata:
      name: #@ data.values.workload.metadata.name + "-kaniko"
    spec:
      runTemplateRef:
        name: custom-kaniko-run-template-{{ session_namespace }}

      inputs:
        image: #@ image()
        dockerfile: #@ data.values.params.dockerfile
        source-url: #@ data.values.sources.source.url
        source-revision: #@ data.values.sources.source.revision
        source-subpath: #@ context_sub_path()
```
```editor:select-matching-text
file: custom-supply-chain/source-template.yaml
text: "  imagePath: \"\""
```
```editor:replace-text-selection
file: custom-supply-chain/source-template.yaml
text: |2
    imagePath: .status.outputs.latest-image
```

```section:end
```

In our last step now just want to deploy the built container with a [Knative Serving Service](https://knative.dev/docs/serving/services/creating-services/) using an ClusterTemplate. Don't forget to add it as a resource with the required input to the ClusterSupplyChain.

```editor:append-lines-to-file
file: custom-supply-chain/deployment-templatee.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterTemplate
  metadata:
    name: custom-deployment-template-{{ session_namespace }}
  spec:
```

```section:begin
title: Solution ClusterTemplate
```
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2
    - name: deployment
      templateRef:
        kind: ClusterTemplate
        name: custom-deployment-template-{{ session_namespace }}
      images:
      - resource: image-builder
        name: image
```
```editor:append-lines-to-file
file: custom-supply-chain/deployment-template.yaml
text: |2
    template:
      apiVersion: serving.knative.dev/v1
      kind: Service
      metadata:
        name: $(workload.metadata.name)$
      spec:
        template: 
          spec:
            containers:
            - image: $(image)
              name: workload
              ports:
              - containerPort: 8080
```
```section:end
```

We are now able to apply our custom supply chain to the cluster.
```terminal:execute
command: kapp deploy -a custom-supply-chain -f custom-supply-chain -y
clear: true
```
To test it we last but not least have to create a **matching Workload**, ...
```editor:append-lines-to-file
file: custom-supply-chain/workload-custom-sc.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: Workload
  metadata:
    labels:
      end2end.link/workshop-session: {{ session_namespace }}
      end2end.link/is-custom: "true" 
    name: simple-python-app
  spec:
    params:
    - name: dockerfile
      value: Dockerfile
    source:
      git:
        ref:
          branch: main
        url: https://github.com/tsalm-pivotal/python-hello-world-workshop-example.git
```
... apply it, ...
```terminal:execute
command: |
  kubectl apply -f workload-custom-sc.yaml
clear: true
```
... and then we are able to see via the commercial Supply Chain Choreographer UI plugin and the following commands whether everything works as expected.

```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/{{ session_namespace }}/simple-python-app
```
```terminal:execute
command: kubectl describe clustersupplychain custom-supplychain-{{ session_namespace }}
clear: true
```
```terminal:execute
command: kubectl tree workload simple-python-app
clear: true
```
```terminal:execute
command: kubectl describe workload simple-python-app
clear: true
```
```execute-2
tanzu apps workload tail simple-python-app
```

That's it! You have built your first custom supply chain and hopefully many more will follow.
Let's delete the resources that we applied to the cluster.
```terminal:execute
command: |
  kubectl delete -f workload-custom-sc.yaml
  kapp delete -a custom-supply-chain -y
clear: true
```