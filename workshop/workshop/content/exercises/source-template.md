A **ClusterSourceTemplate** indicates how the supply chain could instantiate an object responsible for providing source code. 
```editor:append-lines-to-file
file: simple-supply-chain/source-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterSourceTemplate
  metadata:
    name: simple-source-template-{{ session_namespace }}
  spec:
    healthRule:
      singleConditionType: Ready
    urlPath: ""
    revisionPath: ""
    ytt: ""
```
All ClusterSourceTemplate cares about is whether the `spec.urlPath` and `spec.revisionPath` are passed in correctly from the templated object that implements the actual functionality we want to use as part of our path to production.

For our continuous path to production where every git commit to the codebase will trigger another execution of the Supply Chain, we need a solution that watches our configured source code Git repository for changes or will be trigger via e.g. a Webhook and provides the sourcecode for the following steps/resources.

**In the best case** there is already a Kubernetes native solution with a **custom resource available for the functionality** we are looking for. **Otherwise, we can leverage a Kubernetes native CI/CD solution** like Tekton to do the job, which is part of TAP. For more **complex and asynchronous functionalities**, we have to **implement our own [Kubernetes Controller](https://kubernetes.io/docs/concepts/architecture/controller/)**.

In this case, the [Flux](https://fluxcd.io) Source Controller is part of TAP for this functionality, which is a Kubernetes operator that helps to acquire artifacts from external sources such as Git, Helm repositories, and S3 buckets. 
We can have a closer look at the custom resource the solution provides via the following command and then only have to configure it as a template in the ClusterSourceTemplate.
```terminal:execute
command: kubectl describe crds gitrepositories
clear: true
```

There are **two options for templating**:
- **Simple templates** can be defined in `spec.template` and provide string interpolation in a `\$(...)\$` tag with jsonpath syntax.
- **ytt** for complex logic, such as conditionals or looping over collections (defined via `spec.ytt` in Templates).

Both options for templating **provide a data structure** that contains:
- Owner resource (Workload, Deliverable)
- Inputs that are specified in the ClusterSupplyChain (or ClusterDelivery) for the template (sources, images, configs, deployments)
- Parameters

**Hint:** It's only supported to define a resource template for **one** Kubernetes (Custom) Resource. Additional resources will not be stamped out!

More information can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.5.0/templating/
```

For our first functionality, we will use a `ytt` and use the configuration provided by the Workload.
```editor:select-matching-text
file: simple-supply-chain/source-template.yaml
text: "  ytt: \"\""
```
```editor:replace-text-selection
file: simple-supply-chain/source-template.yaml
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
        labels: #@ merge_labels({ "app.kubernetes.io/component": "source", "app.kubernetes.io/part-of": #@ data.values.workload.metadata.name })
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

On every successful repository sync, the status of the custom GitRepository resource will be updated with an url to download an archive that contains the source code and the revision. We can use this information as the output of our Template specified in jsonpath.
```editor:select-matching-text
file: simple-supply-chain/source-template.yaml
text: "  urlPath: \"\""
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
text: "  resources: []"
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

With the `spec.resources[*].templateRef.options` field, it's also possible to define multiple templates of the same kind for one resource to change the implementation of a step based on a selector.

The detailed specifications of the ClusterSourceTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.5.0/reference/template/#clustersourcetemplate
```
