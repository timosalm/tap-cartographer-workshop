**Persona: Developers**

The **Organization Catalog** is a centralized system that keeps track of ownership and metadata for all the software in our ecosystem (services, websites, libraries, data pipelines, etc). The catalog is built around the concept of **metadata files stored together with the code**, which are then harvested and visualized.

It enables **two main use-cases**:
- Helping teams manage and maintain the software they own.
- Makes all the software in our organisation, and who owns it, discoverable.

Let's have a look how that looks like for our use-case. 

**Note: The supply chain run has to be completed and the application running for the following commands**

We first have to import the Organization Catalog definition. Copy the following output ...
```execute
echo "${APP_GIT_REPO_HTTP_URL%.*}/blob/${GIT_BRANCH}/catalog/catalog-info.yaml"
```
... and paste it into the Catalog import dialog.
```dashboard:open-url
url: https://tap-gui.emea.end2end.link/catalog-import
```

After the import we should be able to have a look at the different entities of the Catalog.
```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/catalog/default/system/tmf-apis-system/diagram
```