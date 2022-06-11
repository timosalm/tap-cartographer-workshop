Let's now explore the two fundamental resources that an operator deploys, **Supply Chains** and **Templates**, and how these interact with the resource a developer deploys, the **Workload**. 
We’ll do this hands-on with an example for a simple supply chain that watches a GIT repository for changes, builds a container image and deploys it to the cluster.
```terminal:execute
command: mkdir simple-supply-chain
```

###### ClusterSupplyChain
Cartographer uses the **ClusterSupplyChain** custom resource to link the different Cartographer objects. 

App operators can describe which "shape of applications" they deal with (via e.g. `spec.selector`) and what series of resources are responsible for creating an artifact that delivers it (via `spec.resources`).

```editor:append-lines-to-file
file: simple-supply-chain/supply-chain.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSupplyChain
  metadata:
    name: simple-supplychain-{{ session_namespace }}
  spec:
    selector:
      end2end.link/workshop-session: {{ session_namespace }}
    resources: []
```

Those **Workloads** that match `spec.selector`, `spec.selectorMatchExpressions`, and/or `spec.selectorMatchFields` then go through the specified resources specified in `spec.resources`.

The **matching of Workloads to a Supply Chain** follows the rule that if the seclectors of several Supply Chains match a Workload, **the more concise match (e.g. more matching labels) is selected**. If **more than one match** is returned, the **Workload will not be assigned to a Supply Chain**. 
In our case we use just a label selector that is unique to this workshop session to ensure that there is no additional match.

A `.spec.serviceAccountRef` configuration refers to the Service account with permissions to create resources submitted by the supply chain. If it's like in our example not set, Cartographer will use the default service account in the Workload's namespace.

Additional parameters can be configured with `.spec.params`. They follow a hierarchy and default values (`.spec.params[*].default`) can be overriden by the Workload in constrast to those set with `.spec.params[*].value`.  

The detailed specification can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/workload/#clustersupplychain
```

###### Workload
Before we define our resources, let's have a look at the **Workload** which is an **abstraction for developers** to configure things like the location of the source code repository, environment variables and service claims for an application to be delivered through the supply chain.
```editor:append-lines-to-file
file: simple-supply-chain/workload.yaml
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

###### Templates

We will now start to implement the first of our series of resources that are responsible for bringing the application to a deliverable state.
Those resources are specified via **Templates**. Each template acts as a wrapper for existing Kubernetes resources and allows them to be used with Cartographer. This way, **Cartographer doesn’t care what tools are used under the hood**.
There are currently four different types of templates that can be use in a Cartographer supply chain: **ClusterSourceTemplate**, **ClusterImageTemplate**, **ClusterConfigTemplate**, and the generic **ClusterTemplate**.

####### ClusterSourceTemplate
 
A **ClusterSourceTemplate** indicates how the supply chain could instantiate an object responsible for providing source code. 
```editor:append-lines-to-file
file: simple-supply-chain/source-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: simple-source-template-{{ session_namespace }}
  spec:
    urlPath: ""
    revisionPath: ""
    template: {}
```
All ClusterSourceTemplate cares about is whether the **urlPath** and **revisionPath** are passed in correctly from the templated object that implements the actual functionality we want to use as part for our path to production.

For our continous path to production where every git commit to the codebase will trigger another execution of the Supply Chain, we need a solution that watches our configured source code GIT repository for changes or will be trigger via e.g. a Webhook and provides the sourcecode for the following steps/resources.

**In best case** there is already a Kubernetes native solution with a **custom resource available for the functionality** we are looking for. **Otherwise, we can leverage a Kubernetes native CI/CD solution** like Tekton to do the job, which is part of TAP. For more **complex and asynchronous functionalities**, we have to **implement our own [Kubernetes Controller](https://kubernetes.io/docs/concepts/architecture/controller/)**.

In this case, the [Flux](https://fluxcd.io) Source Controller is part of TAP for this functionality, which is a Kubernetes operator that helps to acquire artifacts from external sources such as Git, Helm repositories, and S3 buckets. 
We can have a closer look at the custom resource the solution provides via the following command and then only have to configure it as a template in the ClusterSourceTemplate.
```terminal:execute
command: kubectl describe crds gitrepositories
```

There are **two options for templating**:
- **Simple templates** can be defined in `spec.template` and provide string interpolation in a `\$(...)\$` tag with jsonpath syntax.
- **ytt** for complex logic, such as conditionals or looping over collections (defined via `spec.ytt` in Templates).

Both options for templating **provide a data structure** that contains:
- Owner resource (Workload, Deliverable)
- Inputs, that are specified in the ClusterSupplyChain (or ClusterDelivery) for the template (sources, images, configs, deployments)
- Parameters

More information can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/templating/
```

For our first functionailty, we will use a simple template and use the configuration provided by the Workload.
```editor:select-matching-text
file: simple-supply-chain/source-template.yaml
text:   template: {}
```
{% raw %}
```editor:replace-text-selection
file: simple-supply-chain/source-template.yaml
text: |2
    template:
      apiVersion: source.toolkit.fluxcd.io/v1beta1
      kind: GitRepository
      metadata:
        name: $(workload.metadata.name)$
      spec:
        interval: 1m0s
        url: $(workload.spec.source.git.url)$
        ref: $(workload.spec.source.git.ref)$
```
{% endraw %}

On every successful repository sync the status of the custom GitRepository resource will be updated with an url to download an archive that contains the source code and the revision. We can use this information as the output of our Template specified in jsonpath.
```editor:select-matching-text
file: simple-supply-chain/source-template.yaml
text:   urlPath: ""
after: 1
```
```editor:replace-text-selection
file: simple-supply-chain/source-template.yaml
text: |2
    urlPath: .status.artifact.url
    revisionPath: .status.artifact.revision
```

The last thing we have to do is to reference our template in the `spec.resources` of our Supply Chain.
```editor:select-matching-text
file: simple-supply-chain/supply-chain.yaml
text:   resources: []
```
```editor:replace-text-selection
file: simple-supply-chain/supply-chain.yaml
text: |2
    resources:
    - name: source-provider
      templateRef:
        kind: ClusterSourceTemplate
        name: simple-source-template-{{ session_namespace }}
```

With the `spec.resources[*].templateRef.options` field it's also possible to define multiple templates of the same kind for one resource to change the implementation of a step based on a selector.

The detailed specifications of the ClusterSourceTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/template/#clustersourcetemplate
```

####### ClusterImageTemplate
A **ClusterImageTemplate** instructs how the supply chain should instantiate an object responsible for supplying container images.

Sound like a perfect match for our second step in the path to production - building of a container out of the provided source-code by the first step. 
We can consume the outputs of our ClusterSourceTemplate resource in the ClusterImageTemplate by referencing it via the `spec.resources[*].sources` field of our Supply Chain definition. 
```editor:append-lines-to-file
file: simple-supply-chain/supply-chain.yaml
text: |2
    - name: image-builder
      templateRef:
        kind: ClusterImageTemplate
        name: image-template-{{ session_namespace }}
      sources:
      - name: source
        resource: source-provider
      params:
      - name: registry
        value:
          server: harbor.emea.end2end.link
          repository: tap-wkld
```
In addition we also define parameters for the resource with the configuration of a registry server and repository where we want to push our container images to. As we are setting them with `params[*].value` instead of `params[*].default`, they are not overridable by the global ClusterSupplyChain resource's params and the Workload params. 

With all the data we need, we can configure our ClusterImageTemplate resource.
```editor:append-lines-to-file
file: simple-supply-chain/image-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterImageTemplate
  metadata:
    name: image-template-{{ session_namespace }}
  spec:
    params:
      - name: registry
        default: {}
    imagePath: ""
    ytt: ""
```
The ClusterImageTemplate requires the definition of an **imagePath** with the value of a valid image digest that has to be provided in the output of the underlying tool used for container building.
As you can already see, we will use the second option for templating now - ytt.

As a Kubernetes native tool for container building, we will use **VMware Tanzu Build Service** that is based on the OSS **kpack**.
You can have a closer look at the various configuration options of the relevant **Image** custom resource the solution provides here:
```dashboard:open-url
url: https://github.com/pivotal/kpack/blob/main/docs/image.md
```

Let's add it to our ClusterImageTemplate resource.
```editor:select-matching-text
file: simple-supply-chain/image-template.yaml
text:   imagePath: ""
after: 1
```
```editor:replace-text-selection
file: simple-supply-chain/image-template.yaml
text: |2
    imagePath: .status.latestImage
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

      ---
      apiVersion: kpack.io/v1alpha2
      kind: Image
      metadata:
        name: #@ data.values.workload.metadata.name
      spec:
        tag: #@ image()
        source:
          blob:
            url: #@ data.values.source.url
```
We are using a ytt function to construct the tag of the container image and are using the data values defined in our Workload, the parameters and the source input.

When an image resource has successfully built with its current configuration and pushed to the container registry, the custom report will report the up to date fully qualified built OCI image reference in the `status.latestImage` which we can therefore use as the output of our Template specified in jsonpath.

The detailed specifications of the ClusterImageTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/template/#clusterimagetemplate
```

####### ClusterConfigTemplate
A **ClusterConfigTemplate** instructs the supply chain how to instantiate a Kubernetes object like a ConfigMap that knows how to make Kubernetes configurations available to further resources in the chain.

For our simple example we use it to provide the deployment configuration of our application to the last step of our Supply Chain and therefore have to consume the outputs of our ClusterImageTemplate resource by referencing it via the `spec.resources[*].images` field of our Supply Chain definition. 
```editor:append-lines-to-file
file: simple-supply-chain/supply-chain.yaml
text: |2
    - name: app-config
      templateRef:
        kind: ClusterConfigTemplate
        name: config-template-{{ session_namespace }}
      images:
      - resource: image-builder
        name: image
```
For the deployment of our application, we will use Knative, which is a serverless application runtime for Kubernetes with e.g. auto-scaling capabilities to save costs.
```editor:append-lines-to-file
file: simple-supply-chain/config-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterConfigTemplate
  metadata:
    name: config-template-{{ session_namespace }}
  spec:
    configPath: .data
    template: |
      #@ load("@ytt:data", "data")
      #@ load("@ytt:yaml", "yaml")

      #@ def delivery():
      apiVersion: serving.knative.dev/v1
      kind: Service
      metadata:
        name: #@ data.values.workload.metadata.name
      spec:
        template: 
          spec:
            containers:
              image: #@ data.values.image
              name: workload
      #@ end

      ---
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: #@ data.values.workload.metadata.name
      data:
        delivery.yml: #@ yaml.encode(delivery())
```
The ClusterConfigTemplate requires definition of a `spec.configPath` and it will update its status to emit a config value, which is a reflection of the value at the path on the created object. 

The detailed specifications of the ClusterConfigTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/template/#clusterconfigtemplate
```

####### ClusterTemplate
A **ClusterTemplate** instructs the supply chain to instantiate a Kubernetes object that has no outputs to be supplied to other objects in the chain.

To standardize our application deployment to a fleet of clusters we'll use **GitOps** which is an operational model that applies the principles of Git and best practices from software development to infrastructure configuration. 
With the GitOps approach, Git is used to version and store the necessary deployment configuration of our application configuration files as the single source of truth for infrastructure running in development, staging, production, etc. 

The last step of our Supply Chain is therefore the push of the deployment configuration to GIT repository. 
```editor:append-lines-to-file
file: simple-supply-chain/supply-chain.yaml
text: |2
    - name: config-writer
      templateRef:
        kind: ClusterTemplate
        name: config-writer-template-{{ session_namespace }}
      config:
      - resource: app-config
        name: config
```

```editor:append-lines-to-file
file: simple-supply-chain/config-writer-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterTemplate
  metadata:
    name: config-writer-template-{{ session_namespace }}
  spec:
    ytt: ""
```

Because there is no suitable solution for Kubernetes available, the Kubernetes native CI/CD solution [Tekton](https://tekton.dev) will help us to implement it or more precisly **Tekton Pipelines**, which provides the building blocks for the creation of pipelines. 

Tekton Pipelines defines the following entities:
- **Tasks** defuine a series of steps which launch specific build or delivery tools that ingest specific inputs and produce specific outputs.
- **Pipelines** define a series of ordered Tasks if it's getting more complex
- **TaskRuns** and **PipelineRuns** instantiate specific Tasks and Pipelines to execute on a particular set of inputs and produce a particular set of outputs

![Pipeline Run Concept Diagram](../images/tekton-runs.png

**TaskRuns** and **PipelineRuns** are immutable Kubernetes resources and therefore it's not possible to just configure it in our ClusterTemplate, because it will just try to update that immutable Kubernetes resource on every signal for an input change. 

The detailed specifications of the ClusterTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/template/#clustertemplate
```

####### Runnable and ClusterRunTemplate
A **Runnable** object declares the intention of having immutable objects submitted to Kubernetes according to a template ( via ClusterRunTemplate) whenever any of the inputs passed to it changes. i.e., it allows us to provide a mutable spec that drives the creation of immutable objects whenever that spec changes.

A **ClusterRunTemplate** differs from supply chain templates in many aspects (e.g. cannot be referenced directly by a ClusterSupplyChain, **outputs** provide a free-form way of exposing any form of results). It defines how an immutable object should be stamped out based on data provided by a **Runnable**.

Sounds like we've found a way to stamp out our immutable **TaskRuns** and **PipelineRuns**.
```editor:select-matching-text
file: simple-supply-chain/config-writer-template.yaml
text:   ytt: ""
```
```editor:replace-text-selection
file: simple-supply-chain/config-writer-template.yaml
text: |2
    imagePath: .status.latestImage
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

    ---
    apiVersion: carto.run/v1alpha1
    kind: Runnable
    metadata:
      name: #@ data.values.workload.metadata.name + "-config-writer"
    spec:
      runTemplateRef:
        name: run-template-{{ session_namespace }}

      inputs:
        git_repository: #@ git_repository()
        git_files: #@ data.values.config
```

```editor:append-lines-to-file
file: simple-supply-chain/run-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterRunTemplate
  metadata:
    name: run-template-{{ session_namespace }}
  spec:
    outputs: {}
    template: {}
```
`spec.outputs` provides a free-form way of exposing any form of results from what has been run to the status of the Runnable object (as opposed to typed “source”, “image”, and “config” from supply chains). Because we don't have the need to expose any outputs to our Supply Chain and therefore using a ClusterTemplate, we don't have to specify it.

We'll now configure a TaskRun to push the deployment configuration to a GIT repository.
```editor:select-matching-text
file: simple-supply-chain/run-template.yaml
text:   outputs: {}
after: 1
```
```editor:replace-text-selection
file: simple-supply-chain/run-template.yaml
text: |2
    template:
      apiVersion: tekton.dev/v1beta1
      kind: TaskRun
      metadata:
        generateName: $(runnable.metadata.name)$-
      spec:
        taskRef:
          name: git-cli
        workspaces:
        - name: ssh-directory
          secret:
            secretName: git-ssh-credentials
        params:
          - name: GIT_USER_NAME
            value: {{ session_namespace }}
          - name: GIT_USER_EMAIL
            value: {{ session_namespace }}@vmware.com
          - name: GIT_SCRIPT
            value: |
              if git clone --depth 1 -b main "$(runnable.spec.inputs.git_repository)$" ./repo; then
                cd ./repo
              else
                git clone --depth 1 "$(runnable.spec.inputs.git_repository)$" ./repo
                cd ./repo
                git checkout -b main
              fi

              mkdir -p config && rm -rf config/*
              cd config

              echo '$(runnable.spec.inputs.git_files)' > files.yaml
              git add .

              git commit -m "Update deployment configuration"
              git push origin $(params.git_branch)
```

The detailed specifications of the Runnable and ClusterRunTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/runnable/
```


- **ClusterDeploymentTemplate** indicates how the delivery should configure the environment

```
A **Deliverable** allows the operator to pass information about the configuration to be applied to the environment to the **Delivery**, which continuously deploys and validates Kubernetes configuration to a cluster.
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/deliverable/
```
