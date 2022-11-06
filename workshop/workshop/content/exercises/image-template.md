#### Cluster Image Template
The details of ClusterImageTemplate specifications can be found here: 
```dashboard:reload-dashboard
name: Cartographer Docs
url: https://cartographer.sh/docs/v0.5.0/reference/template/#clusterimagetemplate
```
A **ClusterImageTemplate** instructs how the supply chain should instantiate an object responsible for supplying container images.

Sounds like a perfect match for our second step in the path to production - the building of a container image out of the provided source code by the first step. 
We can consume the outputs of our ClusterSourceTemplate resource in the ClusterImageTemplate by referencing it via the `spec.resources[*].sources` field of our Supply Chain definition. 
```editor:append-lines-to-file
file: simple-supply-chain/supply-chain.yaml
text: |2
    - name: image-builder
      templateRef:
        kind: ClusterImageTemplate
        name: simple-image-kpack-template-{{ session_namespace }}
      sources:
      - name: source
        resource: source-provider
      params:
      - name: registry
        value:
          server: harbor.services.demo.jg-aws.com
          repository: tap-workshop-workloads
```
In addition, we also define parameters for the resource with the configuration of a registry server and repository to which we want to push our container images. As we are setting them with `params[*].value` instead of `params[*].default`, they are not overridable by the global ClusterSupplyChain resource's and the Workload params. 

With all the data we need, we can configure our ClusterImageTemplate resource.
```editor:append-lines-to-file
file: simple-supply-chain/simple-image-kpack-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterImageTemplate
  metadata:
    name: simple-image-kpack-template-{{ session_namespace }}
  spec:
    healthRule:
      singleConditionType: Ready
    params:
      - name: registry
        default: {}
    imagePath: ""
    ytt: ""
```
The ClusterImageTemplate requires the definition of a `spec.imagePath` with the value of a valid image digest that has to be provided in the output of the underlying tool used for container building.
As you can already see, we will use the second option for templating now - ytt.

As a Kubernetes native tool for container building, we will use **VMware Tanzu Build Service** that is based on the OSS **kpack**.
You can have a closer look at the various configuration options of the relevant **Image** custom resource the solution provides here:
```dashboard:reload-dashboard
name: Cartographer Docs
url: https://github.com/pivotal/kpack/blob/main/docs/image.md
```

Let's add it to our ClusterImageTemplate resource.
```editor:select-matching-text
file: simple-supply-chain/simple-image-kpack-template.yaml
text: "  imagePath: \"\""
after: 1
```
```editor:replace-text-selection
file: simple-supply-chain/simple-image-kpack-template.yaml
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
        labels:
          app.kubernetes.io/component: image
          app.kubernetes.io/part-of: #@ data.values.workload.metadata.name
      spec:
        tag: #@ image()
        source:
          blob:
            url: #@ data.values.source.url
        builder:
          kind: ClusterBuilder
          name: default

```
We are using a **ytt** function to construct the tag of the container image. We are also using the data values, the parameters, and the source input as defined in our **Workload**.

When an image resource has successfully built with its current configuration and pushed to the container registry, the custom report will report the up-to-date, fully qualified built OCI image reference in the `status.latestImage`, which we can use as the output of our Template specified in jsonpath.
