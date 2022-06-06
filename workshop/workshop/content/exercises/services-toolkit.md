**Persona: Operators, Developers**

VMware Tanzu Application Platform makes it easy to **discover, curate, consume, and manage backing services**, such as databases, queues, and caches, across single or multi-cluster environments. 

This experience is made possible via the **Services Toolkit** component. 

Within the context of Tanzu Application Platform, one of the most important use cases is binding an application workload to a backing service such as a PostgreSQL database or a RabbitMQ queue.
This use case is made possible by the [Service Binding Specification](https://github.com/k8s-service-bindings/spec) for Kubernetes. 

For our use-case, we are using a **MongoDB Atlas cluster** for which the **operator made the credentials togehter with the hostname available** in our Kubernetes namespace to be able to bind applications to.

Developers are able to discover the services they are able to consume via the tanzu CLI ...
```terminal:execute
command: tanzu service claim list -o wide
clear: true
```
... and configure the binding to them with the provided information in the Workload.
```editor:open-file
file: tmf-product-catalog-management-api-java/config/workload.yaml
```

With this configuration the required credentials for the connection to the MongoDB Atlas cluster are then **automatically mounted to the application containers as a volume** and frameworks like Spring Boot are able to automatically pick them up an configure the application.

In addition to using a Kubernetes Secret resources to provide credentials to enable developers to connect their applications to almost any backing service, including backing services that are running external to the platform, the Services Toolkit also provied the functionailty to **bind to data services running in the same or another Kubernetes cluster** that adhere to the **Provisioned Service** specifications.


