## My Vim Configs

This repo contains my `vim` configuration as a Nix Flake.

## Usage:

Install `nix`:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

If you want to try it out, run the Flake:

```
nix run github:heywoodlh/vim-configs
```

If you want to install it, install it to your Nix profile:

```
nix profile install github:heywoodlh/vim-configs
```
