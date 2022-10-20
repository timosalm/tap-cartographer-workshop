A **ClusterTemplate** instructs the supply chain to instantiate a Kubernetes object that has no outputs to be supplied to other objects in the chain.

To standardize our application deployment to a fleet of clusters, we'll use **GitOps** which is an operational model that applies the principles of Git and best practices from software development to infrastructure configuration. 
With the GitOps approach, Git is used to version and store the necessary deployment configuration of our application configuration files as the single source of truth for infrastructure running in development, staging, production, etc. 

Therefore, the last step of our Supply Chain is the push of the deployment configuration to Git repository. 

```editor:append-lines-to-file
file: simple-supply-chain/supply-chain.yaml
text: |2
    - name: config-writer
      templateRef:
        kind: ClusterTemplate
        name: simple-config-writer-template-{{ session_namespace }}
      configs:
      - resource: app-config
        name: config
      params:
      - name: git_repository
        value: {{ ENV_GITOPS_REPOSITORY }}
```

```editor:append-lines-to-file
file: simple-supply-chain/config-writer-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterTemplate
  metadata:
    name: simple-config-writer-template-{{ session_namespace }}
  spec:
    healthRule:
      singleConditionType: Ready
    ytt: ""
```

Because there is no suitable solution for Kubernetes available, the Kubernetes native CI/CD solution [Tekton](https://tekton.dev) will help us to implement it, or more precisely, **Tekton Pipelines**, which provides the building blocks for the creation of pipelines. 

Tekton Pipelines defines the following entities:
- **Tasks** define a series of steps that launch specific build or delivery tools that ingest specific inputs and produce specific outputs.
- **Pipelines** define a series of ordered Tasks if it's getting more complex
- **TaskRuns** and **PipelineRuns** instantiate specific Tasks and Pipelines to execute on a particular set of inputs and produce a particular set of outputs

![](../images/tekton-runs.png)

**TaskRuns** and **PipelineRuns** are immutable Kubernetes resources, and therefore, it's not possible to configure it in our ClusterTemplate, because it will try to update that immutable Kubernetes resource on every signal for an input change. 

The detailed specifications of the ClusterTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.5.0/reference/template/#clustertemplate
```
