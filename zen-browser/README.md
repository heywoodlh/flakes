## Zen Browser packaged with Nix

This is a flake for Zen Browser to tide me over until it's actually packaged in nixpkgs. This flake doesn't build the application from source, it simply extracts the latest release.

### Usage:

If you want to just run the executable:

```
nix run "github:heywoodlh/flakes?dir=zen-browser#zen-browser"
```

#### Installation with NixOS

Using flakes:

```
{
  description = "my flake";

  inputs = {
    zen-browser.url = "github:heywoodlh/flakes/main?dir=zen-browser";
  };

  outputs = inputs@{ self, nixpkgs, zen-browser, }: {
    nixosConfigurations = {
      system = "x86_64-linux";
      specialArgs = inputs;
      modules = [
        {
          environment.systemPackages = [
            zen-browser.packages.x86_64-linux.zen-browser
          ];
        }
      ];
    };
  };
```

If you're not using flakes, it would probably be easiest to make your own copy of [zen.nix](./zen.nix)

#### Wrapper for data persistence:

I've also created a wrapper to create a profile in `~/Documents/zen/Profiles/main` if you want to persist data. Run it like this:

```
nix run "github:heywoodlh/flakes?dir=zen-browser#zen-wrapper"
```
