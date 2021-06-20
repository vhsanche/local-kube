#!/bin/bash
reg_name='kind-registry'
reg_port='5000'
cluster_name='my-cluster'

function kind_local_registry() {
    # create registry container unless it already exists

    running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
    if [ "${running}" != 'true' ]; then
    docker run \
        -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
        registry:2
    fi
}

function kind_post_local_registry() {
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
}

function kind_create_cluster() {
    # create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:${reg_port}"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
- role: worker
EOF
    kubectl cluster-info --context kind-kind
    docker network connect "kind" "${reg_name}" || true
}

function kind_basic() {
    # create local registry
    kind_local_registry
    kind_create_cluster
    kind_post_local_registry
}

function kind_install() {
    # install basic kind cluster
    kind_basic
    kind_install_ingress
    install_argocd
}

function kind_delete () {
    kind delete cluster || true
    docker rm -f kind-registry || true
}

function kind_install_ingress() {
    # install ingress controller
    kubectl create namespace ingress-nginx
    kubectl apply -n ingress-nginx -f core/ingress/mandatory.yaml
    kubectl apply -n ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/baremetal/service-nodeport.yaml
    kubectl patch deployments -n ingress-nginx nginx-ingress-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx-ingress-controller","ports":[{"containerPort":80,"hostPort":80},{"containerPort":443,"hostPort":443}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}' 
}

function install_argocd() {
    # install argocd
    kubectl create namespace argocd
    kubectl apply -k argocd/apps/argocd/dev

    # wait for argocd
    kubectl rollout status deployment argocd-application-controller -n argocd
    kubectl rollout status deployment argocd-dex-server -n argocd
    kubectl rollout status deployment argocd-redis -n argocd 
    kubectl rollout status deployment argocd-repo-server -n argocd
    kubectl rollout status deployment argocd-server -n argocd
    kubectl patch secret -n argocd argocd-secret -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" testtest123! | tr -d ':\n')'"}}'

    # configure app for apps
    kubectl apply -f argocd/application.yml
}

function k3d_basic() {
    # create local registry
    #k3d_local_registry
    
    # create cluster
    #k3d cluster create $cluster_name \
    # -p 80:80@loadbalancer \
    # -p 443:443@loadbalancer \
    # --volume /etc/machine-id:/etc/machine-id \
    # --k3s-server-arg "--no-deploy=traefik" \
    # --registry-use k3d-registry.localhost:5000 \
    # --wait

    APPLICATION=big-bang-quick-start
    IMAGE_CACHE=${HOME}/.big-bang-cache

    mkdir -p ${IMAGE_CACHE}

    # Create the cluster
    k3d cluster create \
    --volume ${IMAGE_CACHE}:/var/lib/rancher/k3s/agent/containerd/io.containerd.content.v1.content \
    --volume /etc/machine-id:/etc/machine-id \
    --k3s-server-arg "--disable=traefik" \
    -p 80:80@loadbalancer \
    -p 443:443@loadbalancer \
    ${APPLICATION}
}

function k3d_local_registry() {
    k3d registry create registry.localhost --port 5000
}

function k3d_install() {
    k3d_basic
    k3d_install_ingress
    install_argocd
}

function k3d_delete() {
    k3d cluster delete $cluster_name || true
    k3d registry delete k3d-registry.localhost || true
}

function k3d_install_ingress() {
    kubectl create namespace ingress-nginx
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx
    kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx
    sleep 15s
}

function install_big_bang() {
    terraform init
    terraform apply -auto-approve
}

function delete_big_bang() {
    terraform destroy -auto-approve
}

CMD=$1

case $CMD in
    kind-basic)
        kind_basic
        ;;
    kind-install)
        kind_install
        ;;
    kind-delete)
        kind_delete
        ;;
    k3d-basic)
        k3d_basic
        ;;
    k3d-install)
        k3d_install
        ;;
    k3d-delete)
        k3d_delete
        ;;
    kind-install-ingress)
        kind_install_ingress
        ;;
    k3d-install-ingress)
        k3d_install_ingress
        ;;
    install-argocd)
        install_argocd
        ;;
    install-big-bang)
        install_big_bang
        ;;
    delete-big-bang)
        delete_big_bang
        ;;
    *)
        echo "Options are to basic, install-ingress, install and delete only."
        ;;
esac
