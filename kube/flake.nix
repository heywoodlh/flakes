{
  description = "heywoodlh kubernetes flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    cloudflared-helm = {
      url = "gitlab:kylesferrazza/cloudflared-chart";
      flake = false;
    };
    nfs-helm = {
      url = "github:kubernetes-sigs/nfs-subdir-external-provisioner";
      flake = false;
    };
    nixhelm.url = "github:farcaller/nixhelm";
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
    tailscale.url = "github:tailscale/tailscale";
    longhorn = {
      url = "github:longhorn/longhorn/19e8fefd3ace7fb66c3f3521fc471b60a829b155"; # v1.5.1
      flake = false;
    };
    minecraft-helm = {
      url = "github:itzg/minecraft-server-charts";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    nfs-helm,
    nix-kube-generators,
    nixhelm,
    longhorn,
    tailscale,
    cloudflared-helm,
    minecraft-helm,
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
        cloudflared = (kubelib.buildHelmChart {
          name = "cloudflared";
          chart = "${cloudflared-helm}";
          namespace = "kube-system";
          values = {
            image = {
              repository = "docker.io/cloudflare/cloudflared";
              tag = "2023.10.0";
            };
            existingSecret = "cloudflare-tunnel-auth-secret";
          };
        });
        minecraft-bedrock = (kubelib.buildHelmChart {
          name = "minecraft-bedrock";
          chart = "${minecraft-helm}/charts/minecraft-bedrock";
          namespace = "default";
          values = {
            image = {
              repository = "docker.io/itzg/minecraft-bedrock-server";
              tag = "2023.8.1";
            };
            minecraftServer = {
              eula = "TRUE";
              version = "LATEST";
              difficulty = "hard";
              #whitelist = "user1,user2" ;
              ops = [
                ""
              ];
              maxPlayers = "40";
              tickDistance = "8";
              viewDistance = "20";
              levelName = "heywoodlh world";
              gameMode = "survival";
              serverName = "heywoodlh server";
              enableLanVisibility = "true";
              serverPort = "19132";
            };
            persistence = {
              storageClass = "nfs-kube";
              dataDir = {
                enabled = "true";
                Size = "50Gi";
              };
            };
            serviceAnnotations = {
              "tailscale.com/expose" = true;
              "tailscale.com/hostname" = "minecraft";
              "tailscale.com/tags" = "tag:minecraft";
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
        nfs-kube = (kubelib.buildHelmChart {
          name = "nfs-kube";
          chart = "${nfs-helm}/charts/nfs-subdir-external-provisioner";
          namespace = "default";
          values = {
            image.tag = "v4.0.2";
            nfs = {
              server = "100.107.238.93";
              path = "/media/virtual-machines/kube";
              mountOptions = [
                "rw"
                "bg"
                "hard"
                "rsize=1048576"
                "wsize=1048576"
                "tcp"
                "timeo=600"
              ];
            };
            storageClass = {
              provisionerName = "nfs-kube";
              name = "nfs-kube";
              reclaimPolicy = "Retain";
            };
            podAnnotations = {
              "tailscale.com/tags" = "tag:nfs-client";
            };
          };
        });
        tailscale-operator = tailscale_operator_config {
          name = "tailscale-operator";
          namespace = "kube-system";
          hostname = "tailscale-operator";
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
