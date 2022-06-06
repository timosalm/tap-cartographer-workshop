Cartographer uses the **ClusterSupplyChain** object to link the different Cartographer objects. App operators describe which "shape of applications" they deal with (via **spec.selector**) and what series of resources are responsible for creating an artifact that delivers it (via **spec.resources**).

Those resources are specified via **Templates**. Each template acts as a wrapper for existing Kubernetes resources and allows them to be used with Cartographer. This way, **Cartographer doesn’t care what tools are used under the hood**.

Let’s take a closer look at each Cartographer object and see how they wrap the individual components inside of it.
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/template/
```
- **ClusterSourceTemplate** indicates how the supply chain could instantiate an object responsible for providing source code. All ClusterSourceTemplate cares about is whether the **urlPath** and **revisionPath** are passed in correctly from the template. 
- **ClusterImageTemplate** instructs how the supply chain should instantiate an object responsible for supplying container images. The outputof the underlying tool has to be passed into the cartographer's Object **imagePath**.
- **ClusterConfigTemplate** instructs the supply chain how to instantiate a Kubernetes object that knows how to make Kubernetes configurations available to further resources in the chain.
- **ClusterDeploymentTemplate** indicates how the delivery should configure the environment
- **ClusterTemplate** instructs the supply chain to instantiate a Kubernetes object that has no outputs to be supplied to other objects in the chain. It can for example be used to create any Kubernetes/Knative object, such as deployment, services, Knative services, etc.
- A **ClusterRunTemplate** differs from supply chain templates in many aspects (e.g. cannot be referenced directly by a ClusterSupplyChain, **outputs** provide a free-form way of exposing any form of results). It defines how an immutable object should be stamped out based on data provided by a **Runnable**.
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/runnable/
```
