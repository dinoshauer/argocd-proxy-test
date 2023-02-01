# ArgoCD proxy test

This repo is meant to serve as an "easy" way to test https://github.com/argoproj/argo-cd/pull/9496 locally

## Required software

- [Tailscale](https://tailscale.com/)
- [envsubst](https://github.com/a8m/envsubst)
- [kind](https://kind.sigs.k8s.io/)

## Preparing tailscale

1. Get IP address of your own machine from https://login.tailscale.com/admin/machines
   - Add to `.env` file as `TAILSCALE_IP="..."`
2. Create a reusable and ephemeral api key from https://login.tailscale.com/admin/settings/keys
   - Add to `.env` file as `TAILSCALE_ROUTER_KEY="..."`
3. Make sure allow incoming traffic is enabled in your tailscale preferences

## Setting up clusters

- Run `./init.sh` to set up 2 kind clusers
- Run `./teardown.sh` to remove them when you're done

## Adding a proxied cluster

1. `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
2. `kubectl --namespace=argocd --context=kind-argocd debug -it $(kubectl get pods --selector=app.kubernetes.io/name=argocd-server -o name) --image=dinoshauer/argocd:2.5.5-1 -- bash`
3. `argocd login argocd-server --insecure --username=admin --password=${password from step 2}`
4. Add kubeconfig to debug container (See below code block)
5. `argocd cluster add --proxy-url=socks5://tailscale.tailscale.svc.cluster.local:1055 --name=external --kubeconfig=./kubeconfig kind-external`
6. `argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-namespace default --directory-recurse --dest-name external`

```sh
cat <<EOF > kubeconfig
---
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ...
    server: ...
  name: kind-external
contexts:
- context:
    cluster: kind-external
    user: kind-external
  name: kind-external
current-context: kind-external
kind: Config
preferences: {}
users:
- name: kind-external
  user:
    client-certificate-data: ...
    client-key-data: ...
EOF
```
