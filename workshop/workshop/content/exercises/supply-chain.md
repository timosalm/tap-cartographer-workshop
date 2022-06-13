Cartographer uses the **ClusterSupplyChain** custom resource to link the different Cartographer objects. 

App operators can describe which "shape of applications" they deal with (via e.g. `spec.selector`) and what series of resources are responsible for creating an artifact that delivers it (via `spec.resources`).

```terminal:execute
command: mkdir simple-supply-chain
```

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

###### Templates

We will now start to implement the first of our series of resources that are responsible for bringing the application to a deliverable state.
Those resources are specified via **Templates**. Each template acts as a wrapper for existing Kubernetes resources and allows them to be used with Cartographer. This way, **Cartographer doesn’t care what tools are used under the hood**.
There are currently four different types of templates that can be use in a Cartographer supply chain: **ClusterSourceTemplate**, **ClusterImageTemplate**, **ClusterConfigTemplate**, and the generic **ClusterTemplate**.