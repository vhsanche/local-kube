Generate Manifest
=================
```bash
kubectl create namespace weave-scope
helm template --name-template=scope --namespace weave-scope stable/weave-scope --version 1.1.8 > scope.yml
kubectl apply -f scope.yml
```
