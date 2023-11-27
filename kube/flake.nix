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
      ts-env = pkgs.writeShellScriptBin "tsenv" ''
        TS_CLIENT_ID="$(op-wrapper.sh read 'op://Personal/odnjqovwnyxpltktqd3a5yzqpy/password')"
        TS_SECRET="$(op-wrapper.sh read 'op://Personal/qv3mc3sgnpgw6yfuxtgf6xseou/password')"

        echo export TS_CLIENT_ID="$TS_CLIENT_ID"
        echo export TS_SECRET="$TS_SECRET"
      '';
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
          namespace = "cloudflared";
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
              tag = "latest";
              pullPolicy = "Always";
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
            };
            storageClass = {
              provisionerName = "nfs-kube";
              name = "nfs-kube";
              reclaimPolicy = "Retain";
            };
            podAnnotations = {
              "tailscale.com/tags" = "tag:nfs-client";
              "tailscale.com/expose" = "true";
            };
            nodeSelector = {
              "env" = "home";
            };
          };
        });
        tailscale-operator = (kubelib.buildHelmChart {
          name = "tailscale-operator";
          chart = "${tailscale}/cmd/k8s-operator/deploy/chart";
          namespace = "tailscale";
          values = {
            operatorConfig = {
              image = {
                repo = "docker.io/tailscale/k8s-operator";
                tag = "v1.54.0";
              };
              hostname = "tailscale-operator";
              logging = "info";
            };
            oauth = {
              clientId = "\"" + builtins.getEnv "TS_CLIENT_ID" + "\"";
              clientSecret = "\"" + builtins.getEnv "TS_SECRET" + "\"";
            };
            proxyConfig = {
              image = {
                repo = "docker.io/tailscale/tailscale";
                tag = "v1.54.0";
              };
              defaultTags = "tag:k8s";
            };
            apiServerProxyConfig.mode = "true";
          };
        });
      };
      devShell = pkgs.mkShell {
        name = "kubernetes-shell";
        buildInputs = with pkgs; [
          k0sctl
          k9s
          kubectl
          kubernetes-helm
          ts-env
        ];
      };
      formatter = pkgs.alejandra;
    });
}
