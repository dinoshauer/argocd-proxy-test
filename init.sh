#!/bin/bash
set -o pipefail -o errexit -o errtrace -o nounset
shopt -s nullglob
IFS=$'\n\t'

function log () {
  echo -e "\033[1m${@}\033[0m"
}

trap 'log "=== Script execution FAILED!" >&2' ERR

log "=== Creating argocd cluster"
kind create cluster --config=./kind-config-argocd.yaml
kubectl ctx kind-argocd

log "=== Pulling Onomondo's ArgoCD image"
docker pull dinoshauer/argocd:2.5.5-1

log "=== Loading Onomondo's ArgoCD into kind"
kind load docker-image --name argocd dinoshauer/argocd:2.5.5-1

log "=== Installing TailScale router"
kubectl apply --context=kind-argocd -f ./cluster-setup/tailscale/namespace.yaml
for f in ./cluster-setup/tailscale/*.yaml; do
  envsubst < $f | kubectl apply --context=kind-argocd -n tailscale -f -;
done

log "=== Installing ArgoCD"
kubectl apply -k ./cluster-setup/argocd

log "=== Creating external cluster"
envsubst < kind-config-external.yaml >> /tmp/kind-config-external.yaml
kind create cluster --config=/tmp/kind-config-external.yaml
kubectl ctx kind-external

log "=== Setting context back to kind-argocd"
kubectl ctx kind-argocd

log "=== bootstrapping done"
