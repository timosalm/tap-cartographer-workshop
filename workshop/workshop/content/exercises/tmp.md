
##### Convention Service

**Note: The supply chain run has to be completed for the following commands**

Convention Service provides a means for people in operational roles to express their hard-won **knowledge and opinions about how applications should run on Kubernetes** as a convention. 

You can **define conventions** to target workloads by **using properties of their OCI metadata**.
Conventions can use this information to only apply changes to the configuration of workloads when they match specific criteria (for example, Spring Boot or .Net apps, or Spring Boot v2.3+). Targeted conventions can ensure uniformity across specific workload types deployed on the cluster.

Conventions **can also be defined** to apply to workloads **without targeting build service metadata**. Examples of possible uses of this type of convention include appending a logging/metrics sidecar, adding environment variables, or adding cached volumes. Such conventions are a great way for you to ensure infrastructure uniformity across workloads deployed on the cluster while reducing developer toil.
The conditional criteria governing the application of a convention is customizable and can be based on the evaluation of a custom Kubernetes resource called **PodIntent**. PodIntent is the vehicle by which Convention Service as a whole delivers its value.
```terminal:execute
command: kubectl get PodIntent
clear: true
```

With the current version on TAP, the following **out of the box conventions** are available with more to come in future versions.
```terminal:execute
command: kubectl get ClusterPodConvention
clear: true
```
- **Developer conventions** is a set of conventions that enable workloads to support live-update and debug operations
- **Spring Boot conventions** are smaller conventions applied to any Spring Boot application submitted to the supply chain. Most them either modify or add properties to the environment variable `JAVA_TOOL_OPTIONS` like for example to configure **graceful shutdown** and the **default port to 8080**,  
