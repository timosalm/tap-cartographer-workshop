A **Runnable** object declares the intention of having immutable objects submitted to Kubernetes according to a template ( via ClusterRunTemplate) whenever any of the inputs passed to it changes. i.e., it allows us to provide a mutable spec that drives the creation of immutable objects whenever that spec changes.

A **ClusterRunTemplate** differs from supply chain templates in many aspects (e.g. cannot be referenced directly by a ClusterSupplyChain, **outputs** provide a free-form way of exposing any form of results). It defines how an immutable object should be stamped out based on data provided by a **Runnable**.

Sounds like we've found a way to stamp out our immutable **TaskRuns** and **PipelineRuns**.
```editor:select-matching-text
file: simple-supply-chain/config-writer-template.yaml
text: "  ytt: \"\""
```
```editor:replace-text-selection
file: simple-supply-chain/config-writer-template.yaml
text: |2
    ytt: |
      #@ load("@ytt:data", "data")
      ---
      apiVersion: carto.run/v1alpha1
      kind: Runnable
      metadata:
        name: #@ data.values.workload.metadata.name + "-config-writer"
      spec:
        runTemplateRef:
          name: simple-run-template-{{ session_namespace }}

        inputs:
          git_repository: #@ data.values.params.git_repository
          git_files: #@ data.values.config
```

```editor:append-lines-to-file
file: simple-supply-chain/run-template.yaml
text: |2
  apiVersion: carto.run/v1alpha1
  kind: ClusterRunTemplate
  metadata:
    name: simple-run-template-{{ session_namespace }}
  spec:
    outputs: {}
    template: {}
```
`spec.outputs` provides a free-form way of exposing any form of results from what has been run to the status of the Runnable object (as opposed to typed “source”, “image”, and “config” from supply chains). Because we don't have the need to expose any outputs to our Supply Chain and therefore using a ClusterTemplate, we don't have to specify it.

We'll now configure a TaskRun to push the deployment configuration to a GIT repository.
```editor:select-matching-text
file: simple-supply-chain/run-template.yaml
text: "  outputs: {}"
after: 1
```
```editor:replace-text-selection
file: simple-supply-chain/run-template.yaml
text: |2
    template:
      apiVersion: tekton.dev/v1beta1
      kind: TaskRun
      metadata:
        generateName: $(runnable.metadata.name)$-
      spec:
        taskRef:
          name: git-cli
        workspaces:
        - name: ssh-directory
          secret:
            secretName: git-ssh-credentials
        - name: source
          emptyDir: {}
        params:
          - name: GIT_USER_NAME
            value: {{ session_namespace }}
          - name: GIT_USER_EMAIL
            value: {{ session_namespace }}@vmware.com
          - name: GIT_SCRIPT
            value: |
              if git clone --depth 1 -b main "$(runnable.spec.inputs.git_repository)$" ./repo; then
                cd ./repo
              else
                git clone --depth 1 "$(runnable.spec.inputs.git_repository)$" ./repo
                cd ./repo
                git checkout -b main
              fi

              mkdir -p config && rm -rf config/*
              cd config

              echo '$(runnable.spec.inputs.git_files)' > files.yaml
              git add .

              git commit -m "Update deployment configuration"
              git push origin $(params.git_branch)
```

The detailed specifications of the Runnable and ClusterRunTemplate can be found here: 
```dashboard:open-url
url: https://cartographer.sh/docs/v0.3.0/reference/runnable/
```

Let's now apply our resources to the cluster as a group of resources via the kapp CLI and see via the commercial Supply Chain Choreographer UI plugin and the following commands whether everything works as expected.
```terminal:execute
command: kapp deploy -a simple-supply-chain -f simple-supply-chain -y
clear: true
```

```dashboard:open-url
url: https://tap-gui.{{ ENV_TAP_INGRESS }}/supply-chain/{{ session_namespace }}/simple-app
```

```terminal:execute
command: kubectl describe clustersupplychain simple-supplychain-{{ session_namespace }}
clear: true
```

```terminal:execute
command: kubectl tree workload simple-app
clear: true
```

```terminal:execute
command: kubectl describe workload simple-app 
clear: true
```
