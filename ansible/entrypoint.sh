PATH="/root/.local/bin:/usr/bin:/usr/local/bin:$PATH"

set -ex

# install requirements
ansible-galaxy install -r /ansible/requirements.yml

# server build
ansible-playbook --connection=local /ansible/server/standalone.yml || exit 1
printf "server playbooks completed"
# workstation build
ansible-playbook --connection=local /ansible/workstation/workstation.yml || exit 2
printf "workstation playbooks completed"
