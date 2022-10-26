# A workshop that demonstrates all the capabilities Supply Chain Choreographer provides

A [Learning Center for VMware Tanzu](https://docs.vmware.com/en/Tanzu-Application-Platform/1.1/tap/GUID-learning-center-about.html) workshop that demonstrates all the capabilities Supply Chain Choreographer provides.

## Prerequisites

- A TAP 1.1 environment with OOTB Testing/Scanning Supply Chain installed
- [Gitea](https://gitea.io) for the creation of Git repositories for each session

## Workshop installation
Download the Tanzu CLI for Linux to the root of this sub-directory.
Create a public project called **tap-workshop** in your registry instance. 

There is a Dockerfile in the `workshop` directory of this repo. From that directory, build a Docker image and push it to the project you created:
```
docker build . -t <your-registry-hostname>/tap-workshop/cartographer-workshop
docker push <your-registry-hostname>/tap-workshop/cartographer-workshop
```

Copy values-example.yaml to values.yaml and set configuration values
```
cp values-example.yaml values.yaml
```
Run the installation script.
```
./install.sh
```

## Debug
```
kubectl logs -l deployment=learningcenter-operator -n learningcenter
```
