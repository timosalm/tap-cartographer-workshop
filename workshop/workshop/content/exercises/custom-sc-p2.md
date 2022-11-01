Working Custom Supply Chain (GG,DK) Start
```section:begin
title: Working Custom Supply Chain (GG,DK)
```
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2
apiVersion: carto.run/v1alpha1
kind: ClusterSupplyChain
metadata:
  labels:
    abc.com/is-custom: "true"
    apps.tanzu.vmware.com/workload-type: web
    end2end.link/workshop-session: {{ session_namespace }}
  name: simple-supplychain-{{ session_namespace }}
spec:
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
  resources:
  
  - name: source-provider
    params:
    - name: serviceAccount
      value: default
    - name: gitImplementation
      value: go-git
    templateRef:
      kind: ClusterSourceTemplate
      name: source-template
  
  - name: deliverable
    params:
    - name: registry
      value:
        ca_cert_data: ""
        repository: tap-workshop-workloads
        server: harbor.services.demo.jg-aws.com
    templateRef:
      kind: ClusterTemplate
      name: deliverable-template
  
  - name: source-tester
    sources:
    - name: source
      resource: source-provider
    templateRef:
      kind: ClusterSourceTemplate
      name: testing-pipeline
  
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
      name: source-scanner-template
  
  - name: image-builder
    params:
    - name: serviceAccount
      value: default
    - name: registry
      value:
        ca_cert_data: ""
        repository: tap-workshop-workloads
        server: harbor.services.demo.jg-aws.com
    - default: default
      name: clusterBuilder
    - default: ./Dockerfile
      name: dockerfile
    - default: ./
      name: docker_build_context
    - default: []
      name: docker_build_extra_args
    sources:
    - name: source
      resource: source-scanner
    templateRef:
      kind: ClusterImageTemplate
      options:
      - name: kpack-template
        selector:
          matchFields:
          - key: spec.params[?(@.name=="dockerfile")]
            operator: DoesNotExist
      - name: kaniko-template
        selector:
          matchFields:
          - key: spec.params[?(@.name=="dockerfile")]
            operator: Exists
  
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
      name: image-scanner-template
  
  - images:
    - name: image
      resource: image-scanner
    name: config-provider
    params:
    - name: serviceAccount
      value: default
    templateRef:
      kind: ClusterConfigTemplate
      name: convention-template
  
  - configs:
    - name: config
      resource: config-provider
    name: app-config
    templateRef:
      kind: ClusterConfigTemplate
      name: config-template
  
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
      name: config-writer-template
  
  selector:
    # apps.tanzu.vmware.com/has-tests: "true"
    abc.com/is-custom: "true"
    apps.tanzu.vmware.com/workload-type: web
    end2end.link/workshop-session: {{ session_namespace }}
```
```section:end
```
Working Custom Supply Chain (GG,DK) End






**TODO: Labels for ScanPolicy needs to be there `app.kubernetes.io/part-of: scan-system`** 







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
file: custom-supply-chain/source-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: custom-source-template-{{ session_namespace }}
  spec:
    urlPath: ""
    revisionPath: ""
    ytt: ""
```
In TAP 1.2 we have the ability to detect the **Health Status** of the Supply Chain component. To accomplish that, we need to add `healthRule` spec to the respective component. We will be  adding for the rest of the components.
This is possible via the `spec.healthRule`. The documentation is available here:
```dashboard:open-url
url: https://cartographer.sh/docs/v0.5.0/health-rules/
```
```editor:append-lines-to-file
file: custom-supply-chain/source-template.yaml
text: |2
    healthRule:
      singleConditionType: Ready
```

We will continue `ClusterSourceTemplate` in this below section. Click below tile to expand it first.
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
      params:
      - name: serviceAccount
        value: default
      - name: gitImplementation
        value: go-git
      templateRef:
        kind: ClusterSourceTemplate
        name: source-template
```

```editor:select-matching-text
file: custom-supply-chain/source-template.yaml
text: "  ytt: \"\""
```
```editor:replace-text-selection
file: custom-supply-chain/source-template.yaml
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

Since we want to enforce the source testing, we need to consider creating another `ClusterSourceTemplate` and name it as `source-tester`. 
Lets add the reference of this `ClusterSourceTemplate` to our supply chain before and then we will create the template.

```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |2
    - name: source-tester
      sources:
      - name: source
        resource: source-provider
      templateRef:
        kind: ClusterSourceTemplate
        name: custom-source-template-testing-pipeline-{{ session_namespace }}
```
Create a template now:
```editor:append-lines-to-file
file: custom-supply-chain/testing-pipeline-source-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: custom-source-template-testing-pipeline-{{ session_namespace }}
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


We also have a requirement to scan our source code for CVEs. Let's add those pieces together to get it done. Once again we will use the OOTB provided source scanning template named `source-scanner-template` of kind `ClusterSourceTemplate` that was deployed with `source-test-scan-to-url` OOTB supply chain.
Lets understand what this section is. We are using a scan policy (`ScanPolicy`) named `scan-policy` and the scanning template (`ScanTemplate`) named `blob-source-scan-template` via `scanning.apps.tanzu.vmware.com/v1beta1` that was already deployed on this workshop & the TAP cluster by OOTB supply chain. We can change the policies and templates with our custom ones. We will explain this more during the image scanning section when we add it to the supply chain.
 
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
        name: source-scanner-template
```

As with our custom supply chain, the **next step** is responsible for the building of a container image out of the provided source code by the first step. 

In addition to `kpack`, with our custom supply chain we want to provide a solution that builds a container image based on a **Dockerfile**. 

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
        name: kpack-template
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
```dashboard:open-url
url: https://cartographer.sh/docs/v0.5.0/reference/workload/#clustersupplychain
```

Due to the complexity, here is the **ClusterRunTemplate which you have to reference from a Runnable** that you have to define with its inputs **in the ClusterImageTemplate**. 

You can for sure also try to implement it yourself but please with the name **"custom-kaniko-run-template-{{ session_namespace }}"**.
```editor:append-lines-to-file
file: custom-supply-chain/kaniko-run-template.yaml
text: |2
    apiVersion: carto.run/v1alpha1
    kind: ClusterRunTemplate
    metadata:
      name: custom-kaniko-run-template-{{ session_namespace }}
    spec:
      healthRule:
        singleConditionType: Ready
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
file: custom-supply-chain/image-template.yaml
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
file: custom-supply-chain/image-template.yaml
text: "  imagePath: \"\""
```
```editor:replace-text-selection
file: custom-supply-chain/image-template.yaml
text: |2
    imagePath: .status.outputs.latest-image
```

```section:end
```


We are now able to apply our custom supply chain to the cluster.
```terminal:execute
command: kapp deploy -a custom-supply-chain -f custom-supply-chain -y --dangerous-scope-to-fallback-allowed-namespaces
clear: true
```
To test it we last but not least have to create a **matching Workload**, ...
```editor:append-lines-to-file
file: workload-custom-sc.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: Workload
  metadata:
    labels:
      app.kubernetes.io/part-of: app-with-custom-supply-chain
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
          branch: main
        url: https://github.com/dkhopade/tanzu-java-web-app.git
```
... apply it, ...
```terminal:execute
command: |
  kubectl apply -f workload-custom-sc.yaml
clear: true
```
... and then we are able to see via the commercial Supply Chain Choreographer UI plugin and the following commands whether everything works as expected.

```dashboard:open-url
url: http://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/{{ session_namespace }}/app-with-custom-supply-chain
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
command: kubectl describe workload app-with-custom-supply-chain
clear: true
```
```execute-2
tanzu apps workload tail app-with-custom-supply-chain
```

That's it! You have built your first custom supply chain, and hopefully, many more will follow.
Let's delete the resources that we applied to the cluster.
```terminal:execute
command: |
  kubectl delete -f workload-custom-sc.yaml
  kapp delete -a custom-supply-chain -y
clear: true
```