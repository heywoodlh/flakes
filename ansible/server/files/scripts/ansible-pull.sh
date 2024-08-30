#!/usr/bin/env bash

if command -v nix &>/dev/null
then
  nix run "github:heywoodlh/flakes/$(git ls-remote https://github.com/heywoodlh/flakes | head -1 | awk '{print $1}')?dir=ansible#${system}"
else
  /opt/scripts/install-ansible.sh # install ansible in case it's been removed for some reason
  mkdir -p /opt/ansible/
  curl --silent -L https://raw.githubusercontent.com/heywoodlh/flakes/main/ansible/requirements.yml -o /opt/ansible/requirements.yml
  ansible-galaxy install -r /opt/ansible/requirements.yml
  ansible-pull -U https://github.com/heywoodlh/flakes ansible/server/standalone.yml
fi
