Instructions
============
```bash
1. helm template --name-template=keycloak --set keycloak.persistence.deployPostgres=false --set keycloak.username=admin --set keycloak.password=keycloak --set keycloak.persistence.dbVendor=postgres --set keycloak.persistence.dbName=keycloak --set keycloak.persistence.dbHost=keycloak-postgresql --set keycloak.persistence.dbPort=5432 --set keycloak.persistence.dbUser=keycloak --set keycloak.persistence.dbPassword=keycloak codecentric/keycloak > keycloak.yml
2. kubectl create namespace keycloak
3. kubectl apply -n keycloak -f keycloak.yml
4. kubectl rollout status -n keycloak sts/keycloak
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: keycloak-ingress
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: sso.test-test.com
    http:
      paths:
      - path: /
        backend:
          serviceName: keycloak-http
          servicePort: 8080
      - path: /auth
        backend:
          serviceName: keycloak-http
          servicePort: 8080

Post Configuration
==================
Need to update your /etc/hosts file with the following:
```bash
127.0.0.1   localhost sso.test-test.com
```

References
==========
* https://github.com/galexrt/kubernetes-keycloak
* https://github.com/codecentric/helm-charts/tree/master/charts/keycloak
