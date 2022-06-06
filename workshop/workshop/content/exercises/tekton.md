**Persona: Developers**

Because we all make mistakes, testing the implementation of the application is important. 
To reduce the effort for testing our application on every change, it's recommended to automate the test execution.

Developers know best how to run their for example unit and UI tests. 
This is why **TAP provides the flexibility to**
- make development teams responsible for the creation of the test automation for their applications 
- implement the test automation for the tools and frameworks used in an organization by DevOps teams or operators

TAP includes **Tekton** for the implementation of the test automation or other Continous Integration(CI) tasks that are not handleded by other components. Tekton is a cloud-native, open-source solution for building CI/CD systems. 
Due to the fact that we as most of the other organizations already have other CI/CD tools like Azure DepOps or Jenkins, VMware is working on addining first-class support for the most popular ones. As long as the first-class support for our tools is not yet available, it's technically possible to integrate them with some effort / the help of VMware consultants.

**For our use-case each development team is responsible for the creation of the test automation of their application** which gives them the flexibility to use the frameworks and tools they prefer. A starting point for this test automation can be also provided as part of the Accelerator - like in our example.

This basic Tekton Pipline just executes our unit tests via `mvn test`.
```editor:open-file
file: tmf-product-catalog-management-api-java/config/test-pipeline.yaml
```

Let's now create the Tekton Pipline resource in a Kubernetes namespace, the development team has access to.
```terminal:execute
command: kubectl apply -f config/test-pipeline.yaml
clear: true
```
VMware is also working on a solution to automatically apply those Tekton Pipelines available in the same repository as the source code.