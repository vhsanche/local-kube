# Local registry
This K8s cluster has local registry support. Tag your image as localhost:5000/<image_name> and push it as follows:
```bash
docker push localhost:5000/<image_name>
```

# To install a basic K8s cluster with ingress
```bash
./infra.sh kind-basic
```

# To install a K8s cluster with ArgoCD
```bash
./infra.sh kind-install
```
# To delete
```bash
./infra.sh kind-delete
```

Pre-requesites
==============
To install kind or K3d do the following:

Kind - On Linux
========
```bash
curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-$(uname)-amd64"
chmod +x ./kind
sudo mv kind /usr/local/bin
wget https://get.helm.sh/helm-v3.1.0-linux-amd64.tar.gz
tar xvfz helm-v3.1.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin
```

Kind - On Mac
===
```bash
brew install kind
brew install helm
brew tap argoproj/tap
brew install argoproj/tap/argocd
```
To give Docker enough computer resources do the following:
```bash
4 CPUs
8 GB RAM
1 GB Swap
```

k3d - On Mac
===
```bash
brew install k3d
```

Helm Prerequesites
=================
```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
# used for keycloak
helm repo add codecentric https://codecentric.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

Big Bang
=======
What you need:
- [Docker](https://docs.docker.com/get-started/)
- [k3d](https://github.com/rancher/k3d)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

Nice to haves:
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) - _CLI for working with k8s/k3d_
- [K8s Lens](https://k8slens.dev/) - _Handy GUI for kubectl_

# Instructions

### Create the file `terraform.tfvars` and fill out below.   You will need to get your [Registry1](http://registry1.dso.mil/) CLI secret from the user profile screen.

```bash
registry1_username="REPLACE_ME"
registry1_password="REPLACE_ME"
```

### Deploy Big Bang onto the new cluster

```bash

# Initialize & apply terraform (type yes at prompt)
terraform init
terraform apply 

# Watch the deployments
watch kubectl get kustomizations,hr,po -A

# Get a list of http endpoints
kubectl get vs -A
```

### Teardown

```bash
# Big bang teardown (optional, takes several minutes & just reverts back to an empty cluster)
terraform destroy
