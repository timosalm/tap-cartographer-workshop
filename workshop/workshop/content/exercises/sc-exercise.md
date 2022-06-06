
##### Create new Supply Chain
```terminal:execute
command: mkdir custom-supply-chain
clear: true
```
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |
    apiVersion: carto.run/v1alpha1
    kind: ClusterSupplyChain
    metadata:
      name: custom-supply-chain-{{ session_namespace }}
    spec:
      params: []
      resources: []
```

##### Create Github source template
```editor:append-lines-to-file
file: custom-supply-chain/custom-github-source-template.yaml
text: |
    apiVersion: carto.run/v1alpha1
    kind: ClusterSourceTemplate
    metadata:
      name: custom-github-source-{{ session_namespace }}-template
    spec:
```
```terminal:execute
command: kubectl get crds githubrepositories.timosalm.de -o yaml
clear: true
```

##### Create Kaniko image template
```editor:append-lines-to-file
file: custom-supply-chain/custom-kaniko-image-template.yaml
text: |
    apiVersion: carto.run/v1alpha1
    kind: ClusterImageTemplate
    metadata:
      name: custom-kaniko-{{ session_namespace }}-template
    spec:
```
```editor:append-lines-to-file
file: custom-supply-chain/custom-kaniko-image-template.yaml
text: |
   apiVersion: carto.run/v1alpha1
    kind: ClusterRunTemplate
    metadata:
      name: custom-kaniko-{{ session_namespace }}-template
    spec:
```

##### Create deployment template
```editor:append-lines-to-file
file: custom-supply-chain/supply-chain.yaml
text: |
    apiVersion: carto.run/v1alpha1
    kind: ClusterTemplate
    metadata:
      name: custom-deployment-{{ session_namespace }}-template
    spec:
```