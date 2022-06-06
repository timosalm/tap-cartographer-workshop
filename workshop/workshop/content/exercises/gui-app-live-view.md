**Persona: Developers**

Sometimes an application isn't behaving quite like we'd expect after deployment, and we want to get more information about its runtime behavior, for diagnostics and troubleshooting. Is our application running out of memory? What was the response time for HTTP Requests?

**Application Live View** shows an individual running process, for example, a Spring Boot application deployed as a workload resulting in a JVM process running inside of a Pod. This is an important concept of Application Live View: **only running processes are recognized** by Application Live View. If there is not a running process inside of a running Pod, Application Live View does not show anything.
Therefore and due to the scale-to-zero capabilities of TAP, it could be that there is currently no Pod running. Let's change this by opening our application in the browser.

```dashboard:open-url
url: https://product-catalog-management-api-java-{{ session_namespace }}.cnr.{{ ENV_TAP_INGRESS }}
```

Under the hood, Application Live View uses the concept of **Spring Boot Actuators** to gather data from those running processes. Application Live View **does not store any of that data** for further analysis or historical views. 

In addition to Spring and .NET Steeltoe applications, VMWare is working on supporting this functionlity for all commonly used programming languages and frameworks.

The Application Live View is **available for a desired Pod from the Pods section under Runtime Resources tab**.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/component/tmf-product-catalog-management-api-service/workloads
``` 

