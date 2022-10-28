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










The easiest way to get started with building a custom supply chain is to copy one of the out-of-the-box supply chains from the cluster, change the `metadata.name`, and add a unique selector by e.g. adding a label to the `spec.selector` configuration.

For this exercise, we will build one from scratch and discover the three ways of providing an implementation for a template:
- Using a Kubernetes custom resource that is already available for the functionality we are looking for
- Leverage a Kubernetes native CI/CD solution like Tekton to do the job, which is part of TAP
- For more **complex and asynchronous functionalities**, we have to **implement our own [Kubernetes Controller](https://kubernetes.io/docs/concepts/architecture/controller/)**.

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

As with our simple supply chain, the **second step** is responsible for the building of a container image out of the provided source code by the first step. 

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
    #TODO: healthRule
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
        resource: source-provider
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
      #TODO: healthRule
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
        resource: source-provider
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
        #TODO: healthRule

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

In our last step, we just want to deploy the built container using ClusterTemplate. The easiest way is to use a [Knative Serving Service](https://knative.dev/docs/serving/services/creating-services/) as an implementation because it creates everything it needs to also make our application accessible to the outer world. 

```editor:append-lines-to-file
file: custom-supply-chain/deployment-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterTemplate
  metadata:
    name: custom-deployment-template-{{ session_namespace }}
  spec:
    #TODO: healthRule
```

We already learned that a Knative Serving Service has immutable creator/lastModifer annotations and if Cartographer (or kapp-controller) applies updates to resources, it "removes" them which, results in a request denial by the admission webhook. However, we can work around this by using a kapp-controller App resource and that additional ConfigMap you can copy from the simple supply chain.
You can also add the Knative Serving Service specification in the `spec.fetch.inline` configuration instead of fetching them e.g. via http or from a Git repository.

Don't forget to add the created ClusterTemplate as a resource with the required input to the ClusterSupplyChain.

*Hint: You could also stamp out a Deployment, Service and Ingress resources instead of a Knative Serving Service directly in a ClusterTemplate because they don't have immutable fields. But you have to keep the limitation in mind that only the first resource specified in `spec.template` or `spec.ytt` will be stamped out by a Template. Therefore, you would have to define a ClusterTemplate for each and add them to the ClusterSupplyChain.*

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
      apiVersion: kappctrl.k14s.io/v1alpha1
      kind: App
      metadata:
        name: $(workload.metadata.name)$
      spec:
        #TODO: healthRule
        serviceAccountName: default
        fetch:
        - inline:
            paths:
              deployment.yml: |
                apiVersion: serving.knative.dev/v1
                kind: Service
                metadata:
                  name: $(workload.metadata.name)$
                  annotations:
                    serving.knative.dev/creator: system:serviceaccount:{{ session_namespace }}
                spec:
                  template: 
                    spec:
                      containers:
                      - image: $(image)$
                        name: workload
                        ports:
                        - containerPort: 5000
                ---
                apiVersion: kapp.k14s.io/v1alpha1
                kind: Config
                rebaseRules:
                  - path: [metadata, annotations, serving.knative.dev/creator]
                    type: copy
                    sources: [new, existing]
                    resourceMatchers: &matchers
                      - apiVersionKindMatcher: {apiVersion: serving.knative.dev/v1, kind: Service}
                  - path: [metadata, annotations, serving.knative.dev/lastModifier]
                    type: copy
                    sources: [new, existing]
                    resourceMatchers: *matchers
        template:
        - ytt: {}
        deploy:
        - kapp: {}
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
      app.kubernetes.io/part-of: simple-python-app
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
url: http://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/{{ session_namespace }}/simple-python-app
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

That's it! You have built your first custom supply chain, and hopefully, many more will follow.
Let's delete the resources that we applied to the cluster.
```terminal:execute
command: |
  kubectl delete -f workload-custom-sc.yaml
  kapp delete -a custom-supply-chain -y
clear: true
```