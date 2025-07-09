#!/usr/bin/env bash

# Ansible installer script in case Ansible gets removed

export PATH="$HOME/.local/bin:$PATH"

# Debian-specific commands
if [[ -e /etc/debian_version ]]
then
  apt update
  apt install -y pipx git curl

  dpkg -r ansible || true
  command -v ansible &>/dev/null || pipx install --include-deps ansible
fi

if grep -q 'Arch Linux' /etc/os-release
then
  pacman -Sy --noconfirm ansible git curl
fi
