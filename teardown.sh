#!/bin/bash
set -o pipefail -o errexit -o errtrace -o nounset
shopt -s nullglob
IFS=$'\n\t'

trap 'echo "Script execution FAILED!" >&2' ERR

kind delete cluster --name=argocd
kind delete cluster --name=external
