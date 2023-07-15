## My Vim Configs

This repo contains my `vim` configuration as a Nix Flake.

## Usage:

Install `nix`:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

If you want to try it out, run the Flake:

```
nix run "github:heywoodlh/flakes/main?dir=vim"
```

If you want to install it, install it to your Nix profile:

```
nix profile install "github:heywoodlh/flakes/main?dir=vim"
```

If you want to use it in a Flake, do something like this:

```
{
  description = "my flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    vim-configs.url = "github:heywoodlh/flakes/main?dir=vim";
  };

  outputs = inputs@{ self, nixpkgs, vim-configs }: {
    nixosConfigurations = {
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [
        {
          environment.systemPackages = [
            vim-configs.defaultPackage.${system}
          ];
        }
      ];
    };
  };
```
