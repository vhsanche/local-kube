Instructions
============
```bash
1. helm template --name-template=keycloak --set postgresqlPassword=keycloak --set postgresqlUsername=keycloak --set postgresqlDatabase=keycloak --set persistence.size=2Gi --version 3.15.0 stable/postgresql > postgres.yml
2. kubectl create namespace keycloak
3. Change StatefulSet to v1
4. kubectl apply -n keycloak -f postgres.yml
5. kubectl rollout status sts/keycloak-postgresql -n keycloak
```

References
==========
```bash
https://github.com/galexrt/kubernetes-keycloak
https://github.com/helm/charts/tree/master/stable/postgresql
```
