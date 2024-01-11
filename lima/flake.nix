{
  description = "heywoodlh lima flake";

  inputs.nixpkgs-master.url = "github:nixos/nixpkgs/master";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.myFlakes.url = "github:heywoodlh/flakes";

  outputs = { self, nixpkgs, nixpkgs-master, flake-utils, myFlakes, }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-master = import nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };

      ubuntu-template = pkgs.writeText "ubuntu-nix.yaml" ''
        images:
        - location: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
          arch: "x86_64"
        - location: "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-arm64.img"
          arch: "aarch64"

        mounts:
        - location: "~"
          writable: true
        - location: "/tmp/lima"
          writable: true

        provision:
        - mode: system
          script: |
            #!/bin/sh
            sed -i 's/host.lima.internal.*/host.lima.internal host.docker.internal/' /etc/hosts
        - mode: system
          script: |
            #!/bin/bash
            set -eux -o pipefail
            command -v docker >/dev/null 2>&1 && exit 0
            export DEBIAN_FRONTEND=noninteractive
            curl -fsSL https://get.docker.com | sh
            # NOTE: you may remove the lines below, if you prefer to use rootful docker, not rootless
            systemctl disable --now docker
            apt-get install -y uidmap dbus-user-session
        - mode: user
          script: |
            #!/bin/bash
            set -eux -o pipefail
            # Rootless docker
            systemctl --user start dbus
            dockerd-rootless-setuptool.sh install
            docker context use rootless
            # Nix setup
            curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
            source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            # Flakes setup
            nix profile install --no-write-lock-file \
              github:heywoodlh/flakes#tmux \
              github:heywoodlh/flakes#vim \
              github:heywoodlh/flakes#git \
              github:heywoodlh/flakes#op \
              github:nixos/nixpkgs#openssh
            # Shell setup
            mkdir -p $HOME/.config/fish && touch $HOME/.config/fish/config.fish
            sudo ln -s $HOME/.nix-profile/bin/tmux /usr/local/bin/tmux
            echo "[ -z \$TMUX ] && { $HOME/.nix-profile/bin/tmux attach || exec $HOME/.nix-profile/bin/tmux new-session && exit;}" | sudo tee /tmux.sh
            sudo chmod +x /tmux.sh
            mkdir -p $HOME/bin
            echo "op read 'op://Personal/uwxs2btf3eoweg4phzag2hfkge/private_key' | $HOME/.nix-profile/bin/ssh-add -t 4h -" > $HOME/bin/ssh-unlock
            printf 'eval ($HOME/.nix-profile/bin/ssh-agent -c) &>/dev/null' >> $HOME/.config/fish/config.fish
            chmod +x $HOME/bin/ssh-unlock
      '';
      # Use vz on macOS
      extra-args = if pkgs.stdenv.isDarwin then "--vm-type=vz" else "";
      limactl = "${pkgs-master.lima-bin}/bin/limactl";
    in {
      packages = rec {
        ubuntu-vm = pkgs.writeShellScriptBin "ubuntu-vm" ''
          vm_status="Not running"
          ${limactl} list | grep ubuntu-nix | grep -q Running && vm_status="Running"
          if [[ $vm_status != "Running" ]]
          then
            ${limactl} start ${ubuntu-template} --name=ubuntu-nix --tty=false ${extra-args}
          fi
          ${limactl} shell ubuntu-nix /tmux.sh
        '';
        default = ubuntu-vm;
        };
      }
    );
}
