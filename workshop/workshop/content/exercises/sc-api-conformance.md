**Persona: Operators**

The next step in our path to production is a **custom step we added for our use-case** to check the conformance of the API provided by our application with the TMF Open API specification.

In the **current process**, if developers change the API of their application, they **have to generate the API specification in Swagger or Open-API format and push it to a specific Git repository**. Then it will be checked by a Static Conformance Test Kit (SCTK) and the results made available via Elasticsearch.

We **integrated this process in the path to production, fully automated it, and ensured that only conformant APIs will be deployed**. We also used Tekton to implement this functionality but it would also be possible to e.g. create a custom Kubernetes resource for it.
```editor:open-file
file: tm-forum-poc/supply-chain/api-conformance-run-template.yaml
```

Via the `mvn integration-test` command we first generate the Open API specification based on the provided source code.

After that we use the CLI functionailty provided by the SCTK to generate the TMF Open API specification for the Product Catalog Management API (TMF620) and then compare both.
If the API of provided source code is not conform with the TMF620 spec, the step will fail and the developers have to fix it to get their application deployed to production.

See the results of the conformance test with the following command if the `tanzu apps workload tail` comand output was too fast.
```terminal:execute
command: kubectl logs -l carto.run/resource-name=api-conformance -c step-api-conformance-test
clear: true
```