
The easiest way to get started with building a custom supply chain is to copy one of the out-of-the-box supply chains from the cluster, change the `metadata.name`, and add a unique selector by e.g. adding a label to the `spec.selector` configuration.

For this exercise, we will build one from scratch and discover the three ways of providing an implementation for a template:
- Using a Kubernetes custom resource that is already available for the functionality we are looking for
- Leverage a Kubernetes native CI/CD solution like Tekton to do the job, which is part of TAP
- For more **complex and asynchronous functionalities**, one needs to **implement their own [Kubernetes Controller](https://kubernetes.io/docs/concepts/architecture/controller/)**. We will not be able to cover that in this workshop

You are invited to implement the custom supply chain yourself based on the information and basic templates which you have use to **avoid conflicts with other workshop sessions**. Due to the complexity, it's not part of the workshop as of right now to build a custom Kubernetes Controller, and therefore, we will just have a look at an example.
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
    labels:
      apps.tanzu.vmware.com/workload-type: web
      end2end.link/is-custom: "true"
      end2end.link/workshop-session: {{ session_namespace }}
  spec:
    selector:
      end2end.link/workshop-session: {{ session_namespace }}
      end2end.link/is-custom: "true"
    params:
    - name: maven_repository_url
      value: https://repo.maven.apache.org/maven2
    - default: main
      name: gitops_branch
    - default: supplychain
      name: gitops_user_name
    - default: supplychain
      name: gitops_user_email
    - default: supplychain@cluster.local
      name: gitops_commit_message
    - default: ""
      name: gitops_ssh_secret  
    resources: []
```
As with the other supply chains you already saw, the **first task** for our custom supply chain is also to **provide the latest version of a source code in a Git repository for subsequent steps**.
In the simple and ootb supply chains we used the [Flux](https://fluxcd.io) Source Controller for it. 

The application then has to be packaged in a container, deployed to Kubernetes, and exposed to be reachable by the GitHub Webhook of a Git repository that also has to be configured - which is already done for you.

Based on the provided information it's now your turn to implement the `ClusterSourceTemplate` and add it as the first resource to the ClusterSupplyChain.
```editor:append-lines-to-file
file: custom-supply-chain/custom-source-provider-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: custom-source-provider-template-{{ session_namespace }}
  spec:
    urlPath: ""
    revisionPath: ""
    ytt: ""
```
In TAP 1.2 we have the ability to detect the **Health Status** of the Supply Chain component. To accomplish that, we need to add `healthRule` spec to the respective component. We will be  adding for the rest of the components.
This is possible via the `spec.healthRule`. The documentation is available here:
```dashboard:reload-dashboard
name: Cartographer Docs
url: https://cartographer.sh/docs/v0.4.0/health-rules/
```
```editor:append-lines-to-file
file: custom-supply-chain/custom-source-provider-template.yaml
text: |2
    healthRule:
      singleConditionType: Ready
```

We will continue `ClusterSourceTemplate` in this below section. Click below tile to expand it first.

```editor:select-matching-text
file: custom-supply-chain/supply-chain.yaml
text: "  resources: []"
```
Add `source-provider` to Supply Chain.
```editor:replace-text-selection
file: custom-supply-chain/supply-chain.yaml
text: |2
    resources:

    - name: source-provider
      params:
      - name: serviceAccount
        value: default
      - name: gitImplementation
        value: go-git
      templateRef:
        kind: ClusterSourceTemplate
        name: custom-source-provider-template-{{ session_namespace }}
```
Replace the `ytt` with actual steps with adding a `GitRepository` kind.
```editor:select-matching-text
file: custom-supply-chain/custom-source-provider-template.yaml
text: "  ytt: \"\""
```
```editor:replace-text-selection
file: custom-supply-chain/custom-source-provider-template.yaml
text: |2
    ytt: |
      #@ load("@ytt:data", "data")
      #@ load("@ytt:yaml", "yaml")

      #@ def merge_labels(fixed_values):
      #@   labels = {}
      #@   if hasattr(data.values.workload.metadata, "labels"):
      #@     labels.update(data.values.workload.metadata.labels)
      #@   end
      #@   labels.update(fixed_values)
      #@   return labels
      #@ end

      #@ def param(key):
      #@   if not key in data.values.params:
      #@     return None
      #@   end
      #@   return data.values.params[key]
      #@ end

      #@ if hasattr(data.values.workload.spec, "source"):
      #@ if/end hasattr(data.values.workload.spec.source, "git"):
      ---
      apiVersion: source.toolkit.fluxcd.io/v1beta1
      kind: GitRepository
      metadata:
        name: #@ data.values.workload.metadata.name
        labels: #@ merge_labels({ "app.kubernetes.io/part-of": data.values.workload.metadata.name })
      spec:
        interval: 1m0s
        url: #@ data.values.workload.spec.source.git.url
        ref: #@ data.values.workload.spec.source.git.ref
        ignore: |
          !.git
        #@ if/end param("gitops_ssh_secret"):
        secretRef:
          name: #@ param("gitops_ssh_secret")
      #@ end

      #@ if hasattr(data.values.workload.spec, "source"):
      #@ if/end hasattr(data.values.workload.spec.source, "image"):
      ---
      apiVersion: source.apps.tanzu.vmware.com/v1alpha1
      kind: ImageRepository
      metadata:
        name: #@ data.values.workload.metadata.name
        labels: #@ merge_labels({ "app.kubernetes.io/component": "source" })
      spec:
        serviceAccountName: #@ data.values.params.serviceAccount
        interval: 1m0s
        image: #@ data.values.workload.spec.source.image
      #@ end
```

```editor:select-matching-text
file: custom-supply-chain/custom-source-provider-template.yaml
text: "  urlPath: \"\""
after: 1
```
```editor:replace-text-selection
file: custom-supply-chain/custom-source-provider-template.yaml
text: |2
    urlPath: .status.artifact.url
    revisionPath: .status.artifact.revision
```

Since we want to enforce the source testing, we need to consider creating another `ClusterSourceTemplate` and add its reference as `source-tester` to the supply chain.
Lets add the template `ClusterSourceTemplate`.

Create a template now:
```editor:append-lines-to-file
file: custom-supply-chain/custom-source-tester-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: custom-source-tester-template-{{ session_namespace }}
  spec:
    healthRule:
      singleConditionType: Ready
    revisionPath: .status.outputs.revision
    urlPath: .status.outputs.url
    ytt: |
      #@ load("@ytt:data", "data")

      #@ def merge_labels(fixed_values):
      #@   labels = {}
      #@   if hasattr(data.values.workload.metadata, "labels"):
      #@     labels.update(data.values.workload.metadata.labels)
      #@   end
      #@   labels.update(fixed_values)
      #@   return labels
      #@ end

      ---
      apiVersion: carto.run/v1alpha1
      kind: Runnable
      metadata:
        name: #@ data.values.workload.metadata.name
        labels: #@ merge_labels({ "app.kubernetes.io/component": "test" })
      spec:
        #@ if/end hasattr(data.values.workload.spec, "serviceAccountName"):
        serviceAccountName: #@ data.values.workload.spec.serviceAccountName

        runTemplateRef:
          name: tekton-source-pipelinerun
          kind: ClusterRunTemplate

        selector:
          resource:
            apiVersion: tekton.dev/v1beta1
            kind: Pipeline
          matchingLabels:
            apps.tanzu.vmware.com/pipeline: test

        inputs:
          source-url: #@ data.values.source.url
          source-revision: #@ data.values.source.revision
```
Add reference to Supply Chain.
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - name: source-tester
      sources:
      - name: source
        resource: source-provider
      templateRef:
        kind: ClusterSourceTemplate
        name: custom-source-tester-template-{{ session_namespace }}
```

We have a requirement to scan our source code for any coding or dependency level CVEs. Let's add those pieces together to get it done.
To achieve this, we will need to create a `ClusterSourceTemplate` that uses `SourceScan`, and then add the reference of it to the Supply Chain. 
Lets understand what this section is. We are using a scan policy (`ScanPolicy`) named `scan-policy` and the scanning template (`ScanTemplate`) named `blob-source-scan-template` via `scanning.apps.tanzu.vmware.com/v1beta1` that was already deployed on this workshop & the TAP cluster by OOTB supply chain. We can change the policies and templates with our custom ones. We will explain this more during the image scanning section when we add it to the supply chain.

Create a template now:
```editor:append-lines-to-file
file: custom-supply-chain/custom-source-scanner-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: custom-source-scanner-template-{{ session_namespace }}
  spec:
    healthRule:
      singleConditionType: Succeeded
    revisionPath: .status.compliantArtifact.blob.revision
    urlPath: .status.compliantArtifact.blob.url
    ytt: |
      #@ load("@ytt:data", "data")

      #@ def merge_labels(fixed_values):
      #@   labels = {}
      #@   if hasattr(data.values.workload.metadata, "labels"):
      #@     labels.update(data.values.workload.metadata.labels)
      #@   end
      #@   labels.update(fixed_values)
      #@   return labels
      #@ end

      ---
      apiVersion: scanning.apps.tanzu.vmware.com/v1beta1
      kind: SourceScan
      metadata:
        name: #@ data.values.workload.metadata.name
        labels: #@ merge_labels({ "app.kubernetes.io/component": "source-scan" })
      spec:
        blob:
          url: #@ data.values.source.url
          revision: #@ data.values.source.revision
        scanTemplate: #@ data.values.params.scanning_source_template
        scanPolicy: #@ data.values.params.scanning_source_policy
```
Lets add a reference to the Supply Chain.
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - name: source-scanner
      params:
      - default: scan-policy
        name: scanning_source_policy
      - default: blob-source-scan-template
        name: scanning_source_template
      sources:
      - name: source
        resource: source-tester
      templateRef:
        kind: ClusterSourceTemplate
        name: custom-source-scanner-template-{{ session_namespace }}
```

As with our custom supply chain, the **next step** is responsible for the building of a container image out of the provided source code by the first step. 

TODO: Add colapsable for `kpack` and `Dockerfile` deploy

In addition to `kpack`, with our custom supply chain we want to provide a solution that builds a container image based on a **Dockerfile**. 

**[kaniko](https://github.com/GoogleContainerTools/kaniko)** is the solution we'll use for it. It's a tool to build container images from a Dockerfile, inside a container or Kubernetes cluster. 
Because there is **no official Kubernetes CRD** for it available, we will use **Tekton** to run it in a container.

Let's first create the skeleton for our new `ClusterImageTemplate`. As you can se we also added an additional ytt function that generates the context sub-path out of the Git url and revision which we need for our custom implementation.
```editor:append-lines-to-file
file: custom-supply-chain/custom-image-kaniko-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterImageTemplate
  metadata:
    name: custom-image-kaniko-template-{{ session_namespace }}
  spec:
    healthRule:
      singleConditionType: Ready
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
We can reuse the relevant part of the simple supply chain for it.
```editor:open-file
file: simple-supply-chain/supply-chain.yaml
line: 14
```
But we want to implement in a way that the different implementations (kpack and kaniko) will be switched based on a selector - in this case, whether the `dockerfile` parameter in the Workload is set or not.
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - name: image-builder
      templateRef:
        kind: ClusterImageTemplate
        name: kpack-template # we are using this one `kpack-template` thats deployed by OOTB 
      sources:
      - name: source
        resource: source-scanner
      params:
      - name: registry
        value:
          server: harbor.services.demo.jg-aws.com
          repository: tap-workshop-workloads
```
This is possible via the `spec.resources[*].templateRef.options`. The documentation is available here:
```dashboard:reload-dashboard
name: Cartographer Docs
url: https://cartographer.sh/docs/v0.4.0/reference/workload/#clustersupplychain
```

Due to the complexity, here is the **ClusterRunTemplate which you have to reference from a Runnable** that you have to define with its inputs **in the ClusterImageTemplate**. 

You can for sure also try to implement it yourself but please with the name **"custom-kaniko-run-template-{{ session_namespace }}"**.
```editor:append-lines-to-file
file: custom-supply-chain/custom-kaniko-run-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: ClusterRunTemplate
    metadata:
      name: custom-kaniko-run-template-{{ session_namespace }}
    spec:
      healthRule:
        singleConditionType: Ready
      outputs:
        image-ref: .status.taskResults[?(@.name=="image-ref")].value
      template:
        apiVersion: tekton.dev/v1beta1
        kind: TaskRun
        metadata:
          generateName: $(runnable.metadata.name)$-
        spec:
          taskSpec:
            results:
            - name: image-ref
            steps:
            - name: download-and-unpack-tarball
              image: alpine
              script: |-
                set -xv
                cd `mktemp -d`
                wget -O- $(runnable.spec.inputs.source-url)$ | tar xvz -m -C /source
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

                echo -n "${image}@${digest}" | tee /tekton/results/image-ref
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

```editor:select-matching-text
file: custom-supply-chain/supply-chain.yaml
text: "  - name: image-builder"
after: 11
```
```editor:replace-text-selection
file: custom-supply-chain/supply-chain.yaml
text: |2

    - name: image-builder
      templateRef:
        kind: ClusterImageTemplate
        options:
        - name: kpack-template # we are using this one `kpack-template` thats deployed by OOTB
          selector:
            matchFields:
              - key: spec.params[?(@.name=="dockerfile")]
                operator: DoesNotExist
        - name: custom-image-kaniko-template-{{ session_namespace }} 
          selector:
            matchFields:
              - key: spec.params[?(@.name=="dockerfile")]
                operator: Exists
      sources:
      - name: source
        resource: source-scanner
      params:
      - name: registry
        value:
          server: harbor.services.demo.jg-aws.com
          repository: tap-workshop-workloads
      - name: dockerfile
        default: ""
```
```editor:append-lines-to-file
file: custom-supply-chain/custom-image-kaniko-template.yaml
text: |2
      apiVersion: carto.run/v1alpha1
      kind: Runnable
      metadata:
        name: #@ data.values.workload.metadata.name + "-kaniko"
      spec:
        runTemplateRef:
          name: custom-kaniko-run-template-{{ session_namespace }}
        healthRule:
          singleConditionType: Ready

        inputs:
          image: #@ image()
          dockerfile: #@ data.values.params.dockerfile
          source-url: #@ data.values.sources.source.url
          source-revision: #@ data.values.sources.source.revision
          source-subpath: #@ context_sub_path()
```
```editor:select-matching-text
file: custom-supply-chain/custom-image-kaniko-template.yaml
text: "  imagePath: \"\""
```
```editor:replace-text-selection
file: custom-supply-chain/custom-image-kaniko-template.yaml
text: |2
    imagePath: .status.outputs.image-ref
```


We also have a requirement to scan the container image that was produced in a previous build step. We need to create `ClusterImageTemplate` and add its reference as `image-scanner` to the supply chain.
Lets understand what this section is. We are using a scan policy (`ScanPolicy`) named `lax-scan-policy` that was created as a custom policy thats different than what we have used on Source Scan earlier. Also, the scanning template (`ScanTemplate`) named `private-image-scan-template` is specific template to scan container images for container level CVEs via `scanning.apps.tanzu.vmware.com/v1beta1` that was already deployed on this workshop & the TAP cluster by OOTB supply chain. We can change the policies and templates with our custom ones. We will explain this more during the image scanning section when we add it to the supply chain.

Create a template now:
```editor:append-lines-to-file
file: custom-supply-chain/custom-image-scanner-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterImageTemplate
  metadata:
    name: custom-image-scanner-template-{{ session_namespace }}
  spec:
    healthRule:
      singleConditionType: Succeeded
    imagePath: .status.compliantArtifact.registry.image
    ytt: |
      #@ load("@ytt:data", "data")

      #@ def merge_labels(fixed_values):
      #@   labels = {}
      #@   if hasattr(data.values.workload.metadata, "labels"):
      #@     labels.update(data.values.workload.metadata.labels)
      #@   end
      #@   labels.update(fixed_values)
      #@   return labels
      #@ end

      ---
      apiVersion: scanning.apps.tanzu.vmware.com/v1beta1
      kind: ImageScan
      metadata:
        name: #@ data.values.workload.metadata.name
        labels: #@ merge_labels({ "app.kubernetes.io/component": "image-scan" })
      spec:
        registry:
          image: #@ data.values.image
        scanTemplate: #@ data.values.params.scanning_image_template
        scanPolicy: #@ data.values.params.scanning_image_policy
```
Lets add a reference to the Supply Chain.
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - images:
      - name: image
        resource: image-builder
      name: image-scanner
      params:
      - default: lax-scan-policy
        name: scanning_image_policy
      - default: private-image-scan-template
        name: scanning_image_template
      templateRef:
        kind: ClusterImageTemplate
        name: custom-image-scanner-template-{{ session_namespace }}
```

Let's add `ClusterConfigTemplate`s
Step1: In this step we will add `ClusterConfigTemplate` for `PodIntent` and its reference to the Supply Chain.
Lets add a template:
```editor:append-lines-to-file
file: custom-supply-chain/custom-config-provider-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: ClusterConfigTemplate
    metadata:
      name: custom-config-provider-template-{{ session_namespace }}
    spec:
      configPath: .status.template
      healthRule:
        singleConditionType: Ready
      params:
      - default: default
        name: serviceAccount
      ytt: |
        #@ load("@ytt:data", "data")

        #@ def param(key):
        #@   if not key in data.values.params:
        #@     return None
        #@   end
        #@   return data.values.params[key]
        #@ end

        #@ def merge_labels(fixed_values):
        #@   labels = {}
        #@   if hasattr(data.values.workload.metadata, "labels"):
        #@     labels.update(data.values.workload.metadata.labels)
        #@   end
        #@   labels.update(fixed_values)
        #@   return labels
        #@ end

        #@ def build_fixed_annotations():
        #@   fixed_annotations = { "developer.conventions/target-containers": "workload" }
        #@   if param("debug"):
        #@     fixed_annotations["apps.tanzu.vmware.com/debug"] = param("debug")
        #@   end
        #@   if param("live-update"):
        #@     fixed_annotations["apps.tanzu.vmware.com/live-update"] = param("live-update")
        #@   end
        #@   return fixed_annotations
        #@ end

        #@ def merge_annotations(fixed_values):
        #@   annotations = {}
        #@   if hasattr(data.values.workload.metadata, "annotations"):
        #@     # DEPRECATED: remove in a future release
        #@     annotations.update(data.values.workload.metadata.annotations)
        #@   end
        #@   if type(param("annotations")) == "dict" or type(param("annotations")) == "struct":
        #@     annotations.update(param("annotations"))
        #@   end
        #@   annotations.update(fixed_values)
        #@   return annotations
        #@ end
        ---
        apiVersion: conventions.apps.tanzu.vmware.com/v1alpha1
        kind: PodIntent
        metadata:
          name: #@ data.values.workload.metadata.name
          labels: #@ merge_labels({ "app.kubernetes.io/component": "intent" })
        spec:
          serviceAccountName: #@ data.values.params.serviceAccount
          template:
            metadata:
              annotations: #@ merge_annotations(build_fixed_annotations())
              labels: #@ merge_labels({ "app.kubernetes.io/component": "run", "carto.run/workload-name": data.values.workload.metadata.name })
            spec:
              serviceAccountName: #@ data.values.params.serviceAccount
              containers:
                - name: workload
                  image: #@ data.values.image
                  securityContext:
                    runAsUser: 1000
                  #@ if hasattr(data.values.workload.spec, "env"):
                  env:
                    #@ for var in data.values.workload.spec.env:
                    - name: #@ var.name
                      #@ if/end hasattr(var, "value"):
                      value: #@ var.value
                      #@ if/end hasattr(var, "valueFrom"):
                      valueFrom: #@ var.valueFrom
                    #@ end
                  #@ end
                  #@ if/end hasattr(data.values.workload.spec, "resources"):
                  resources: #@ data.values.workload.spec["resources"]
```
Now add the reference to the supply chain:
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - images:
      - name: image
        resource: image-scanner
      name: config-provider
      params:
      - name: serviceAccount
        value: default
      templateRef:
        kind: ClusterConfigTemplate
        name: custom-config-provider-template-{{ session_namespace }}
```


Step2: In this step we will add `ClusterConfigTemplate` and the `ClusterTemplate` templates and the reference to the Supply Chain for configs.
Lets add a template:
```editor:append-lines-to-file
file: custom-supply-chain/custom-app-config-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: ClusterConfigTemplate
    metadata:
      name: custom-app-config-template-{{ session_namespace }}
    spec:
      configPath: .data
      healthRule:
        alwaysHealthy: {}
      ytt: |
        #@ load("@ytt:data", "data")
        #@ load("@ytt:yaml", "yaml")
        #@ load("@ytt:json", "json")

        #@ def get_claims_extension():
        #@   claims_extension_key = "serviceclaims.supplychain.apps.x-tanzu.vmware.com/extensions"
        #@   if not hasattr(data.values.workload.metadata, "annotations") or not hasattr(data.values.workload.metadata.annotations, claims_extension_key):
        #@     return None
        #@   end
        #@
        #@   extension = json.decode(data.values.workload.metadata.annotations[claims_extension_key])
        #@
        #@   spec_extension = extension.get('spec')
        #@   if spec_extension == None:
        #@     return None
        #@   end
        #@
        #@   return spec_extension.get('serviceClaims')
        #@ end

        #@ def merge_claims_extension(claim, claims_extension):
        #@   if claims_extension == None:
        #@     return claim.ref
        #@   end
        #@   extension = claims_extension.get(claim.name)
        #@   if extension == None:
        #@      return claim.ref
        #@   end
        #@   extension.update(claim.ref)
        #@   return extension
        #@ end

        #@ def param(key):
        #@   if not key in data.values.params:
        #@     return None
        #@   end
        #@   return data.values.params[key]
        #@ end

        #@ def merge_labels(fixed_values):
        #@   labels = {}
        #@   if hasattr(data.values.workload.metadata, "labels"):
        #@     labels.update(data.values.workload.metadata.labels)
        #@   end
        #@   labels.update(fixed_values)
        #@   return labels
        #@ end

        #@ def merge_annotations(fixed_values):
        #@   annotations = {}
        #@   if hasattr(data.values.workload.metadata, "annotations"):
        #@     # DEPRECATED: remove in a future release
        #@     annotations.update(data.values.workload.metadata.annotations)
        #@   end
        #@   if type(param("annotations")) == "dict" or type(param("annotations")) == "struct":
        #@     annotations.update(param("annotations"))
        #@   end
        #@   annotations.update(fixed_values)
        #@   return annotations
        #@ end

        #@ def delivery():
        apiVersion: serving.knative.dev/v1
        kind: Service
        metadata:
          name: #@ data.values.workload.metadata.name
          #! annotations NOT merged because knative annotations would be invalid here
          labels: #@ merge_labels({ "app.kubernetes.io/component": "run", "carto.run/workload-name": data.values.workload.metadata.name })
        spec:
          template: #@ data.values.config
        #@ end

        #@ def claims():
        #@ claims_extension = get_claims_extension()
        #@ for s in data.values.workload.spec.serviceClaims:
        #@ if claims_extension == None or claims_extension.get(s.name) == None:
        ---
        apiVersion: servicebinding.io/v1alpha3
        kind: ServiceBinding
        metadata:
          name: #@ data.values.workload.metadata.name + '-' + s.name
          annotations: #@ merge_annotations({})
          labels: #@ merge_labels({ "app.kubernetes.io/component": "run", "carto.run/workload-name": data.values.workload.metadata.name })
        spec:
          name: #@ s.name
          service: #@ s.ref
          workload:
            apiVersion: serving.knative.dev/v1
            kind: Service
            name: #@ data.values.workload.metadata.name
        #@ else:
        ---
        apiVersion: services.apps.tanzu.vmware.com/v1alpha1
        kind: ResourceClaim
        metadata:
          name: #@ data.values.workload.metadata.name + '-' + s.name
          annotations: #@ merge_annotations({})
          labels: #@ merge_labels({ "app.kubernetes.io/component": "run", "carto.run/workload-name": data.values.workload.metadata.name })
        spec:
          ref: #@ merge_claims_extension(s, claims_extension)
        ---
        apiVersion: servicebinding.io/v1alpha3
        kind: ServiceBinding
        metadata:
          name: #@ data.values.workload.metadata.name + '-' + s.name
          annotations: #@ merge_annotations({})
          labels: #@ merge_labels({ "app.kubernetes.io/component": "run", "carto.run/workload-name": data.values.workload.metadata.name })
        spec:
          name: #@ s.name
          service:
            apiVersion: services.apps.tanzu.vmware.com/v1alpha1
            kind: ResourceClaim
            name: #@ data.values.workload.metadata.name + '-' + s.name
          workload:
            apiVersion: serving.knative.dev/v1
            kind: Service
            name: #@ data.values.workload.metadata.name
        #@ end
        #@ end
        #@ end

        ---
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: #@ data.values.workload.metadata.name
          labels: #@ merge_labels({ "app.kubernetes.io/component": "config" })
        data:
          delivery.yml: #@ yaml.encode(delivery())
          #@ if hasattr(data.values.workload.spec, "serviceClaims") and len(data.values.workload.spec.serviceClaims):
          serviceclaims.yml: #@ yaml.encode(claims())
          #@ end
```
Now add the reference to the supply chain:
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - configs:
      - name: config
        resource: config-provider
      name: app-config
      templateRef:
        kind: ClusterConfigTemplate
        name: custom-app-config-template-{{ session_namespace }}
```

Lets add a template:
```editor:append-lines-to-file
file: custom-supply-chain/custom-config-writer-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: ClusterTemplate
    metadata:
      name: custom-config-writer-template-{{ session_namespace }}
    spec:
      healthRule:
        singleConditionType: Ready
      params:
      - default: default
        name: serviceAccount
      - default: {}
        name: registry
      ytt: |
        #@ load("@ytt:data", "data")
        #@ load("@ytt:json", "json")
        #@ load("@ytt:base64", "base64")
        #@ load("@ytt:assert", "assert")

        #@ def merge_labels(fixed_values):
        #@   labels = {}
        #@   if hasattr(data.values.workload.metadata, "labels"):
        #@     labels.update(data.values.workload.metadata.labels)
        #@   end
        #@   labels.update(fixed_values)
        #@   return labels
        #@ end

        #@ def is_monorepo_approach():
        #@   if 'gitops_server_address' in data.values.params and 'gitops_repository_owner' in data.values.params and 'gitops_repository_name' in data.values.params:
        #@     return True
        #@   end
        #@   if 'gitops_server_address' in data.values.params or 'gitops_repository_owner' in data.values.params or 'gitops_repository_name' in data.values.params:
        #@     'gitops_server_address' in data.values.params or assert.fail("missing param: gitops_server_address")
        #@     'gitops_repository_owner' in data.values.params or assert.fail("missing param: gitops_repository_owner")
        #@     'gitops_repository_name' in data.values.params or assert.fail("missing param: gitops_repository_name")
        #@   end
        #@   return False
        #@ end

        #@ def has_git_params():
        #@   if 'gitops_repository_prefix' in data.values.params:
        #@     return True
        #@   end
        #@
        #@   if 'gitops_repository' in data.values.params:
        #@     return True
        #@   end
        #@
        #@   return False
        #@ end

        #@ def is_gitops():
        #@   return is_monorepo_approach() or has_git_params()
        #@ end

        #@ def param(key):
        #@   if not key in data.values.params:
        #@     return None
        #@   end
        #@   return data.values.params[key]
        #@ end

        #@ def strip_trailing_slash(some_string):
        #@   if some_string[-1] == "/":
        #@     return some_string[:-1]
        #@   end
        #@   return some_string
        #@ end

        #@ def mono_repository():
        #@   strip_trailing_slash(data.values.params.gitops_server_address)
        #@   return "/".join([
        #@     strip_trailing_slash(data.values.params.gitops_server_address),
        #@     strip_trailing_slash(data.values.params.gitops_repository_owner),
        #@     data.values.params.gitops_repository_name,
        #@   ]) + ".git"
        #@ end

        #@ def git_repository():
        #@   if is_monorepo_approach():
        #@     return mono_repository()
        #@   end
        #@
        #@   if 'gitops_repository' in data.values.params:
        #@     return param("gitops_repository")
        #@   end
        #@
        #@   prefix = param("gitops_repository_prefix")
        #@   return prefix + data.values.workload.metadata.name + ".git"
        #@ end

        #@ def image():
        #@   return "/".join([
        #@    data.values.params.registry.server,
        #@    data.values.params.registry.repository,
        #@    "-".join([
        #@      data.values.workload.metadata.name,
        #@      data.values.workload.metadata.namespace,
        #@      "bundle",
        #@    ])
        #@   ]) + ":" + data.values.workload.metadata.uid
        #@ end

        #@ def ca_cert_data():
        #@   if "ca_cert_data" not in param("registry"):
        #@     return ""
        #@   end
        #@
        #@   return param("registry")["ca_cert_data"]
        #@ end

        ---
        apiVersion: carto.run/v1alpha1
        kind: Runnable
        metadata:
          name: #@ data.values.workload.metadata.name + "-config-writer"
          labels: #@ merge_labels({ "app.kubernetes.io/component": "config-writer" })
        spec:
          #@ if/end hasattr(data.values.workload.spec, "serviceAccountName"):
          serviceAccountName: #@ data.values.workload.spec.serviceAccountName

          runTemplateRef:
            name: tekton-taskrun

          inputs:
            serviceAccount: #@ data.values.params.serviceAccount
            taskRef:
              kind: ClusterTask
              name: #@ "git-writer" if is_gitops() else "image-writer"
            params:
              #@ if is_gitops():
              - name: git_repository
                value: #@ git_repository()
              - name: git_branch
                value: #@ param("gitops_branch")
              - name: git_user_name
                value: #@ param("gitops_user_name")
              - name: git_user_email
                value: #@ param("gitops_user_email")
              - name: git_commit_message
                value: #@ param("gitops_commit_message")
              - name: git_files
                value: #@ base64.encode(json.encode(data.values.config))
              #@ if/end is_monorepo_approach():
              - name: sub_path
                value: #@ "config/" + data.values.workload.metadata.namespace + "/" + data.values.workload.metadata.name
              #@ else:
              - name: files
                value: #@ base64.encode(json.encode(data.values.config))
              - name: bundle
                value: #@ image()
              - name: ca_cert_data
                value: #@ ca_cert_data()
              #@ end
```
Reference:
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - configs:
      - name: config
        resource: app-config
      name: config-writer
      params:
      - name: serviceAccount
        value: default
      - name: registry
        value:
          ca_cert_data: ""
          repository: tap-workshop-workloads
          server: harbor.services.demo.jg-aws.com
      templateRef:
        kind: ClusterTemplate
        name: custom-config-writer-template-{{ session_namespace }}
```

**Finally**, lets add a deliverable before we apply the supply chain to the cluster.
Lets add a `ClusterTemplate`:
```editor:append-lines-to-file
file: custom-supply-chain/custom-deliverable-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: ClusterTemplate
    metadata:
      labels:
        app.tanzu.vmware.com/deliverable-type: web
      name: custom-deliverable-template-{{ session_namespace }}
    spec:
      params:
      - default: {}
        name: registry
      ytt: |
        #@ load("@ytt:data", "data")
        #@ load("@ytt:assert", "assert")

        #@ def merge_labels(fixed_values):
        #@   labels = {}
        #@   if hasattr(data.values.workload.metadata, "labels"):
        #@     labels.update(data.values.workload.metadata.labels)
        #@   end
        #@   labels.update(fixed_values)
        #@   return labels
        #@ end

        #@ def is_monorepo_approach():
        #@   if 'gitops_server_address' in data.values.params and 'gitops_repository_owner' in data.values.params and 'gitops_repository_name' in data.values.params:
        #@     return True
        #@   end
        #@   if 'gitops_server_address' in data.values.params or 'gitops_repository_owner' in data.values.params or 'gitops_repository_name' in data.values.params:
        #@     'gitops_server_address' in data.values.params or assert.fail("missing param: gitops_server_address")
        #@     'gitops_repository_owner' in data.values.params or assert.fail("missing param: gitops_repository_owner")
        #@     'gitops_repository_name' in data.values.params or assert.fail("missing param: gitops_repository_name")
        #@   end
        #@   return False
        #@ end

        #@ def has_git_params():
        #@   if 'gitops_repository_prefix' in data.values.params:
        #@     return True
        #@   end
        #@
        #@   if 'gitops_repository' in data.values.params:
        #@     return True
        #@   end
        #@
        #@   return False
        #@ end

        #@ def is_gitops():
        #@   return is_monorepo_approach() or has_git_params()
        #@ end

        #@ def param(key):
        #@   if not key in data.values.params:
        #@     return None
        #@   end
        #@   return data.values.params[key]
        #@ end

        #@ def strip_trailing_slash(some_string):
        #@   if some_string[-1] == "/":
        #@     return some_string[:-1]
        #@   end
        #@   return some_string
        #@ end

        #@ def mono_repository():
        #@   strip_trailing_slash(data.values.params.gitops_server_address)
        #@   return "/".join([
        #@     strip_trailing_slash(data.values.params.gitops_server_address),
        #@     strip_trailing_slash(data.values.params.gitops_repository_owner),
        #@     data.values.params.gitops_repository_name,
        #@   ]) + ".git"
        #@ end

        #@ def git_repository():
        #@   if is_monorepo_approach():
        #@     return mono_repository()
        #@   end
        #@
        #@   if 'gitops_repository' in data.values.params:
        #@     return param("gitops_repository")
        #@   end
        #@
        #@   prefix = param("gitops_repository_prefix")
        #@   return prefix + data.values.workload.metadata.name + ".git"
        #@ end

        #@ def image():
        #@   return "/".join([
        #@    data.values.params.registry.server,
        #@    data.values.params.registry.repository,
        #@    "-".join([
        #@      data.values.workload.metadata.name,
        #@      data.values.workload.metadata.namespace,
        #@      "bundle",
        #@    ])
        #@   ]) + ":" + data.values.workload.metadata.uid
        #@ end
        ---
        apiVersion: carto.run/v1alpha1
        kind: Deliverable
        metadata:
          name: #@ data.values.workload.metadata.name
          labels: #@ merge_labels({ "app.kubernetes.io/component": "deliverable", "app.tanzu.vmware.com/deliverable-type": "web" })
        spec:
          #@ if/end hasattr(data.values.workload.spec, "serviceAccountName"):
          serviceAccountName: #@ data.values.workload.spec.serviceAccountName

          #@ if/end is_gitops():
          params:
            - name: "gitops_ssh_secret"
              value: #@ param("gitops_ssh_secret")
            #@ if/end is_monorepo_approach():
            - name: gitops_sub_path
              value: #@ "config/" + data.values.workload.metadata.namespace + "/" + data.values.workload.metadata.name

          source:
            #@ if/end is_gitops():
            git:
              url: #@ git_repository()
              ref:
                branch: #@ param("gitops_branch")

            #@ if/end not is_gitops():
            image: #@ image()
```
Reference to the supply chain:
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2

    - name: deliverable
      params:
      - name: registry
        value:
          ca_cert_data: ""
          repository: tap-workshop-workloads
          server: harbor.services.demo.jg-aws.com
      templateRef:
        kind: ClusterTemplate
        name: custom-deliverable-template-{{ session_namespace }}
```

We are now able to apply our custom supply chain to the cluster.
```terminal:execute
command: kapp deploy -a custom-supply-chain -f custom-supply-chain -y --dangerous-scope-to-fallback-allowed-namespaces
clear: true
```
To test it we last but not least have to create a **matching Workload**, ...
```editor:append-lines-to-file
file: workloads/workload-custom-sc.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: Workload
  metadata:
    labels:
      app.kubernetes.io/part-of: app-with-custom-supply-chain
      apps.tanzu.vmware.com/workload-type: web
      end2end.link/workshop-session: {{ session_namespace }}
      end2end.link/is-custom: "true" 
    name: app-with-custom-supply-chain
  spec:
    params:
    - name: dockerfile
      value: Dockerfile
    source:
      git:
        ref:
          branch: dockerfile
        url: https://github.com/sample-accelerators/tanzu-java-web-app.git
```
... apply it, ...
```terminal:execute
command: |
  kubectl apply -f workloads/workload-custom-sc.yaml
clear: true
```
... and then we are able to see via the commercial Supply Chain Choreographer UI plugin and the following commands whether everything works as expected.

```dashboard:reload-dashboard
name: TAP Gui for Supply Chain
url: http://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/app-with-custom-supply-chain
```
```terminal:execute
command: kubectl describe clustersupplychain custom-supplychain-{{ session_namespace }}
clear: true
```
```terminal:execute
command: kubectl tree workload app-with-custom-supply-chain
clear: true
```
```terminal:execute
command: tanzu apps workload get app-with-custom-supply-chain
clear: true
```
```execute-2
tanzu apps workload tail app-with-custom-supply-chain
```
Now that we deployed our workload, let's confirm by going to the following URL
```dashboard:create-dashboard
name: app-with-custom-supply-chain
url: http://app-with-custom-supply-chain.{{ session_namespace }}.{{ ENV_TAP_INGRESS }}
```

That's it! You have built your first custom supply chain, and hopefully, many more will follow.
Let's delete the resources that we applied to the cluster.
```terminal:execute
command: |
  kubectl delete -f workload-custom-sc.yaml
  kapp delete -a custom-supply-chain -y
clear: true
```