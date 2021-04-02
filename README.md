# Local registry
This K8s cluster has local registry support. Tag your image as localhost:5000/<image_name> and push it as follows:
```bash
docker push localhost:5000/<image_name>
```

# To install a basic K8s cluster with ingress
```bash
./infra.sh basic
```

# To install a K8s cluster with ArgoCD
```bash
./infra.sh install
```
# To delete
```bash
./infra.sh delete
```

Pre-requesites
==============
To install kind do the following:

On Linux
========
```bash
curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-$(uname)-amd64"
chmod +x ./kind
sudo mv kind /usr/local/bin
wget https://get.helm.sh/helm-v3.1.0-linux-amd64.tar.gz
tar xvfz helm-v3.1.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin
```

On Mac
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
Helm Prerequesites
=================
```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
# used for keycloak
helm repo add codecentric https://codecentric.github.io/helm-charts
helm repo update
```
Instructions
============
To create development environment run the following:
```bash
1. kind create cluster --config cluster-config.yml
2. kubectl cluster-info --context kind-kind
3. kubectl create namespace ingress-nginx
4. kubectl apply -n ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/mandatory.yaml
5. kubectl apply -n ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/baremetal/service-nodeport.yaml
6. kubectl patch deployments -n ingress-nginx nginx-ingress-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx-ingress-controller","ports":[{"containerPort":80,"hostPort":80},{"containerPort":443,"hostPort":443}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}' 
```

To Verify Configuration
=====================
Perform the following command:
```bash
1. kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml
2. # should output "foo"
curl localhost/foo
# should output "bar"
curl localhost/bar
```

Delete verification configuration:
```bash
kubectl delete -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml
```
