**Persona: Developers**

After the test automation, the rest of the path to production has to automated and configured. 

With TAP, by design, **a path to production can be reused by many applications**. 
![](../images/cartographer.png)
This allows an operator to specify the steps in the path to production a single time, and for developers to specify their applications independently but for each to use the same path to production. The intent is that developers are able to focus on providing value for their users and can reach production quickly and easily, while providing peace of mind for app operators, who are ensured that each application has passed through the steps of the path to production that they’ve defined.

To set configurations like the location of the source code repository, environment variables and service claims for an application, there is an abstraction for developers called **Workloads**. 

Let's have a look at the ready to use Workload configuration provided by the Accelerator.
```editor:open-file
file: tmf-product-catalog-management-api-java/config/workload.yaml
```
As you can see we use our Git repository with the application sourcecode as a source. With that we can configure a **continous path to production** where every git commit to the codebase will trigger another execution of the supply chain and developers have to apply a Workload only once if they start with a new application or microservice. It's also supported via the tanzu CLI to use source code from the filesystem instead of a Git repository and deploy a container image from e.g. an ISV. 

As already mentioned a path to production can be reused by many applications. For our use-case the right **path to production will be chosen by the labels** for the application type, whether our source code contains tests and whether the API conformance has to be checked. It's also possible to configure the selector for a path to production based on other configurations available in the Workload.

The `app.kubernetes.io/part-of` label is relevant for another component of TAP, the TAP GUI.

Last but not least, there is the configuration of a `serviceClaim` which enables automated binding of data services and their credentials to an application running as container in a Kubernetes cluster - in this case a MongoDB Atlas cluster.

Development teams are then able to initiate their continous path to production with the tanzu CLI.
```terminal:execute
command: tanzu apps workload create -f config/workload.yaml -y
clear: true
```

It's also possible to provide all the configuration we saw in the workload.yaml via CLI flags, e.g. to try something out.
```execute
tanzu apps workload create --help
```

Tanzu CLI's app plugin also provides the functionality to stream logs for a Workload from all the pods that are involved in the deplyoment process to the running application.
```execute-2
tanzu apps workload tail product-catalog-management-api-java --since 1h
```

The developers can now focus on providing business value by implementing new functionitly and don't have to care where and how their application runs. 

Let's now have a closer look at the path to production from an operator and security perspective.
