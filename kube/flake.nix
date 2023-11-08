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

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    nfs-helm,
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
        "nfs-kube" = (kubelib.buildHelmChart {
          name = "nfs-subdir-external-provisioner";
          chart = "${nfs-helm}/charts/nfs-subdir-external-provisioner";
          namespace = "default";
          values = {
            nfs = {
              server = "100.107.238.93";
              path = "/media/virtual-machines/kube";
              volumeName = "nfs-subdir-external-provisioner-root";
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
              name = "nfs-kube";
              annotations = {
                "tailscale.com/tags" = "tag:nfs-client";
              };
            };
            podAnnotations = {
              "tailscale.com/tags" = "tag:nfs-client";
            };
          };
        });
        "nfs-media-disk1" = (kubelib.buildHelmChart {
          name = "nfs-media-disk1";
          chart = "${nfs-helm}/charts/nfs-subdir-external-provisioner";
          namespace = "default";
          values = {
            nfs = {
              server = "100.67.2.30";
              path = "/media/disk1";
              volumeName = "nfs-media-disk1";
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
              name = "nfs-media-disk1";
              annotations = {
                "tailscale.com/tags" = "tag:nfs-client";
              };
            };
            podAnnotations = {
              "tailscale.com/tags" = "tag:nfs-client";
            };
          };
        });
        "nfs-media-disk2" = (kubelib.buildHelmChart {
          name = "nfs-media-disk2";
          chart = "${nfs-helm}/charts/nfs-subdir-external-provisioner";
          namespace = "default";
          values = {
            nfs = {
              server = "100.67.2.30";
              path = "/media/disk2";
              volumeName = "nfs-media-disk2";
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
              name = "nfs-media-disk2";
              annotations = {
                "tailscale.com/tags" = "tag:nfs-client";
              };
            };
            podAnnotations = {
              "tailscale.com/tags" = "tag:nfs-client";
            };
          };
        });
        "1password-connect" = (kubelib.buildHelmChart {
          name = "1password-connect";
          chart = (nixhelm.charts { inherit pkgs; })."1password".connect;
          namespace = "kube-system";
          values = {
            connect.credentials = builtins.readFile /tmp/1password-credentials.json;
          };
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
