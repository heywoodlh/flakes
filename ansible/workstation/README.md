## Requirements:

These playbooks assume the system is already installed and that you are the root user (but a non-root user should not be created yet).

## Running the playbooks:

After installing the latest version of Ansible and `git`, run the following commands:

```
ansible-pull -U https://github.com/heywoodlh/ansible setup.yml
ansible-pull -U https://github.com/heywoodlh/ansible playbooks/workstations/workstation.yml
```
