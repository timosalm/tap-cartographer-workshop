**Persona: Developers**

Part of the TAP GUI is also a plug-in for **API documentation** which enables nables API consumers to find APIs they can use in their own applications. Consumers can view detailed API documentation and try out an API to see if it can meet their needs. It assembles its dashboard and detailed API documentation views by ingesting OpenAPI documentation from the source URLs. 
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/api/tmf-product-catalog-management-api/definition
```

The plug-in that is available in the current version of TAP is based on the Backstage OSS plugin. In addition VMware has its own API discovery solution **API portal for VMware Tanzu** that is also part of TAP.
```dashboard:open-url
url: https://api-portal.{{ ENV_TAP_INGRESS }}/group/tmf-product-catalog-management-api
```
It **adds some capabilities** like the automated discovery of APIs of another product, the developer friendly API Gateway called **VMware Spring Cloud Gateway for Kubernetes**.
VMware is working on the integration of API portal for VMware Tanzu (and VMware Spring Cloud Gateway for Kubernetes) into TAP GUI with new capabilities like the generation of session tokens for the HTTP Authorization of the APIs.

