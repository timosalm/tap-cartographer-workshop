**Persona: Developers**

Inspired by [start.spring.io](https://start.spring.io), **Application Accelerator for VMware Tanzu** enables developers to create new applications based on templates that follow enterprise standards defined by platform engineers and architects. This accelerates how a developer goes from idea to running system with ready-made, enterprise-conformant code and configurations.

Application Accelerator for VMware Tanzu can be installed with a variety of sample Accelerators.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/create
```

For our use-case we created Accelerators for the TMF Product Catalog Management API in two different languages to show the ploygot capabilites of VMware Tanzu Application Platform.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/create?filters%5Bkind%5D=template&filters%5Buser%5D=all&filters%5Btags%5D%5B0%5D=tmf620
```

Let's have a closer look at the Java version of the Accelerator.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/create/templates/tmf-product-catalog-management-api-java
```

As an alternative to the UI, it's also possible to generate a project from an Accelerator with the **tanzu CLI** that can also be used to add, update, and delete Accelerators.
```terminal:execute
command: tanzu accelerator list --server-url http://accelerator.{{ ENV_TAP_INGRESS }}
clear: true
```
```terminal:execute
command: |
  export GIT_BRANCH={{ session_namespace }}-$(cat /proc/sys/kernel/random/uuid)
  tanzu accelerator generate tmf-product-catalog-management-api-java --options '{"artifactId":"product-catalog-management-api-java","database":"mongo","gitUrl":"{{ ENV_APP_GIT_REPO_HTTP_URL }}","gitBranch":"'"$GIT_BRANCH"'","namespace":"{{ session_namespace }}","apiSpecLocation":"remote","cnrSubdomain":"{{ ENV_TAP_CNRS_SUBDOMAIN }}"}' --server-url http://accelerator.{{ ENV_TAP_INGRESS }}
clear: true
```

Finally, we are able to extract the project files from the archive.
```terminal:execute
command: unzip tmf-product-catalog-management-api-java.zip && cd tmf-product-catalog-management-api-java
clear: true
```
