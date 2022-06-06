**Persona: Operators**

To be able to get all the benefits for our application Kubernetes provides, we have to containerize it.

The most obvious way to do this, is to write a Dockerfile, run `docker build` and push it to the container registry of our choice via `docker push`.

![](../images/dockerfile.png)

As you can see, in general it is relatively easy and requires little effort to containerize an application, but whether you should go into production with it, is another question, because it is hard to create an optimized and secure container image (or Dockerfile).

To improve the Docker image generation, **Buildpacks** were conceived by Heroku in 2011. Since then, they have been adopted by Cloud Foundry and other PaaS.
And the new generation of buildpacks, the [Cloud Native Buildpacks](https://buildpacks.io), is an incubating project in the CNCF which was initiated by Pivotal and Heroku in 2018.

Cloud Native Buildpacks (CNBs) detect what is needed to compile and run an application based on the application's source code. 
The application is then compiled by the appropriate buildpack and a container image with best practices in mind is build with the runtime environment.

The biggest benefits of CNBs are increased security, minimized risk, and increased developer productivity because they don't need to care much about the details of how to build a container.

With all the benefits of Cloud Native Buildpacks, one of the **biggest challenges with container images still is to keep the operating system, used libraries, etc. up-to-date** in order to minimize attack vectors by CVEs.

With **VMware Tanzu Build Service (TBS)**, which is part of TAP, it's possible **automatically recreate and push an updated container image to the target registry, if there is a new version of the buildpack or the base operating system available** (e.g. due to a CVE), a new container is automatically created and pushed to the target registry.
With our Supply Chain, it's then possible to deploy security patches automatically.
This fully automated update functionality of the base container stack is a big competitive advantage compared to other tools.