Instructions
============
```bash
1. kubectl create namespace argocd
2. kubectl apply -n argocd -f argocd.yml
3. kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```


Post Configuration
==================
Need to update your /etc/hosts file with the following:
```bash
127.0.0.1   localhost sso.test-test.com argocd.test-test.com
```

References
==========

