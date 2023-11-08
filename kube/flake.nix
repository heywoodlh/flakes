{
  description = "heywoodlh kubernetes flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-kube-generators.url = "github:farcaller/nix-kube-generators";
  inputs.nixhelm.url = "github:farcaller/nixhelm";
  inputs.tailscale.url = "github:tailscale/tailscale";

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    nix-kube-generators,
    nixhelm,
    tailscale,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      kubelib = nix-kube-generators.lib { inherit pkgs; };
    in {
      packages = {
        "1password-connect" = (kubelib.buildHelmChart {
          name = "1password-connect";
          chart = (nixhelm.charts { inherit pkgs; })."1password".connect;
          namespace = "kube-system";
        });
        tailscale-operator = (kubelib.buildHelmChart {
          name = "tailscale-operator";
          chart = "${tailscale}/cmd/k8s-operator/deploy/chart";
          namespace = "kube-system";
          values = {
            operatorConfig = {
              image = {
                repo = "docker.io/tailscale/k8s-operator";
                tag = "unstable-v1.53";
              };
            };
            proxyConfig = {
              image = {
                repo = "docker.io/tailscale/tailscale";
                tag = "unstable-v1.53";
              };
              defaultTags = "tag:k8s";
            };
          };
        });
      };

      devShell = pkgs.mkShell {
        name = "kubernetes-shell";
        buildInputs = with pkgs; [
          k9s
          kubectl
          kubernetes-helm
        ];
      };
      formatter = pkgs.alejandra;
    });
}
