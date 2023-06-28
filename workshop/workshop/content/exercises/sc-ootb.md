VMware Tanzu Application provides a **full integration of all of its components via out-of-the-box Supply Chains** that can be customized for customers' processes and tools.

TAP provides three out-of-the-box (OOTB) supply chains that can be customized for your processes and tools.

##### OOTB Supply Chain Basic
![OOTB Supply Chain Basic](../images/sc-basic.png)
Capabilities of this supply chain: 
- Monitors a repository that is identified in the developer’s Workload configuration
- Creates a new container image out of the source code
- Generates the Kubernetes resources for the deployment of the application as YAML and applies predefined conventions to them
- Deploys the application to the cluster

##### OOTB Supply Chain with Testing
![OOTB Supply Chain with Testing](../images/sc-testing.png)
Additional capabilities of this supply chain: 
- Runs application tests using a Tekton or Jenkins pipeline

##### OOTB Supply Chain with Testing and Scanning
![OOTB Supply Chain with Testing+Scanning](../images/sc-testing-scanning.png)
Additional capabilities of this supply chain: 
- The application source code is scanned for vulnerabilities
- The container image is scanned for vulnerabilities

All of the OOTB supply chains also support a prebuilt application container image as an input instead of source code. In this case, only the steps after the container image creation will be executed (e.g. image scanning, Kubernetes resources YAML generation, Deployment).

As the OOTB Supply Chain with Testing and Scanning provides the most capabilities, we'll now have a closer look at the implementation and the different tools that provide all of them.

```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/host/{{ session_namespace }}/ootb-sc-demo
```

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
