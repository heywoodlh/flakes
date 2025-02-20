# Ansible Playbooks

These are my playbooks for managing non-NixOS servers.

Currently supports the following distributions:
- Ubuntu
- Debian
- Arch Linux
- Alpine

## Testing

Use the following command to test all variations of Linux distributions via Docker:

```
bash test.sh
```

For more specific testing, provide a specific distribution and target, for example, here are some combinations:

```
bash test.sh alpine # test server and workstation playbooks for Alpine
bash test.sh ubuntu server # test ubuntu server playbooks
bash test.sh debian workstation # test debian workstation playbooks
```
