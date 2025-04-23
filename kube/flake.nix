{
  description = "heywoodlh kubernetes flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
    crossplane = {
      url = "github:upbound/universal-crossplane/release-1.18";
      flake = false;
    };
    elastic-cloud = {
      url = "github:elastic/cloud-on-k8s/2.15";
      flake = false;
    };
    krew2nix = {
      url = "github:eigengrau/krew2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kasmweb = {
      url = "github:kasmtech/kasm-helm/release/1.16.0";
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
    crossplane,
    elastic-cloud,
    krew2nix,
    kasmweb,
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
          image = "docker.io/heywoodlh/attic:47752427561f1c34debb16728a210d378f0ece36";
        };
        actual = mkKubeDrv "actual" {
          src = ./templates/actual.yaml;
          namespace = "default";
          replicas = 1;
          image = "docker.io/actualbudget/actual-server:25.3.1-alpine";
        };
        # After applying this, run the following: `kubectl apply -f ./kubectl/argo-nix-configmap.yaml`
        argo = (kubelib.buildHelmChart {
          name = "argo";
          chart = (nixhelm.charts { inherit pkgs; }).argoproj.argo-cd;
          namespace = "argo";
          values = {
            repoServer = {
              volumes = [
                {
                  name = "nix-cmp-config";
                  configMap = { name = "nix-cmp-config"; };
                }
                {
                  name = "nix-cmp-tmp";
                  emptyDir = { };
                }
                {
                  name = "nix-cmp-nix";
                  emptyDir = { };
                }
                {
                  name = "nix-cmp-home";
                  emptyDir = { };
                }
              ];
              initContainers = [
                {
                  name = "nix-bootstrap";
                  command = [ "sh" "-c" "cp -a /nix/* /nixvol && chown -R 999 /nixvol/*" ];
                  image = "docker.io/nixos/nix:latest";
                  imagePullPolicy = "Always";
                  volumeMounts = [
                    {
                      mountPath = "/nixvol";
                      name = "nix-cmp-nix";
                    }
                  ];
              }];
              extraContainers = [
                {
                  name = "nix-cmp-plugin";
                  command = [ "/var/run/argocd/argocd-cmp-server" ];
                  image = "docker.io/nixos/nix:latest";
                  imagePullPolicy = "Never";
                  securityContext = {
                    runAsNonRoot = true;
                    runAsUser = 999;
                  };
                  volumeMounts = [
                    {
                      mountPath = "/var/run/argocd";
                      name = "var-files";
                    }
                    {
                      mountPath = "/home/argocd/cmp-server/plugins";
                      name = "plugins";
                    }
                    {
                      mountPath = "/home/argocd/cmp-server/config/plugin.yaml";
                      subPath = "plugin.yaml";
                      name = "nix-cmp-config";
                    }
                    {
                      mountPath = "/etc/passwd";
                      subPath = "passwd";
                      name = "nix-cmp-config";
                    }
                    {
                      mountPath = "/etc/nix/nix.conf";
                      subPath = "nix.conf";
                      name = "nix-cmp-config";
                    }
                    {
                      mountPath = "/tmp";
                      name = "nix-cmp-tmp";
                    }
                    {
                      mountPath = "/nix";
                      name = "nix-cmp-nix";
                    }
                    {
                      mountPath = "/home/nix";
                      name = "nix-cmp-home";
                    }
                  ];
                }
              ];
            };
          };
        });
        atuin = mkKubeDrv "atuin" {
          src = ./templates/atuin.yaml;
          namespace = "default";
          replicas = 1;
          image = "ghcr.io/atuinsh/atuin:v18.4.0";
          postgres_image = "docker.io/postgres:14";
        };
        dev = mkKubeDrv "dev" {
          src = ./templates/dev.yaml;
          namespace = "default";
          replicas = 1;
          image = "docker.io/heywoodlh/dev:2025_04_snapshot";
        };
        cloudflared = mkKubeDrv "cloudflared" {
          src = ./templates/cloudflared.yaml;
          namespace = "cloudflared";
          image = "docker.io/cloudflare/cloudflared:2025.2.1";
          replicas = 2;
        };
        cloudtube = mkKubeDrv "cloudtube" {
          src = ./templates/cloudtube.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/cloudtube:2024_12";
          second_image = "docker.io/heywoodlh/second:2023_12";
          replicas = 1;
        };
        coder = mkKubeDrv "coder" {
          src = ./templates/coder.yaml;
          namespace = "coder";
          version = "2.8.3";
          image = "ghcr.io/coder/coder:v2.20.2";
          access_url = "https://coder.heywoodlh.io";
          replicas = "1";
          port = "80";
          postgres_version = "16.1.0";
          postgres_image = "docker.io/bitnami/postgresql:16.6.0";
          postgres_replicas = "1";
          postgres_storage_class = "local-path";
        };
        coredns = mkKubeDrv "coredns" {
          src = ./templates/coredns.yaml;
          namespace = "coredns";
          image = "docker.io/coredns/coredns:1.12.1";
          replicas = "1";
        };
        "crossplane" = (kubelib.buildHelmChart {
          name = "crossplane";
          chart = "${crossplane}/cluster/charts/universal-crossplane";
          namespace = "upbound-system";
          values = {};
        });
        drawio = mkKubeDrv "drawio" {
          src = ./templates/draw-io.yaml;
          namespace = "drawio";
          tag = "23.0.0";
          port = "80";
          replicas = "1";
        };
        elastic-cloud-operator = (kubelib.buildHelmChart {
          name = "elastic-cloud-operator";
          chart = "${elastic-cloud}/deploy/eck-operator";
          namespace = "monitoring";
          values.image.tag = "2.15.0-bc4";
        });
        elastic-cloud-elastic-stack = mkKubeDrv "elastic-stack" {
          src = ./templates/elastic-stack.yaml;
          namespace = "monitoring";
          version = "8.15.3";
          elasticsearch_nodecount = 1;
          kibana_nodecount = 1;
          storage = "100Gi";
        };
        fleetdm = mkKubeDrv "fleetdm" {
          src = ./templates/fleetdm.yaml;
          namespace = "monitoring";
          image = "docker.io/fleetdm/fleet:c62899e";
          mysql_image = "docker.io/mysql:8.4.4";
          redis_image = "docker.io/redis:8.0-M02-alpine3.21";
          replicas = 1;
        };
        gomuks = mkKubeDrv "gomuks" {
          src = ./templates/gomuks.yaml;
          namespace = "default";
          image = "dock.mau.dev/tulir/gomuks:latest";
          replicas = 1;
        };
        grafana = mkKubeDrv "grafana" {
          src = ./templates/grafana.yaml;
          namespace = "monitoring";
          image = "docker.io/grafana/grafana:11.6.0";
          storageclass = "local-path";
        };
        healthchecks = mkKubeDrv "healthchecks" {
          src = ./templates/healthchecks.yaml;
          namespace = "monitoring";
          image = "docker.io/curlimages/curl:8.12.1";
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
          image = "ghcr.io/home-assistant/home-assistant:2025.3.4";
          port = 80;
          replicas = 1;
          nodename = "nix-nvidia";
        };
        http-files = mkKubeDrv "http-files" {
          src = ./templates/http-files.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/http-files:v2.9.1";
          replicas = 1;
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
        # Create ns first: kubectl create ns kasmweb
        "kasmweb" = (kubelib.buildHelmChart {
          name = "kasmweb";
          chart = "${kasmweb}/kasm-single-zone";
          namespace = "kasmweb";
          values = {
            global = {
              namespace = "kasmweb";
              hostname = "kasmweb";
              altHostnames = [
                "kasm-proxy.kasmweb.svc.cluster.local"
                "kasmweb.heywoodlh.io"
              ];
            };
          };
        });
        kubevirt = mkKubeDrv "kubevirt" {
          src = ./templates/kubevirt.yaml;
          version = "v1.4.0";
        };
        # For whatever reason, Tailscale's 'tailscale.com/tailnet-ip' doesn't seem to work
        # Manually set the IPs in the Tailscale admin UI
        lancache = mkKubeDrv "lancache" {
          src = ./templates/lancache.yaml;
          namespace = "default";
          dns_image = "docker.io/heywoodlh/lancache-dns:latest";
          dns_upstream = "10.43.9.152"; # use coredns, which will work with tailscale and kubernetes
          dns_ip = "100.65.18.5";
          cache_ip = "100.65.18.10";
          cache_disk_size = "1000g";
          cache_index_size = "500m";
          cache_max_age = "3650d";
          cache_hostDir = "/media/data-ssd/lancache/";
          cache_image = "docker.io/lancachenet/monolithic:latest";
          cache_generic = "true";
          timezone = "America/Denver";
          replicas = 1;
          nodename = "nix-nvidia";
        };
        longhorn = mkKubeDrv "longhorn" {
          src = ./templates/longhorn.yaml;
          namespace = "longhorn-system";
          version = "1.5.5";
        };
        metrics-server = mkKubeDrv "metrics-server" {
          src = ./templates/metrics-server.yaml;
          image = "registry.k8s.io/metrics-server/metrics-server:v0.7.2";
        };
        metube = mkKubeDrv "metube" {
          src = ./templates/metube.yaml;
          namespace = "default";
          image = "ghcr.io/alexta69/metube:2024-12-04";
          replicas = 1;
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
          image = "docker.io/miniflux/miniflux:2.2.8";
          postgres_image = "docker.io/postgres:15.12";
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
          image = "docker.io/binwiederhier/ntfy:v2.11.0";
          base_url = "http://ntfy.barn-banana.ts.net";
          timezone = "America/Denver";
          replicas = 1;
        };
        nuclei = mkKubeDrv "nuclei" {
          src = ./templates/nuclei.yaml;
          namespace = "nuclei";
          image = "docker.io/heywoodlh/nuclei:v3.3.0-dev";
          interactsh_image = "docker.io/projectdiscovery/interactsh-server:v1.2.4";
          httpd_image = "docker.io/httpd:2.4.63";
          replicas = 1;
        };
        open-webui = mkKubeDrv "open-webui" {
          src = ./templates/open-webui.yaml;
          namespace = "open-webui";
          webui_image = "ghcr.io/open-webui/open-webui:0.6.5";
          ollama_image = "docker.io/ollama/ollama:0.6.6";
          hostfolder = "/opt/open-webui";
        };
        palworld = mkKubeDrv "palworld" {
          src = ./templates/palworld.yaml;
          namespace = "palworld";
          image = "docker.io/thijsvanloef/palworld-server-docker:v1.3.0";
          hostfolder = "/opt/palworld";
        };
        # Ensure to deploy prometheus-blackbox-exporter first
        prometheus = (kubelib.buildHelmChart {
          name = "prometheus";
          chart = (nixhelm.charts { inherit pkgs; }).prometheus-community.prometheus;
          namespace = "monitoring";
          values = {
            server.image = {
              repository = "quay.io/prometheus/prometheus";
              tag = "v3.2.1";
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
                  - nix-nvidia.barn-banana.ts.net:9100
                  - nix-drive.barn-banana.ts.net:9100
            '';
          };
        });
        prometheus-blackbox-exporter = (kubelib.buildHelmChart {
          name = "prometheus";
          chart = (nixhelm.charts { inherit pkgs; }).prometheus-community.prometheus-blackbox-exporter;
          namespace = "monitoring";
          values = {
            image = {
              registry = "quay.io";
              repository = "prometheus/blackbox-exporter";
              tag = "v0.25.0";
            };
          };
        });
        protonmail-bridge = mkKubeDrv "protonmail-bridge" {
          src = ./templates/protonmail-bridge.yaml;
          namespace = "default";
          image = "docker.io/shenxn/protonmail-bridge:3.18.0-1";
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
          image = "docker.io/lizardbyte/retroarcher:v2024.922.10155";
          nodename = "nix-nvidia";
          hostfolder = "/opt/retroarcher";
          replicas = 1;
        };
        rsshub = mkKubeDrv "rsshub" {
          src = ./templates/rsshub.yaml;
          namespace = "default";
          replicas = 1;
          image = "docker.io/diygod/rsshub:2025-02-19";
          browserless_image = "docker.io/browserless/chrome:1.61-puppeteer-13.1.3";
          browserless_replicas = 1;
          redis_image = "docker.io/redis:7.4.2";
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
        rustdesk-web = mkKubeDrv "rustdesk-web" {
          src = ./templates/rustdesk-web.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/rustdesk-web:1.3.9";
          replicas = 1;
        };
        squid = mkKubeDrv "squid" {
          src = ./templates/squid.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/squid:6.10";
          nodename = "nix-nvidia";
          hostfolder = "/opt/squid";
          replicas = 1;
        };
        syncthing = mkKubeDrv "syncthing" {
          src = ./templates/syncthing.yaml;
          namespace = "syncthing";
          nodename = "nix-nvidia";
          hostfolder = "/opt/syncthing";
          image = "docker.io/syncthing/syncthing:1.29.3";
          replicas = 1;
        };
        # Update nixhelm input for updates
        # Setup secret with this command:
        # nix run .#1password-item -- --name operator-oauth --namespace tailscale --itemPath "vaults/Kubernetes/items/bwmt642lsbd5drsjcrxxnljkku" | kubectl apply -f -
        "tailscale-operator" = (kubelib.buildHelmChart {
          name = "tailscale-operator";
          chart = (nixhelm.charts { inherit pkgs; })."tailscale".tailscale-operator;
          namespace = "tailscale";
          values = {};
        });
        tor-socks-proxy = mkKubeDrv "tor-socks-proxy" {
          src = ./templates/tor-socks-proxy.yaml;
          namespace = "default";
          image = "docker.io/heywoodlh/tor-socks-proxy:0.4.8.13";
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
        whishper = mkKubeDrv "whishper" {
          src = ./templates/whishper.yaml;
          namespace = "default";
          replicas = 1;
          image = "docker.io/pluja/whishper:v3.1.4-gpu";
        };
        # Kubectl wrapper with plugins
        kubectl = let
          kubectl = (krew2nix.packages.${system}.kubectl.withKrewPlugins (plugins: [
            plugins.krew
          ]));
        in pkgs.writeShellScriptBin "kubectl" ''
          PATH="$HOME/.krew/bin:$PATH" ${kubectl}/bin/kubectl "$@";
        '';
      };
      devShell = pkgs.mkShell {
        name = "kubernetes-shell";
        buildInputs = with pkgs; [
          argocd
          k9s
          kubectl
          kubernetes-helm
          kubevirt
          talos-wrapper
          ts-env
        ];
      };
      formatter = pkgs.alejandra;
    });
}
