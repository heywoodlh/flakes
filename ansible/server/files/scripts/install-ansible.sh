#!/usr/bin/env bash

# Ansible installer script in case Ansible gets removed

# Debian-specific commands
if [[ -e /etc/debian_version ]]
then
  if grep -iq 'Ubuntu' /etc/os-release
  then
    apt update
    apt install software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
  else
    UBUNTU_CODENAME=jammy
    wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | tee /etc/apt/sources.list.d/ansible.list
  fi
  apt update
  apt install -y ansible git curl
fi

if grep -q 'Arch Linux' /etc/os-release
then
  pacman -Sy --noconfirm ansible git curl
fi
