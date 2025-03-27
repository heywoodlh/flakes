#!/usr/bin/env bash

root_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

applications=(
  "actual"
  "attic"
  "argo"
  "cloudflared"
  "coredns"
  "crossplane"
  "drawio"
  "fleetdm"
  "gomuks"
  "grafana"
  "healthchecks"
  "http-files"
  "iperf"
  "kubevirt"
  "lancache"
  "miniflux"
  "ntfy"
  "nuclei"
  "open-webui"
  "prometheus"
  "protonmail-bridge"
  "rsshub"
  "rustdesk"
  "rustdesk-web"
)

echo "" > ${root_dir}/manifests/apps.yaml

set -ex

for app in "${applications[@]}"
do
    nix build "${root_dir}#${app}"
    cp ./result "${root_dir}/manifests/${app}.yaml" # Copy file instead of using symlink
    chmod 644 "${root_dir}/manifests/${app}.yaml"

cat >> ${root_dir}/manifests/apps.yaml << EOL
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${app}
  namespace: argo
spec:
  destination:
    server: https://kubernetes.default.svc
    namespace: argo
  source:
    repoURL: https://github.com/heywoodlh/flakes.git
    targetRevision: HEAD
    path: kube/manifests
    directory:
      include: "${app}.yaml"
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOL
done
