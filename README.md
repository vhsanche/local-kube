
# Pre-requesites
# Install K3d 
Follow the instructions below:
```bash
https://k3d.io/v5.4.9/#installation
```

 # Install Helm
 Follow the instructions below:
```bash
https://helm.sh/docs/intro/install/
```

# Running local-kube
Run the following command:
```bash
./local-kube up
```

# Destroying local-kube
```bash
./local-kube down
```

# Using a local registry
This K8s cluster has local registry support. Tag your image as localhost:5000/<image_name> and push it as follows:
```bash
docker push k3d-registry.localhost:5000/<image_name>
```