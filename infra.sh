#!/bin/bash
reg_name='kind-registry'
reg_port='5000'

function local_registry() {
    # create registry container unless it already exists

    running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
    if [ "${running}" != 'true' ]; then
    docker run \
        -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
        registry:2
    fi
}

function post_local_registry() {
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

function create_cluster() {
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

function basic() {
    # create local registry
    local_registry
    create_cluster
    post_local_registry
}

function install_ingress() {
    # install ingress controller
    kubectl create namespace ingress-nginx
    kubectl apply -n ingress-nginx -f base/ingress/mandatory.yaml
    kubectl apply -n ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/baremetal/service-nodeport.yaml
    kubectl patch deployments -n ingress-nginx nginx-ingress-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx-ingress-controller","ports":[{"containerPort":80,"hostPort":80},{"containerPort":443,"hostPort":443}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}' 
}

function install() {
    # install basic kind cluster
    basic
    install_ingress

    # install psp
    kubectl apply -f base/policy/restricted-psp.yml

    # install argocd
    kubectl create namespace dev
    kubectl apply -k base/argocd/dev

    # wait for argocd
    kubectl rollout status deployment argocd-application-controller -n dev
    kubectl rollout status deployment argocd-dex-server -n dev
    kubectl rollout status deployment argocd-redis -n dev 
    kubectl rollout status deployment argocd-repo-server -n dev
    kubectl rollout status deployment argocd-server -n dev
    kubectl patch secret -n dev argocd-secret -p '{"stringData": { "admin.password": "'$(htpasswd -bnBC 10 "" testtest123! | tr -d ':\n')'"}}'

    # configure app for apps
    kubectl apply -f application.yml
    
}

function install_keycloak() {
    # install postgresql and keycloak
    kubectl create namespace keycloak
    kubectl apply -n keycloak -f apps/keycloak/postgres/postgres.yml
    kubectl rollout status sts/keycloak-postgresql -n keycloak
    kubectl apply -n keycloak -f apps/keycloak/keycloak.yml
    kubectl rollout status -n keycloak sts/keycloak
}

function delete () {
    kind delete cluster || true
    docker rm -f kind-registry || true
}

CMD=$1

case $CMD in
    basic)
        basic
        ;;
    install-ingress)
        install_ingress
        ;;
    install)
        install
        ;;
    delete)
        delete
        ;;
    *)
        echo "Options are to basic, install-ingress, install and delete only."
        ;;
esac
