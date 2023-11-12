{
  description = "heywoodlh kubernetes flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nfs-helm = {
    url = "github:kubernetes-sigs/nfs-subdir-external-provisioner";
    flake = false;
  };
  inputs.nixhelm.url = "github:farcaller/nixhelm";
  inputs.nix-kube-generators.url = "github:farcaller/nix-kube-generators";
  inputs.tailscale.url = "github:tailscale/tailscale";
  inputs.jellyfin-helm = {
    url = "github:brianmcarey/jellyfin-helm";
    flake = false;
  };
  inputs.longhorn = {
    url = "github:longhorn/longhorn/19e8fefd3ace7fb66c3f3521fc471b60a829b155"; # v1.5.1
    flake = false;
  };
  inputs.plex-helm = {
    url = "github:plexinc/pms-docker";
    flake = false;
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    nfs-helm,
    nix-kube-generators,
    nixhelm,
    jellyfin-helm,
    longhorn,
    plex-helm,
    tailscale,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      kubelib = nix-kube-generators.lib { inherit pkgs; };
      tailscale_operator_config = {
        name ? "tailscale-operator",
        namespace ? "default",
        hostname ? "tailscale-operator",
      }: (kubelib.buildHelmChart {
        name = "${name}";
        chart = "${tailscale}/cmd/k8s-operator/deploy/chart";
        namespace = "${namespace}";
        values = {
          operatorConfig = {
            image = {
              repo = "docker.io/tailscale/k8s-operator";
              tag = "unstable-v1.53";
            };
            hostname = "${hostname}";
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
    in {
      packages = {
        "1password-connect" = (kubelib.buildHelmChart {
          name = "1password-connect";
          chart = (nixhelm.charts { inherit pkgs; })."1password".connect;
          namespace = "kube-system";
          values = {
            connect.credentials = builtins.readFile /tmp/1password-credentials.json;
          };
        });
        jellyfin = (kubelib.buildHelmChart {
          name = "jellyfin";
          chart = jellyfin-helm;
          namespace = "default";
          values = {
            image = {
              repository = "docker.io/jellyfin/jellyfin";
              tag = "20231109.107-unstable";
            };
            service = {
              port = 80;
              annotations = {
                "tailscale.com/expose" = "true";
                "tailscale.com/hostname" = "jellyfin";
                "tailscale.com/tags" = "tag:jellyfin,tag:k8s";
              };
            };
            persistence = {
              config = {
                enabled = true;
                storageClass = "nfs-media";
                subPath = "./jellyfin/config";
              };
              media = {
                enabled = true;
                storageClass = "nfs-media";
                subPath = "./";
              };
            };
          };
        });
        longhorn = pkgs.stdenv.mkDerivation {
          name = "longhorn";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${longhorn}/deploy/longhorn.yaml $out
          '';
        };
        media-pvc = import ./storage/local-pvc.nix {
          "name" = "media";
          "path" = "/media/plex";
          "namespace" = "media";
        };
        plex = (kubelib.buildHelmChart {
          name = "plex";
          chart = "${plex-helm}/charts/plex-media-server";
          namespace = "media";
          values = {};
        });
        tailscale-operator = tailscale_operator_config {
          name = "tailscale-operator";
          namespace = "default";
          hostname = "tailscale-operator";
        };
        tailscale-operator-media = tailscale_operator_config {
          name = "tailscale-operator-media";
          namespace = "media";
          hostname = "tailscale-operator-media";
        };
        tailscale-operator-kube-system = tailscale_operator_config {
          name = "tailscale-operator-kube-system";
          namespace = "kube-system";
          hostname = "tailscale-operator-kube-system";
        };
        tailscale-operator-longhorn-system = tailscale_operator_config {
          name = "tailscale-operator-longhorn-system";
          namespace = "longhorn-system";
          hostname = "tailscale-operator-longhorn-system";
        };
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
