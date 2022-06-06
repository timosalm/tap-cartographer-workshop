**Persona: Developers**

The Tanzu Developer Tools IDE extension enables developers to rapidly iterate on their applications on a production like environment - which is easy to provide with TAP.

This extension enables developers to:
- Generate snippets to quickly create TAP configuration files
- Live update workloads directly onto TAP-enabled Kubernetes cluster
- Debug workloads directly on TAP-enabled Kubernetes clusters

Let's first set the workspace to our application's source code.
```editor:execute-command
command: workbench.action.files.openFolder
```
Copy/paste the following path to the command prompt.
```copy
/home/eduk8s/tmf-product-catalog-management-api-java/
```

**Code snippets** enable you to quickly add three files necessary to develop against TAP to existing projects by creating a template in an empty file which you fill out with the required information. 
Those three files are the following:
- The `workload.yaml` file provides instructions to the Supply Chain Choreographer for how a workload must be built and managed.
- The `catalog-info.yaml` file enables the workloads created with the Tanzu Developer Tools extension to be visible in the TAP GUI.
- The `Tiltfile` provides the configuration for Tilt to enable your project to live update on the Tanzu Application Platform.

In our project the first two are already included and configured. To show the code snippet functionality the `Tiltfile` is not part of the App Accelerator and we will generate it now!
```editor:append-lines-to-file
file: ~/tmf-product-catalog-management-api-java/Tiltfile
text: ""
```


**Enter** `tanzu tiltfile` **in the created file with your keybaord** to triggered the Code snippets functionality. Then we can replace the placeholders with our configuration.
```terminal:execute
command: sed -i 's/path-to-workload-yaml/config\/workload.yaml/' ~/tmf-product-catalog-management-api-java/Tiltfile
clear: true
```
```terminal:execute
command: sed -i 's/workload-name/product-catalog-management-api-java/' ~/tmf-product-catalog-management-api-java/Tiltfile
clear: true
```
We also have to add one instruction to allow to deploy our application to the cluster which is detected as "production" cluster. 
```editor:append-lines-to-file
file: ~/tmf-product-catalog-management-api-java/Tiltfile
text: allow_k8s_contexts('eduk8s')
```

The `Tiltfile` is the configuration file for [Tilt](https://tilt.dev) which is behind the scence used for the **live update functionality**.
If you've never used Tilt before, this script may seem like a lot. We can right click on the Tiltfile in the code editor, and select `Tanzu: Live Update Start` in the pop-up menu. **Or**, we can click on the command below to accomplish the same thing.

```editor:execute-command
command: tanzu.liveUpdateStart
```

The Tiltfile script is going to deploy our application into our development environment, and it will take about 2.5 minutes to run to completion the first time. But don't worry! It is setting us up to run iterative deployments that will be much, much faster.

This code change will automatically trigger a patch to the running container. 
```editor:select-matching-text
file: ~/tmf-product-catalog-management-api-java/src/main/java/org/openapitools/OpenAPI2SpringBoot.java
text: "TMF Product Catalog Management API"
```

```editor:replace-text-selection
file: ~/tmf-product-catalog-management-api-java/src/main/java/org/openapitools/OpenAPI2SpringBoot.java
text: "TMF Product Catalog Management API of the UK market"
```

In under 10 seconds, we'll see the application restart in the terminal window. Go to the browser tab where our application is running, and refresh it. We'll see the code changes applied.
```dashboard:open-url
url: https://product-catalog-management-api-java-{{ session_namespace }}.cnr.{{ ENV_TAP_INGRESS }}
```

Let's now stop our live update functionality and have a look at debugging.
```editor:execute-command
command: tanzu.liveUpdateStop
```

To start **debugging** on the cluster:
1. Add a breakpoint in our code to the selected file

```editor:select-matching-text
file: ~/tmf-product-catalog-management-api-java/src/main/java/com/vodafone/CatalogApi.java
text: "a315c1d2-c726-4786-94a0-f267d60d91f5"
before: 0
after: 0
```
2. Right-click the config/workload.yaml file in our project.
3. Select Tanzu: Java Debug Start in the right-click menu.
4. Open the application in the browser and execute a request for the "list catalogs" API.
```dashboard:open-url
url: https://product-catalog-management-api-java-{{ session_namespace }}.cnr.{{ ENV_TAP_INGRESS }}
```
5. Jump back to your workshop to use the debug functionality.