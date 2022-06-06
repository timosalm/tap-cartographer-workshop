**Persona: Operators**

TAP uses **Supply Chain Choreographer** which is based on the open source **Cartographer** to **allow App Operators create pre-approved paths to production** by integrating Kubernetes resources with the elements of our existing toolchains.

```dashboard:open-url
url: https://cartographer.sh
```

Each pre-approved supply chain creates a paved road to production. Orchestrating supply chain resources - test, build, scan, and deploy - allows developers to focus on delivering value to their users and provides App Operators the assurance that all code in production has passed through all the steps of an approved workflow.

##### Design and Philosophy

Cartographer allows operators via the **Supply Chain** abstraction to define all of the steps that an application must go through to create an image and Kubernetes configuration. 

The supply chain consists of resources that are specified via **Templates**. Each template acts as a wrapper for existing Kubernetes resources and allows them to be used with Cartographer. 

**Contrary to many other Kubernetes native workflow tools** that already exist in the market, **Cartographer does not “run” any of the objects themselves**. Instead, it monitors the execution of each resource and templates the following resource in the supply chain after a given resource has completed execution and updated its status.

In the **orchestration** model, which is used by most of the current CI/CD tools like Jenkins or Tekton, an **orchestrator** executes, monitor, and manage each of the steps of the path to production. The CI stage, or any others, could not function independently from the orchestrator. In the case of a path to production with a vulnerability scanning step, if a new CVE should arise, the only way to scan the code for it would be to trigger the orchestrator to initiate the scanning step or a new run through the supply chain.
![](../images/orchestrator.png)

In the **choreography** model, each step of the path to production and the tool required for that step knows nothing about the next step. It is responsible for receiving a signal that it must perform some work, completing it, and signaling that it has finished. In the same case as above, with a pipeline that has a vulnerability scanner, if there was a new CVE, the vulnerability scanner would know about it and trigger a new scan. When the scan is complete, the vulnerability scanner would send a message indicating that scanning is complete.
![](../images/choreographer.png)
Because steps of the path to production are rarely synchronous, for example, if a new CVE comes up, someone clicks the button on a build, and so on, choreography is a natural choice as a workflow engine. Flexibility and the ability to swap steps of the path to production is also of extreme importance.

The supply chain may also be **extended to include integrations to existing CI/CD pipelines** like for our test automation Tekton Pipeline.

VMware Tanzu Application provides a **full integration of all of its components via out of the box Supply Chains** that can be customized for our processes and tools.

Let's now have a closer look at the path to production for our use-case for which we added one custom step to the ones that are out-of-the-box available with TAP.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/{{ session_namespace }}/product-catalog-management-api-java
```
