## How to use this flake

Build an output specified in `flake.nix` like so (not all outputs are impure):

```
nix build -o ./result .#tailscale-operator --impure
kubectl apply -f ./result
```

## 1Password usage with Kubernetes Operator

Create a 1Password entry with the CLI:

```
op item create --category=login --title='some-secret' --vault='Kubernetes' \
    'somefield=somevalue' \
    'someotherfield=someothervalue'
```

Alternatively, inject arbitrary fields into an existing 1Password entry with the 1Password CLI:

```
op item edit 'UUID' 'somefield=somevalue'
```

### Generate a OnePasswordItem:

If I had a 1Password entry with the following criteria:
- Desired secret name: `cloudflared`
- Desired namespace: `default`
- Item path: `vaults/Kubernetes/items/m4i7whzvm5amrmxntpoleuaxxe`

I would use the following command to generate a OnePasswordItem:

```
nix run .#1password-item -- --name cloudflared --namespace default --itemPath "vaults/Kubernetes/items/m4i7whzvm5amrmxntpoleuaxxe"
```

## Notes on node setup

### Home Assistant

For Home Assistant to work with wifi and bluetooth, the following commands were necessary on each node:

```
sudo apt-get install -y bluetooth network-manager && sudo systemctl enable --now bluetooth.service
```

For the `macmini7,1` model, install the broadcom wifi driver like so:

```
sudo apt-get install --reinstall bcmwl-kernel-source
```

To discover devices, Avahi must be running:

```
sudo apt-get install -y avahi-daemon
sudo systemctl enable --now avahi-daemon.service
```

Additionally, set the following setting in `/etc/avahi/avahi-daemon.conf`:

```
[reflector]
enable-reflector=yes
reflect-ipv=no
```

And restart Avahi:

```
sudo systemctl restart avahi-daemon.service
```

Additionally, allow UDP port 5353 and TCP port 21063 on your node running HA:

```
sudo ufw allow from any to any port 5353 proto udp
sudo ufw allow from any to any port 21063 proto tcp
```
