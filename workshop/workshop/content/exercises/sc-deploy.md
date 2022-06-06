**Persona: Operators**

##### GitOps

After we have containerized our application and pushed it to the container registry and scanned it for vulnerabilities, we are now able to get all the benefits Kubernetes provides for our application by deploying it to a cluster.

Kubernetes clusters and the applications running on them have a lot of moving parts and the state of your clusters may need to be updated frequently, potentially leading to configuration inconsistencies and hours of troubleshooting. These challenges are leading many DevOps teams to adopt **GitOps** to standardize Kubernetes cluster configuration and application deployment. GitOps is an operational model that applies the principles of Git and best practices from software development to infrastructure configuration. 

With the GitOps approach, Git is used to version and store the necessary infrastructure configuration files as the single source of truth for infrastructure running in development, staging, production, etc. 
**With TAP by default these configuration files will be automatically pulled by the Kubernetes clusters after the Supply Chain pushed it to a remote Git repository.** 
This allows users to compare configuration changes and promote those changes through environments by using GitOps principles.

As an alternative, TAP also provides **RegistryOps** which typically used for inner loop flows where configuration is treated as an artifact from quick iterations by developers. In this scenario, at the end of the supply chain, configuration is pushed to a container image registry in the form of an imgpkg bundle. You can think of it as a container image whose sole purpose is to carry arbitrary files.

##### Multi-cluster support
TAP **supports the installation of all its component on one cluster**.

For production deployments, **VMware recommends a multi-cluter installation** of two fully independent instances of Tanzu Application Platform. 
One instance for operators to conduct their own reliability tests, and the other instance hosts development, test, QA, and production environments for our different markets isolated by separate clusters.

The recommended multi-cluter installation of the following types of clusters:
- **Iterate Clusters** (1 or more for each market) for "inner loop" development iteration. Developers connect to the Iterate Cluster via their IDE to rapidly iterate on new software features. The Iterate Cluster operates distinctly from the outer loop infrastructure. Each developer should be given their own namespace within the Iterate Cluster during their platform onboarding.
- The **Build Cluster** (1 global or for each market) is responsible for taking a developer's source code commits and applying a supply chain that will produce a container image and Kubernetes manifests for deploying on a Run Cluster. The Kubernetes Build Cluster will see bursty workloads as each build or series of builds kicks off. The Build Cluster will see very high pod scheduling loads as these events happen. The amount of resources assigned to the Build Cluster will directly correlate to how quickly parallel builds are able to be completed.
- The **View Cluster** (1 global) is designed to run the developer portal (TAP GUI), Learning Center, and API Portal. One benefit of having them on a separate cluster for us is, that **developers are able to discover all the applications in the different markets**.
- Several **Run Clusters** for the different stages and markets that read the container image and Kubernetes resources created by the Build Cluster and runs them as defined for each application.

![](../images/reference-architecture.png)

##### Cloud Native Runtimes for VMware Tanzu

Cloud Native Runtimes for VMware Tanzu (CNRs) simplify deploying and operating microservices on Kubernetes. They are a set of capabilities that enable us to leverage the power of Kubernetes for **Serverless** use cases without first having to master the Kubernetes API.

###### Knative
CNRs includes **Knative**, an open source community project that provides a simple, consistent layer over Kubernetes that solves common problems of deploying software, connecting disparate systems together, upgrading software, observing software, routing traffic, and scaling automatically. This layer creates a firmer boundary between the developer and the platform, allowing the developer to concentrate on the software they are directly responsible for.

The major subprojects of Knative are *Serving* and *Eventing*.
- **Serving** is responsible for deploying, upgrading, routing, and scaling. 
- **Eventing** is responsible for connecting disparate systems. Dividing responsibilities this way allows each to be developed more independently and rapidly by the Knative community.

###### Functions runtime
With TAP 1.1 a public beta of a polyglot serverless function experience for Kubernetes was released. 
It leverages Knative and new Cloud Native Buildpacks and currently supports Java and Python HTTP functions. .NET and NodeJS support is planned.

###### Future runtimes
VMware is currently working on the following additional runtimes:
- **Streaming**: A polyglot runtime that can simplify the orchestration of diverse data processing architecture patterns. By reimagining the building blocks of Spring Cloud Data Flow with polyglot-friendly and Kubernetes-native principles, the Streaming runtime will bridge the gap between application development and data ‘organization silos’.
- **Batch:** Scheduled jobs to complete tasks.

##### Convention Service

**Note: The supply chain run has to be completed for the following commands**

Convention Service *provides a means for people in operational roles to express their hard-won **knowledge and opinions about how applications should run on Kubernetes** as a convention. 

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
