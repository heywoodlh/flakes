## My nushell configs

This directory contains my `nushell` configuration as a Nix Flake.

## Usage:

Install `nix`:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

If you want to try it out, run the Flake:

```
nix run "github:heywoodlh/flakes/main?dir=nushell"
```

If you want to install it, install it to your Nix profile:

```
nix profile install "github:heywoodlh/flakes/main?dir=nushell"
```

If you want to use it in a Flake, do something like this:

```
{
  description = "my flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nushell-configs.url = "github:heywoodlh/flakes/main?dir=nushell";
  };

  outputs = inputs@{ self, nixpkgs, nushell-configs }: {
    nixosConfigurations = {
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [
        {
          environment.systemPackages = [
            nushell-configs.packages.${system}
          ];
        }
      ];
    };
  };
```
