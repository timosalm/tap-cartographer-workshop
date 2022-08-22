VMware Tanzu Application provides a **full integration of all of its components via out-of-the-box Supply Chains** that can be customized for customers' processes and tools.

The following three out-of-the-box supply chains are provided with Tanzu Application Platform:

- Out of the Box Supply Chain Basic
- Out of the Box Supply Chain with Testing
- Out of the Box Supply Chain with Testing and Scanning

All of them come with support for pre-built container images.

As auxiliary components, VMware Tanzu Application Platform also includes:
- **Out of the Box Templates**, for providing templates used by the supply chains to perform common tasks like fetching source code, running tests, and building container images.
- **Out of the Box Delivery Basic**, for delivering to a Kubernetes cluster the configuration built throughout a supply chain.
Both Templates and Delivery Basic are requirements for the Supply Chains.

Let's now have a closer look at the **Out of the Box Supply Chain with Testing and Scanning**.

```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/ootb-sc-demo
```

For workloads that use source code or prebuilt images, it performs the following.
**Building from source code:**
1. Watching a Git Repository or local directory for changes
2. Running tests from a developer-provided Tekton pipeline
3. Scanning the source code for known vulnerabilities using Grype
4. Building a container image out of the source code with Buildpacks
5. Scanning the image for known vulnerabilities
6. Applying operator-defined conventions to the container definition
7. Deploying the application to the same cluster

**Using a prebuilt application image**
1. Scanning the image for known vulnerabilities
2. Applying operator-defined conventions to the container definition
3. Creating a deliverable object for deploying the application to a cluster

With the following command, we are able to extract it from the cluster and can have a closer look via VSCode, how they are implemented.
```terminal:execute
command: |
 mkdir ootb-sc-testing-scanning
 kubectl eksporter "clusterconfigtemplate,clusterimagetemplates,clusterruntemplates,clustersourcetemplates,clustersupplychains,clustertemplates,clusterdelivery,ClusterDeploymentTemplate,deliverable" | kubectl slice -o ootb-sc-testing-scanning/ -f-
 find ootb-sc-testing-scanning/ -type f -name '*custom*' -delete
 find ootb-sc-testing-scanning/ -type f -name '*simple*' -delete
 find ootb-sc-testing-scanning/ -type f -name '*api*' -delete
clear: true
```

```editor:open-file
file: ootb-sc-testing-scanning/clustersupplychain-source-test-scan-to-url.yaml
line: 1
```
