
Applying Pod Security Policy
============================
```bash
kubectl create -f apps/policy/restricted-psp.yaml
```
To delete pod security policy:
```bash
kubectl delete psp restricted
```
