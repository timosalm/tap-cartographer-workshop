**Persona: Operators**

In the next step the provided **source code will be scanned** for known vulnerabilities using [Grype](https://github.com/anchore/grype). After the container image building, there is also a step for **image scanning** using Grype.

For source and image scans to happen, scan policies must exist in the same namespace as the Workload which can be done during the automated provisioning of new namespaces. It defines how to evaluate whether the artifacts scanned are compliant, for example allowing one to be either very strict, or restrictive about particular vulnerabilities found. 
If an artifacts is not compliant, the application will not be deployed.
```terminal:execute
command: kubectl eksporter scanpolicy
clear: true
```

**Note: "Source Scanner" and "Image Scanner" supply chain steps have to be completed for the following commands**

###### Viewing scan status

The functionality to see the scan results in the Supply Chain view will be probably available in TAP 1.2.
In the meantime it's possible to directly view the results via kubectl and the custom resources.
```terminal:execute
command: kubectl describe sourcescan product-catalog-management-api-java 
clear: true
```
```terminal:execute
command: kubectl describe imagescan product-catalog-management-api-java
clear: true
```

###### Storing the software bills of materials (SBoMs)
Both scanning stepts automatically store the resulting source code and image vulnerability reports to a database which allows us to query for image, source code, package, and vulnerability relationships via an API and the tanzu CLI's insight plugin. The so called **Metadata Store** accepts CycloneDX input and outputs in both human-readable and machine-readable formats, including JSON, text, and CycloneDX.

```terminal:execute
command: |
  IMAGE_DIGEST=$(kubectl get kservice product-catalog-management-api-java -o jsonpath='{.spec.template.spec.containers[0].image}' | awk -F @ '{ print $2 }')
  tanzu insight image vulnerabilities --digest $IMAGE_DIGEST
clear: true
```
VMware is also working on making this information available via a "security analyst" dashboard in the UI.

###### Container signing

TAP also provides optional container signing capabilites via an admission WebHook that:
- Verifies signatures on container images used by Kubernetes resources.
- Enforces policy by allowing or denying container images from running based on configuration.
- Adds metadata to verified resources according to their verification status.
- It intercepts all resources that create Pods as part of their lifecycle.

This component uses **cosign** as its backend for signature verification and is compatible only with cosign signatures. 