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
    open-webui = {
      url = "github:open-webui/open-webui";
      flake = false;
    };
    op-scripts.url = "github:heywoodlh/flakes?dir=1password";
    coredns = {
      url = "github:coredns/helm";
      flake = false;
    };
    wazuh = {
      url = "github:wazuh/wazuh-kubernetes/v4.9.0";
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
    open-webui,
    op-scripts,
    coredns,
    wazuh,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      mkKubeDrv = pkgName: args: let
        yaml = pkgs.substituteAll args;
      in pkgs.stdenv.mkDerivation {
        name = pkgName;
        phases = [ "installPhase" ];
        installPhase = ''
          cp ${yaml} $out
        '';
      };
      kubelib = nix-kube-generators.lib { inherit pkgs; };
      ts-env = pkgs.writeShellScriptBin "tsenv" ''
        TS_CLIENT_ID="$(op-wrapper.sh read 'op://Personal/odnjqovwnyxpltktqd3a5yzqpy/password')"
        TS_SECRET="$(op-wrapper.sh read 'op://Personal/qv3mc3sgnpgw6yfuxtgf6xseou/password')"

        echo export TS_CLIENT_ID="$TS_CLIENT_ID"
        echo export TS_SECRET="$TS_SECRET"
      '';
      op-wrapper = op-scripts.packages.${system}.op;
      talos-wrapper = pkgs.writeShellScriptBin "talosctl" ''
        mkdir -p ~/tmp/talos
        item="op://kubernetes/h6d3bdi7yx2kvrk64u2lolva74"

        [[ -e ~/tmp/talos/controlplane.yaml ]] || ${op-wrapper}/bin/op read "$item/controlplane.yaml" > ~/tmp/talos/controlplane.yaml
        [[ -e ~/tmp/talos/talosconfig ]] || ${op-wrapper}/bin/op read "$item/talosconfig" > ~/tmp/talos/talosconfig
        [[ -e ~/tmp/talos/worker.yaml ]] || ${op-wrapper}/bin/op read "$item/worker.yaml" > ~/tmp/talos/worker.yaml
        [[ -e ~/tmp/talos/storage.yaml ]] || ${op-wrapper}/bin/op read "$item/storage.yaml" > ~/tmp/talos/storage.yaml

        ${pkgs.talosctl}/bin/talosctl --talosconfig ~/tmp/talos/talosconfig $@
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
        attic = mkKubeDrv "attic" {
          src = ./templates/attic.yaml;
          namespace = "default";
          replicas = 1;
          image = "docker.io/heywoodlh/attic:4dbdbee45728d8ce5788db6461aaaa89d98081f0";
          nodename = "nix-nvidia";
          hostfolder = "/opt/attic";
        };
        cloudflared = mkKubeDrv "cloudflared" {
          src = ./templates/cloudflared.yaml;
          namespace = "cloudflared";
          image = "docker.io/cloudflare/cloudflared:2024.2.1";
          replicas = 2;
        };
        cloudtube = mkKubeDrv "cloudtube" {
          src = ./templates/cloudtube.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/cloudtube:2024_04";
          second_image = "docker.io/heywoodlh/second:2023_12";
          replicas = 1;
        };
        coder = mkKubeDrv "coder" {
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
        };
        "coredns" = (kubelib.buildHelmChart {
          name = "coredns";
          chart = "${coredns}/charts/coredns";
          namespace = "default";
          values = {
            image = {
              repository = "docker.io/coredns/coredns";
              tag = "1.11.1";
            };
            service = {
              name = "coredns-external";
              clusterIP = "10.96.0.15";
            };
            isClusterService = false;
          };
        });
        drawio = mkKubeDrv "drawio" {
          src = ./templates/draw-io.yaml;
          namespace = "drawio";
          tag = "23.0.0";
          port = "80";
          replicas = "1";
        };
        grafana = mkKubeDrv "grafana" {
          src = ./templates/grafana.yaml;
          namespace = "monitoring";
          image = "docker.io/grafana/grafana:10.3.1";
          storageclass = "longhorn";
        };
        healthchecks = mkKubeDrv "healthchecks" {
          src = ./templates/healthchecks.yaml;
          namespace = "monitoring";
          image = "docker.io/curlimages/curl:8.6.0";
        };
        heralding = mkKubeDrv "heralding" {
          src = ./templates/heralding.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/heralding:1.0.7";
          replicas = 1;
        };
        home-assistant = mkKubeDrv "home-assistant" {
          src = ./templates/home-assistant.yaml;
          namespace = "default";
          timezone = "America/Denver";
          image = "ghcr.io/home-assistant/home-assistant:2024.3.1";
          port = 80;
          replicas = 1;
          nodename = "nix-nvidia";
        };
        iperf = mkKubeDrv "iperf" {
          src = ./templates/iperf3.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/iperf3:3.16-r0";
          replicas = 1;
        };
        jellyfin = mkKubeDrv "jellyfin" {
          src = ./templates/jellyfin.yaml;
          namespace = "default";
          tag = "20231213.1-unstable";
          replicas = 1;
        };
        kubevirt = mkKubeDrv "kubevirt" {
          src = ./templates/kubevirt.yaml;
          version = "v1.2.0";
        };
        longhorn = mkKubeDrv "longhorn" {
          src = ./templates/longhorn.yaml;
          namespace = "longhorn-system";
          version = "1.5.5";
        };
        metrics-server = mkKubeDrv "metrics-server" {
          src = ./templates/metrics-server.yaml;
          image = "registry.k8s.io/metrics-server/metrics-server:v0.7.1";
        };
        minecraft-bedrock = mkKubeDrv "minecraft-bedrock" {
          src = ./templates/minecraft-bedrock.yaml;
          namespace = "default";
          image = "docker.io/itzg/minecraft-bedrock-server:latest";
          nodename = "nix-nvidia";
          hostfolder = "/opt/minecraft-bedrock";
        };
        miniflux = mkKubeDrv "miniflux" {
          src = ./templates/miniflux.yaml;
          namespace = "default";
          image = "docker.io/miniflux/miniflux:2.1.0";
          postgres_image = "docker.io/postgres:15.6";
          postgres_replicas = 1;
          nodename = "nix-nvidia";
          hostfolder = "/opt/miniflux";
          replicas = 1;
        };
        motioneye = mkKubeDrv "motioneye" {
          src = ./templates/motioneye.yaml;
          namespace = "default";
          storageclass = "local-path";
          tag = "dev-amd64";
          replicas = 1;
          port = 80;
          nodename = "nix-nvidia";
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
        ntfy = mkKubeDrv "ntfy" {
          src = ./templates/ntfy.yaml;
          namespace = "default";
          image = "docker.io/binwiederhier/ntfy:v2.9.0";
          base_url = "http://ntfy.barn-banana.ts.net";
          timezone = "America/Denver";
          replicas = 1;
        };
        nuclei = mkKubeDrv "nuclei" {
          src = ./templates/nuclei.yaml;
          namespace = "nuclei";
          image = "docker.io/heywoodlh/nuclei:v3.3.0-dev";
          interactsh_image = "docker.io/projectdiscovery/interactsh-server:v1.1.9";
          httpd_image = "docker.io/httpd:2.4.58";
          replicas = 1;
        };
        open-webui = mkKubeDrv "open-webui" {
          src = ./templates/open-webui.yaml;
          namespace = "open-webui";
          ollama_image = "docker.io/ollama/ollama:0.1.28";
          webui_image = "ghcr.io/open-webui/open-webui:git-1b91e7f";
          hostfolder = "/opt/open-webui";
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
              - job_name: "metrics-server"
                scrape_interval: 2m
                static_configs:
                - targets:
                  - metrics-server.kube-system.svc:443
                tls_config:
                  insecure_skip_verify: true

              - job_name: "node"
                scrape_interval: 2m
                static_configs:
                - targets:
                  - nixos-mac-mini.barn-banana.ts.net:9100
                  - nix-nvidia.barn-banana.ts.net:9100
                  - nix-drive.barn-banana.ts.net:9100
                  - nix-backups.barn-banana.ts.net:9100
                  - nixos-matrix.barn-banana.ts.net:9100
                  - proxmox-mac-mini.barn-banana.ts.net:9100
                  - proxmox-oryx-pro.barn-banana.ts.net:9100
                  - proxmox-nvidia.barn-banana.ts.net:9100
                  - cloud.barn-banana.ts.net:9100
                  - kasmweb.barn-banana.ts.net:9100
            '';
          };
        });
        protonmail-bridge = mkKubeDrv "protonmail-bridge" {
          src = ./templates/protonmail-bridge.yaml;
          namespace = "default";
          image = "docker.io/shenxn/protonmail-bridge:3.12.0-1";
          nodename = "nix-nvidia";
          hostfolder = "/opt/protonmail-bridge";
          replicas = 1;
        };
        redlib = mkKubeDrv "redlib" {
          src = ./templates/redlib.yaml;
          namespace = "default";
          port = 80;
          replicas = 1;
          image = "quay.io/redlib/redlib:latest";
        };
        regexr = mkKubeDrv "regexr" {
          src = ./templates/regexr.yaml;
          namespace = "regexr";
          image = "docker.io/heywoodlh/regexr:1e38271";
          replicas = 1;
        };
        retroarcher = mkKubeDrv "retroarcher" {
          src = ./templates/retroarcher.yaml;
          namespace = "default";
          image = "docker.io/lizardbyte/retroarcher:v2024.210.22900";
          nodename = "nix-nvidia";
          hostfolder = "/opt/retroarcher";
          replicas = 1;
        };
        rsshub = mkKubeDrv "rsshub" {
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
        };
        rustdesk = mkKubeDrv "rustdesk" {
          src = ./templates/rustdesk.yaml;
          namespace = "default";
          image = "docker.io/rustdesk/rustdesk-server:1.1.10-3";
          nodename = "nix-nvidia";
          hostfolder = "/opt/rustdesk";
          replicas = 1;
        };
        squid = mkKubeDrv "squid" {
          src = ./templates/squid.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/squid:5.7";
          nodename = "nix-nvidia";
          hostfolder = "/opt/squid";
          replicas = 1;
        };
        syncthing = mkKubeDrv "syncthing" {
          src = ./templates/syncthing.yaml;
          namespace = "syncthing";
          nodename = "nix-nvidia";
          hostfolder = "/opt/syncthing";
          image = "docker.io/syncthing/syncthing:1.27.4";
          replicas = 1;
        };
        tailscale-operator = mkKubeDrv "tailscale-operator" {
          src = ./templates/tailscale-operator.yaml;
          operator_image = "docker.io/tailscale/k8s-operator:v1.64.2";
          proxy_image = "docker.io/tailscale/tailscale:v1.64.2";
          replicas = 1;
        };
        tor-socks-proxy = mkKubeDrv "tor-socks-proxy" {
          src = ./templates/tor-socks-proxy.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/tor-socks-proxy:0.4.8.12";
          replicas = 1;
        };
        uptime = mkKubeDrv "uptime" {
          src = ./templates/uptime.yaml;
          namespace = "monitoring";
          replicas = 1;
          image = "docker.io/heywoodlh/bash-uptime:0.0.4";
          ntfy_url = "http://ntfy.default/uptime-notifications";
        };
        # Copy certs first: `scp -r nix-nvidia:/opt/wazuh/certs /tmp/certs`
        # Then build with: `nix build .#wazuh --impure`
        wazuh = let
          certs = /tmp/certs;
          finalWazuh = pkgs.stdenv.mkDerivation {
            name = "wazuh-with-certs";
            dontUnpack = true;
            buildPhase = ''
              mkdir -p ./kustomize/wazuh/wazuh-src/wazuh/certs
              cp -rn ${certs}/* ./kustomize/wazuh/wazuh-src/wazuh/certs/
              mkdir -p ./kustomize/wazuh
              cp -rn ${self}/kustomize/wazuh/* ./kustomize/wazuh
              cp -rn ${wazuh}/* ./kustomize/wazuh/wazuh-src
              mkdir -p $out
              cp -r * $out
            '';
          };
        in pkgs.stdenv.mkDerivation {
          name = "wazuh";
          dontUnpack = true;
          buildInputs = with pkgs; [
            git
          ];
          buildPhase = ''
            ${pkgs.kubectl}/bin/kubectl kustomize ${finalWazuh}/kustomize/wazuh > $out
          '';
        };
      };
      devShell = pkgs.mkShell {
        name = "kubernetes-shell";
        buildInputs = with pkgs; [
          k9s
          kubectl
          kubernetes-helm
          talos-wrapper
          ts-env
        ];
      };
      formatter = pkgs.alejandra;
    });
}
