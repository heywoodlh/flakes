## setup-scripts

Various scripts for setting up a new system.

## Dependencies

Debian:

```
apt update && apt install -y curl sudo git
```

Alpine:

```
apk add --no-cache curl bash shadow sudo git
```

Arch:

```
pacman -Syu --noconfirm curl bash sudo git
```

## Usage:

Ensure the following commands are run as a `sudo` user.

### Workstation:

```
curl -L https://files.heywoodlh.io/scripts/linux.sh | bash -s -- workstation --ansible --home-manager
```

### Server:

```
curl -L https://files.heywoodlh.io/scripts/linux.sh | bash -s -- server --ansible --home-manager
```

### Unprivileged, FUSE-enabled system (installs AppImages):

```
curl -L https://files.heywoodlh.io/scripts/linux.sh | bash -s -- files-only
```
