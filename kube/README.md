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
