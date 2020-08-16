#!/bin/bash

function install() {
    # install kind K8 cluster and add ingress controller
    kind create cluster --config cluster-config.yml
    kubectl cluster-info --context kind-kind
    kubectl create namespace ingress-nginx
    kubectl apply -n ingress-nginx -f base/ingress/mandatory.yaml
    kubectl apply -n ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.27.0/deploy/static/provider/baremetal/service-nodeport.yaml
    kubectl patch deployments -n ingress-nginx nginx-ingress-controller -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx-ingress-controller","ports":[{"containerPort":80,"hostPort":80},{"containerPort":443,"hostPort":443}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}' 
    
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
    kind delete cluster
}

CMD=$1

case $CMD in
    install)
        install
        ;;
    delete)
        delete
        ;;
    *)
        echo "Options are to install and delete only."
        ;;
esac
