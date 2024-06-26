{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, nixos-generators, ... }@attrs:
    # Create system-specific outputs for lima systems
    let
      ful = flake-utils.lib;
    in
    ful.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        # Determine arch for building Linux system
        # i.e. if on MacOS where system will not equal aarch64-linux
        arch = if pkgs.lib.hasInfix "aarch64" "${system}" then "aarch64" else "x86_64";
        linuxSystem = "${arch}-linux";
        nixosImage = nixos-generators.nixosGenerate {
          pkgs = import nixpkgs { system = linuxSystem; };
          modules = [
            ./lima.nix
          ];
          format = "raw-efi";
        };
        imageLocation = if pkgs.stdenv.isLinux then
          "${nixosImage}/nixos.img"
          else
          "https://files.heywoodlh.io/os/nixos-unstable-${arch}.img";
        nixosYaml = pkgs.writeText "nixos.yaml" ''
          arch: "${arch}"
          images:
            - location: "${imageLocation}"
              arch: "${arch}"
          cpus: 2
          mounts:
          - location: "~"
            writable: true
            9p:
              # Try choosing "mmap" or "none" if you see a stability issue with the default "fscache".
              cache: "mmap"
          - location: "/tmp/lima"
            writable: true
            9p:
              cache: "mmap"
          mountType: "9p"
          containerd:
            system: false
            user: false
        '';
      in
      {
        packages = rec {
          img = nixosImage;
          runVm = pkgs.writeShellScriptBin "nixos.sh" ''
            ${pkgs.lima}/bin/limactl start --name=default ${nixosYaml}
          '';
          default = img;
        };
      }) // {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = attrs;
          modules = [
            ./lima.nix
            ./user-config.nix
          ];
        };

        nixosModules.lima = {
          imports = [ ./lima.nix ];
        };
      };
}
