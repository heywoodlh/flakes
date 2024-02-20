{ config, modulesPath, pkgs, lib, ... }:
{
    imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
        ./lima-init.nix
    ];

    # ssh
    services.openssh = {
      enable = true;
      settings.PermitRootLogin = lib.mkForce "yes";
    };
    users.users.root.password = "nixos";

    security = {
      sudo.wheelNeedsPassword = false;
    };

    # system mounts
    boot.loader.grub = {
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
      options = [ "noatime" "nodiratime" "discard" ];
    };

    # misc
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # pkgs
    environment.systemPackages = with pkgs; [
      vim
    ];
}
