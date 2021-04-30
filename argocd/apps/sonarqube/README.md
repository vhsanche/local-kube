Instructions
============
```bash
-1. brew install helm
0. helm repo add oteemocharts https://oteemo.github.io/charts
1. helm template --name-template=sonarqube --set persistence.enabled=true --set persistence.size=3Gi oteemocharts/sonarqube > sonarqube.yml
2. kubectl create namespace sonarqube
3. kubectl apply -n sonarqube -f sonarqube.yml
```
Ingress
====
```
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: sonarqube-ingress
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - sonarqube.test-test.com
  rules:
  - host: sonarqube.test-test.com
    http:
      paths:
      - path: /
        backend:
          serviceName: sonarqube-sonarqube
          servicePort: 9000
```

Post Configuration
==================
Need to update your /etc/hosts file with the following:
```bash
<your_ip>   sonarqube.test-test.com
```

References
==========
* https://github.com/Oteemo/charts/tree/master/charts/sonarqube
* https://github.com/SonarSource/sonarqube/blob/master/sonar-application/src/main/assembly/conf/sonar.properties

