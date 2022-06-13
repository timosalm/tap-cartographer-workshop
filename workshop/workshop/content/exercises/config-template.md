A **ClusterConfigTemplate** instructs the supply chain how to instantiate a Kubernetes object like a ConfigMap that knows how to make Kubernetes configurations available to further resources in the chain.

For our simple example we use it to provide the deployment configuration of our application to the last step of our Supply Chain and therefore have to consume the outputs of our ClusterImageTemplate resource by referencing it via the `spec.resources[*].images` field of our Supply Chain definition. 
```editor:append-lines-to-file
file: simple-supply-chain/supply-chain.yaml
text: |2
    - name: app-config
      templateRef:
        kind: ClusterConfigTemplate
        name: simple-config-template-{{ session_namespace }}
      images:
      - resource: image-builder
        name: image
```
For the deployment of our application, we will use Knative, which is a serverless application runtime for Kubernetes with e.g. auto-scaling capabilities to save costs.
```editor:append-lines-to-file
file: simple-supply-chain/config-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterConfigTemplate
  metadata:
    name: simple-config-template-{{ session_namespace }}
  spec:
    configPath: .data
    ytt: |
      #@ load("@ytt:data", "data")
      #@ load("@ytt:yaml", "yaml")

      #@ def delivery():
      apiVersion: serving.knative.dev/v1
      kind: Service
      metadata:
        name: #@ data.values.workload.metadata.name
      spec:
        template: 
          spec:
            containers:
              image: #@ data.values.image
              name: workload
      #@ end

      ---
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: #@ data.values.workload.metadata.name
      data:
        delivery.yml: #@ yaml.encode(delivery())
```
The ClusterConfigTemplate requires definition of a `spec.configPath` and it will update its status to emit a config value, which is a reflection of the value at the path on the created object. 

The detailed specifications of the ClusterConfigTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/template/#clusterconfigtemplate
```
