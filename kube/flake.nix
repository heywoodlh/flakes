{
  description = "heywoodlh kubernetes flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    cloudflared-helm = {
      url = "github:cloudflare/helm-charts";
      flake = false;
    };
    nfs-helm = {
      url = "github:kubernetes-sigs/nfs-subdir-external-provisioner";
      flake = false;
    };
    nixhelm.url = "github:farcaller/nixhelm";
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
    tailscale.url = "github:tailscale/tailscale";
    minecraft-helm = {
      url = "github:itzg/minecraft-server-charts";
      flake = false;
    };
    truecharts-helm = {
      url = "github:truecharts/charts";
      flake = false;
    };
    github-actions-runner-helm = {
      url = "github:actions/actions-runner-controller";
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
    tailscale,
    cloudflared-helm,
    minecraft-helm,
    truecharts-helm,
    github-actions-runner-helm,
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
      cf-env = pkgs.writeShellScriptBin "cfenv" ''
        TS_CLIENT_ID="$(op-wrapper.sh read 'op://Personal/odnjqovwnyxpltktqd3a5yzqpy/password')"
        TS_SECRET="$(op-wrapper.sh read 'op://Personal/qv3mc3sgnpgw6yfuxtgf6xseou/password')"

        echo export TS_CLIENT_ID="$TS_CLIENT_ID"
        echo export TS_SECRET="$TS_SECRET"
      '';
      onepassworditem = pkgs.writers.writePython3Bin "onepassitem.py" { libraries = [ pkgs.python3Packages.PyGithub ]; } ''
      import argparse

      parser = argparse.ArgumentParser(description="Create a OnePasswordItem")
      parser.add_argument("--name", help="Name of secret", required=True)
      parser.add_argument("--namespace", help="Namespace", required=True)
      parser.add_argument("--itemPath", help="Path of item", required=True)

      args = parser.parse_args()

      item = """
      ---
      apiVersion: onepassword.com/v1
      kind: OnePasswordItem
      metadata:
        name: "{0}"
        namespace: "{1}"
      spec:
        itemPath: "{2}"
      """

      print(item.format(args.name, args.namespace, args.itemPath))
      '';
    in {
      packages = {
        "1password-connect" = (kubelib.buildHelmChart {
          name = "1password-connect";
          chart = (nixhelm.charts { inherit pkgs; })."1password".connect;
          namespace = "kube-system";
          values = {
            # op connect server create k0s-cluster --vaults Kubernetes && mv 1password-credentials.json /tmp/
            connect.credentials = builtins.readFile /tmp/1password-credentials.json;
            operator = {
              create = true;
              # op connect token create --server k0s-cluster --vault Kubernetes k0s-cluster > /tmp/token.txt
              token.value = builtins.readFile /tmp/token.txt;
              # Automatically restart the operator if secrets are updated
              autoRestart = true;
            };
          };
        });
        "1password-item" = onepassworditem;
        # apply with: kubectl apply -f ./result --server-side
        actions-runner-controller = (kubelib.buildHelmChart {
          name = "actions-runner-controller";
          chart = "${github-actions-runner-helm}/charts/gha-runner-scale-set-controller";
          namespace = "actions-runner";
          values = {
            image = {
              tag = "0.7.0";
            };
            githubConfigSecret = "controller-manager";
          };
        });
        actions-runner-flakes = (kubelib.buildHelmChart {
          name = "actions-runner-flakes";
          chart = "${github-actions-runner-helm}/charts/gha-runner-scale-set";
          namespace = "actions";
          values = {
            githubConfigUrl = "https://github.com/heywoodlh/flakes";
            githubConfigSecret = "github-token";
            controllerServiceAccount = {
              name = "actions-runner-controller-gha-rs-controller";
              namespace = "actions-runner";
            };
          };
        });
        cloudflared = let
          yaml = pkgs.substituteAll ({
            src = ./templates/cloudflared.yaml;
            namespace = "cloudflared";
            tag = "2023.10.0";
            replicas = 2;
          });
        in pkgs.stdenv.mkDerivation {
          name = "cloudflared";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        cloudtube = let
          yaml = pkgs.substituteAll ({
            src = ./templates/cloudtube.yaml;
            namespace = "default";
            tag = "2023_10";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "cloudtube";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        home-assistant = let
          yaml = pkgs.substituteAll ({
            src = ./templates/home-assistant.yaml;
            namespace = "default";
            timezone = "America/Denver";
            tag = "2023.11.3";
            servicePort = 80;
            storageClass = "nfs-kube";
            replicas = 1;
            nodename = "k8s-node-2";
          });
        in pkgs.stdenv.mkDerivation {
          name = "home-assistant";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
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
              difficulty = "normal";
              #whitelist = "user1,user2" ;
              ops = [
                "2533274841530057"
              ];
              maxPlayers = "40";
              tickDistance = "8";
              viewDistance = "20";
              levelName = "heywoodlh world";
              gameMode = "survival";
              serverName = "heywoodlh server";
              enableLanVisibility = "true";
              cheats = "true";
              serverPort = "19132";
            };
            persistence = {
              storageClass = "longhorn";
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
        longhorn = let
          yaml = pkgs.substituteAll ({
            src = ./templates/longhorn.yaml;
            namespace = "longhorn-system";
            version = "1.5.3";
          });
        in pkgs.stdenv.mkDerivation {
          name = "longhorn";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        media-server = let
          yaml = pkgs.substituteAll ({
            src = ./templates/media-server.yaml;
            namespace = "default";
          });
        in pkgs.stdenv.mkDerivation {
          name = "media-server";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
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
        jellyfin = let
          yaml = pkgs.substituteAll ({
            src = ./templates/jellyfin.yaml;
            namespace = "default";
            tag = "20231213.1-unstable";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "jellyfin";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        second = let
          yaml = pkgs.substituteAll ({
            src = ./templates/second.yaml;
            namespace = "default";
            tag = "2023_12";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "second";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        syncthing = let
          yaml = pkgs.substituteAll ({
            src = ./templates/syncthing.yaml;
            namespace = "syncthing";
            tag = "1.27.1";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "syncthing";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        tailscale-operator = (kubelib.buildHelmChart {
          name = "tailscale-operator";
          chart = "${tailscale}/cmd/k8s-operator/deploy/chart";
          namespace = "tailscale";
          values = {
            operatorConfig = {
              image = {
                repo = "docker.io/tailscale/k8s-operator";
                tag = "unstable-v1.55.68";
              };
              hostname = "tailscale-operator";
              logging = "debug";
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
        teddit = let
          yaml = pkgs.substituteAll ({
            src = ./templates/teddit.yaml;
            domain = "teddit.heywoodlh.io";
            namespace = "default";
            port = 80;
            replicas = 1;
            redis_tag = "7.2.3";
            redis_replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "teddit";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
      };
      devShell = pkgs.mkShell {
        name = "kubernetes-shell";
        buildInputs = with pkgs; [
          k0sctl
          k9s
          kubectl
          kubernetes-helm
          cf-env
          ts-env
        ];
      };
      formatter = pkgs.alejandra;
    });
}
