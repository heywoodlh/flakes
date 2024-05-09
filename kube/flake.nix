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
    open-webui = {
      url = "github:open-webui/open-webui";
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
    open-webui,
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
            # op connect server create k3s-cluster --vaults Kubernetes && mv 1password-credentials.json /tmp/
            connect.credentials = builtins.readFile /tmp/1password-credentials.json;
            operator = {
              create = true;
              # op connect token create --server k3s-cluster --vault Kubernetes k3s-cluster > /tmp/token.txt
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
              repository = "ghcr.io/actions/gha-runner-scale-set-controller";
              tag = "0.8.3";
            };
            #kubectl create ns actions-runner
            #nix run .#1password-item -- --name github-token --namespace actions-runner --itemPath "vaults/Kubernetes/items/d54zu5ohvjkd2fou7rh2rrhnee" | kubectl apply -f -
            githubConfigSecret = "github-token";
          };
        });
        actions-runner-flakes = (kubelib.buildHelmChart {
          name = "actions-runner-flakes";
          chart = "${github-actions-runner-helm}/charts/gha-runner-scale-set";
          namespace = "actions";
          values = {
            githubConfigUrl = "https://github.com/heywoodlh/flakes";
            #kubectl create ns actions
            #nix run .#1password-item -- --name github-token --namespace actions --itemPath "vaults/Kubernetes/items/d54zu5ohvjkd2fou7rh2rrhnee" | kubectl apply -f -
            githubConfigSecret = "github-token";
            controllerServiceAccount = {
              name = "actions-runner-controller-gha-rs-controller";
              namespace = "actions-runner";
            };
            containerMode = {
              type = "kubernetes";
              kubernetesModeWorkVolumeClaim = {
                accessModes = ["ReadWriteOnce"];
                storageClassName = "local-path";
                resources.requests.storage = "50Gi";
              };
            };
            template.spec.containers = [
              {
                name = "runner";
                image = "ghcr.io/actions/actions-runner:2.314.1";
                imagePullPolicy = "Always";
                command = ["/home/runner/run.sh"];
                env = [
                {
                  name = "ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER";
                  value = "false";
                }
                {
                  name = "ACTIONS_RUNNER_CONTAINER_HOOK_TEMPLATE";
                  value = "/home/runner/pod-template.yaml";
                }
                ];
                resources = {
                  requests = {
                    memory = "200Mi";
                    cpu = "250m";
                  };
                  limits = {
                    memory = "400Mi";
                    cpu = "500m";
                  };
                };
              }
            ];
          };
        });
        attic = let
          yaml = pkgs.substituteAll ({
            src = ./templates/attic.yaml;
            namespace = "default";
            replicas = 1;
            image = "docker.io/heywoodlh/attic:4dbdbee45728d8ce5788db6461aaaa89d98081f0";
            nodename = "nix-nvidia";
            hostfolder = "/opt/attic";
          });
        in pkgs.stdenv.mkDerivation {
          name = "attic";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        cloudflared = let
          yaml = pkgs.substituteAll ({
            src = ./templates/cloudflared.yaml;
            namespace = "cloudflared";
            image = "docker.io/cloudflare/cloudflared:2024.2.1";
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
            image = "docker.io/heywoodlh/cloudtube:2024_04";
            second_image = "docker.io/heywoodlh/second:2023_12";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "cloudtube";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        coder = let
          yaml = pkgs.substituteAll ({
            src = ./templates/coder.yaml;
            namespace = "coder";
            version = "2.8.3";
            image = "ghcr.io/coder/coder:v2.8.4";
            access_url = "https://coder.heywoodlh.io";
            replicas = "1";
            port = "80";
            postgres_version = "16.1.0";
            postgres_image = "docker.io/bitnami/postgresql:16.2.0";
            postgres_replicas = "1";
            postgres_storage_class = "local-path";
          });
        in pkgs.stdenv.mkDerivation {
          name = "coder";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        dns-autoscaler = let
          yaml = pkgs.substituteAll ({
            src = ./templates/dns-autoscaler.yaml;
            image = "registry.k8s.io/cpa/cluster-proportional-autoscaler:v1.8.9";
          });
        in pkgs.stdenv.mkDerivation {
          name = "dns-autoscaler";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        drawio = let
          yaml = pkgs.substituteAll ({
            src = ./templates/draw-io.yaml;
            namespace = "drawio";
            tag = "23.0.0";
            port = "80";
            replicas = "1";
          });
        in pkgs.stdenv.mkDerivation {
          name = "drawio";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        grafana = let
          yaml = pkgs.substituteAll ({
            src = ./templates/grafana.yaml;
            namespace = "monitoring";
            image = "docker.io/grafana/grafana:10.3.1";
            storageclass = "local-path";
          });
        in pkgs.stdenv.mkDerivation {
          name = "grafana";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        healthchecks = let
          yaml = pkgs.substituteAll ({
            src = ./templates/healthchecks.yaml;
            namespace = "monitoring";
            image = "docker.io/curlimages/curl:8.6.0";
          });
        in pkgs.stdenv.mkDerivation {
          name = "healthchecks";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        heralding = let
          yaml = pkgs.substituteAll ({
            src = ./templates/heralding.yaml;
            namespace = "default";
            image = "docker.io/heywoodlh/heralding:1.0.7";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "heralding";
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
            image = "ghcr.io/home-assistant/home-assistant:2024.3.1";
            port = 80;
            storageClass = "nfs-kube";
            replicas = 1;
            nodename = "nix-nvidia";
          });
        in pkgs.stdenv.mkDerivation {
          name = "home-assistant";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        iperf = let
          yaml = pkgs.substituteAll ({
            src = ./templates/iperf3.yaml;
            namespace = "default";
            image = "docker.io/heywoodlh/iperf3:3.16-r0";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "iperf";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
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
        kubevirt = let
          yaml = pkgs.substituteAll ({
            src = ./templates/kubevirt.yaml;
            version = "v1.2.0";
          });
        in pkgs.stdenv.mkDerivation {
          name = "kubevirt";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
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
        minecraft-bedrock = let
          yaml = pkgs.substituteAll ({
            src = ./templates/minecraft-bedrock.yaml;
            namespace = "default";
            image = "docker.io/itzg/minecraft-bedrock-server:latest";
            nodename = "nix-nvidia";
            hostfolder = "/opt/minecraft-bedrock";
          });
        in pkgs.stdenv.mkDerivation {
          name = "minecraft-bedrock";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        miniflux = let
          yaml = pkgs.substituteAll ({
            src = ./templates/miniflux.yaml;
            namespace = "default";
            image = "docker.io/miniflux/miniflux:2.1.0";
            postgres_image = "docker.io/postgres:15.6";
            postgres_replicas = 1;
            nodename = "nix-nvidia";
            hostfolder = "/opt/miniflux";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "miniflux";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        motioneye = let
          yaml = pkgs.substituteAll ({
            src = ./templates/motioneye.yaml;
            namespace = "default";
            storageclass = "local-path";
            tag = "dev-amd64";
            replicas = 1;
            port = 80;
            nodename = "nix-nvidia";
          });
        in pkgs.stdenv.mkDerivation {
          name = "motioneye";
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
        ntfy = let
          yaml = pkgs.substituteAll ({
            src = ./templates/ntfy.yaml;
            namespace = "default";
            image = "docker.io/binwiederhier/ntfy:v2.9.0";
            nodename = "nix-nvidia";
            hostfolder = "/opt/ntfy";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "ntfy";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        nuclei = let
          yaml = pkgs.substituteAll ({
            src = ./templates/nuclei.yaml;
            namespace = "nuclei";
            image = "docker.io/heywoodlh/nuclei:v3.2.0-dev";
            interactsh_image = "docker.io/projectdiscovery/interactsh-server:v1.1.9";
            httpd_image = "docker.io/httpd:2.4.58";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "nuclei";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        open-webui = let
          yaml = pkgs.substituteAll ({
            src = ./templates/open-webui.yaml;
            namespace = "open-webui";
            ollama_image = "docker.io/ollama/ollama:0.1.28";
            webui_image = "ghcr.io/open-webui/open-webui:git-1b91e7f";
            hostfolder = "/opt/open-webui";
          });
        in pkgs.stdenv.mkDerivation {
          name = "open-webui";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        prometheus = (kubelib.buildHelmChart {
          name = "prometheus";
          chart = (nixhelm.charts { inherit pkgs; }).prometheus-community.prometheus;
          namespace = "monitoring";
          values = {
            server.image = {
              repository = "quay.io/prometheus/prometheus";
              tag = "v2.50.1";
            };
            prometheus-node-exporter.enabled = false;
            extraScrapeConfigs = ''
              - job_name: "node"
                scrape_interval: 2m
                static_configs:
                - targets:
                  - nixos-mac-mini:9100
                  - nix-nvidia:9100
                  - nix-drive:9100
                  - nix-backups:9100
                  - nixos-matrix:9100
                  - proxmox-mac-mini:9100
                  - cloud:9100
                  - kasmweb:9100
            '';
          };
        });
        protonmail-bridge = let
          yaml = pkgs.substituteAll ({
            src = ./templates/protonmail-bridge.yaml;
            namespace = "default";
            image = "docker.io/heywoodlh/hydroxide:2024_03";
            nodename = "nix-nvidia";
            hostfolder = "/opt/hydroxide";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "protonmail-bridge";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        redlib = let
          yaml = pkgs.substituteAll ({
            src = ./templates/redlib.yaml;
            namespace = "default";
            port = 80;
            replicas = 1;
            image = "quay.io/redlib/redlib:latest";
          });
        in pkgs.stdenv.mkDerivation {
          name = "teddit";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        regexr = let
          yaml = pkgs.substituteAll ({
            src = ./templates/regexr.yaml;
            namespace = "regexr";
            image = "docker.io/heywoodlh/regexr:1e38271";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "regexr";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        retroarcher = let
          yaml = pkgs.substituteAll ({
            src = ./templates/retroarcher.yaml;
            namespace = "default";
            image = "docker.io/lizardbyte/retroarcher:v2024.210.22900";
            nodename = "nix-nvidia";
            hostfolder = "/opt/retroarcher";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "rustdesk";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        rsshub = let
          yaml = pkgs.substituteAll ({
            src = ./templates/rsshub.yaml;
            namespace = "default";
            replicas = 1;
            image = "docker.io/diygod/rsshub:2024-02-19";
            browserless_image = "docker.io/browserless/chrome:1.61-puppeteer-13.1.3";
            browserless_replicas = 1;
            redis_image = "docker.io/redis:7.2.4";
            redis_replicas = 1;
            nodename = "nix-nvidia";
            hostfolder = "/opt/rsshub";
          });
        in pkgs.stdenv.mkDerivation {
          name = "rsshub";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        rustdesk = let
          yaml = pkgs.substituteAll ({
            src = ./templates/rustdesk.yaml;
            namespace = "default";
            image = "docker.io/rustdesk/rustdesk-server:1.1.10-3";
            nodename = "nix-nvidia";
            hostfolder = "/opt/rustdesk";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "rustdesk";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        squid = let
          yaml = pkgs.substituteAll ({
            src = ./templates/squid.yaml;
            namespace = "default";
            image = "docker.io/heywoodlh/squid:5.7";
            nodename = "nix-nvidia";
            hostfolder = "/opt/squid";
            replicas = 1;
          });
        in pkgs.stdenv.mkDerivation {
          name = "squid";
          phases = [ "installPhase" ];
          installPhase = ''
            cp ${yaml} $out
          '';
        };
        syncthing = let
          yaml = pkgs.substituteAll ({
            src = ./templates/syncthing.yaml;
            namespace = "syncthing";
            nodename = "nix-nvidia";
            hostfolder = "/opt/syncthing";
            image = "docker.io/syncthing/syncthing:1.27.4";
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
          # oauth configured with this command
          # nix run .#1password-item -- --name operator-oauth --namespace tailscale --itemPath "vaults/Kubernetes/items/h64xxdshrse2jto2nkdo6nerp4" | kubectl apply -f -
          values = {
            operatorConfig = {
              image = {
                repo = "docker.io/tailscale/k8s-operator";
                tag = "unstable-v1.55.68";
              };
              hostname = "tailscale-operator";
              logging = "debug";
            };
            proxyConfig = {
              image = {
                repo = "docker.io/tailscale/tailscale";
                tag = "unstable-v1.55.68";
              };
              defaultTags = "tag:k8s";
            };
            apiServerProxyConfig.mode = "true";
          };
        });
        uptime = let
          yaml = pkgs.substituteAll ({
            src = ./templates/uptime.yaml;
            namespace = "monitoring";
            replicas = 1;
            image = "docker.io/heywoodlh/bash-uptime:0.0.4";
            ntfy_url = "http://ntfy.default/uptime-notifications";
          });
        in pkgs.stdenv.mkDerivation {
          name = "uptime";
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
