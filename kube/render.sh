#!/usr/bin/env bash

root_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

applications=(
  "actual"
  "attic"
  "argo"
  "cloudflared"
  "coredns"
  "coredns-kube-system"
  "crossplane"
  "drawio"
  "flan-scan"
  "fleetdm"
  "grafana"
  "healthchecks"
  "homepage"
  "http-files"
  "iperf"
  "lancache"
  "media"
  "miniflux"
  "namespaces"
  "nfcapd"
  "ntfy"
  "nuclei"
  "open-webui"
  "palworld"
  "prometheus"
  "protonmail-bridge"
  "rsshub"
  "rustdesk"
  "rustdesk-web"
  "samplicator"
  "syncthing"
  "syslog"
)


set -ex

gen_list=true
if [[ -n "${1}" ]]
then
    applications=("${1}")
    gen_list=false
else
    echo "" > ${root_dir}/manifests/apps.yaml
fi

for app in "${applications[@]}"
do
    nix build "${root_dir}#${app}"
    cp ./result "${root_dir}/manifests/${app}.yaml" # Copy file instead of using symlink
    chmod 644 "${root_dir}/manifests/${app}.yaml"

    if [[ "${gen_list}" == true ]]
    then
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
    fi
done
