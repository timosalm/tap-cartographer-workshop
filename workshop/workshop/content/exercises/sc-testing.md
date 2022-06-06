**Persona: Operators**

The **first step** in the path to production watches the in the Workload configured repository with the source code for new commits and makes the source code available for the following steps as an archive via HTTP. 

[Flux](https://fluxcd.io) is part of TAP for this functionality, but as with any other tool we provide with TAP it can be easily replaced by an alternative.

After that the **Tekton Pipeline**, we applied in the role of the development team in a previous step, will be automatically executed for the provided source code via an Tekton integration that detects our pipeline based on the `apps.tanzu.vmware.com/pipeline: test`. 
```editor:open-file
file: tmf-product-catalog-management-api-java/config/test-pipeline.yaml
```





