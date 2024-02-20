{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, flake-utils, nixpkgs, nixos-generators, ... }:
  flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    arch = if pkgs.lib.hasInfix "aarch64" "${system}" then "aarch64" else "x86_64";
    linuxSystem = "${arch}-linux";
    nixos-image = nixos-generators.nixosGenerate {
      pkgs = nixpkgs.legacyPackages.${linuxSystem};
      modules = [
        ./configuration.nix
      ];
      format = "raw-efi";
    };
    lima-yml = pkgs.writeText "nixos.yml" ''
      arch: "${arch}"
      images:
      - location: "${nixos-image.outPath}/nixos.img"
        arch: "${arch}"
      cpus: 1
      memory: "2GiB"
      disk: "100GiB"
      mounts:
      - location: "~"
        9p:
          cache: "fscache"
      - location: "/tmp/lima"
        writable: true
        9p:
          cache: "mmap"
      mountType: "9p"
      containerd:
        system: false
        user: false
    '';
  in {
    packages = rec {
      lima-vm = pkgs.writeShellScriptBin "nixos-vm" ''
        ${pkgs.lima}/bin/limactl create --name=nixos ${lima-yml}
      '';
      default = lima-vm;
    };
  });
}
