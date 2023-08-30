{
  description = "heywoodlh git config";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.vim-flake.url = "github:heywoodlh/flakes?dir=vim";

  outputs = { self, nixpkgs, flake-utils, vim-flake, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        vim = vim-flake.defaultPackage.${system};
        onepassword_path = if pkgs.stdenv.isDarwin then
        "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else
        "/home/heywoodlh/.nix-profile/bin/op-ssh-sign";
        onepassword_config = ''
[gpg "ssh"]
  program = "${onepassword_path}"

[commit]
  gpgsign = "true"

[user]
  signingkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCYn+7oSNHXN3qqDDidw42Vv7fDS0iEpYqaa0wCXRPBlfWAnD81f6dxj/QPGfZtxpl9jvk7nAKpE7RVUvQiJzUC2VM3Bw/4ucT+xliEHo3oesMQQa1AT70VPTbP5PdU7oUpgQWLq39j9XHno2YPJ/WWtuOl/UTjY6IDokkAmNmvft/jqqkiwSkGMmw68qrLFEM7+rNwJV5cXKvvpB6Gqc7qnbJmk1TZ1MRGW5eLjP9ofDqiyoLbnTm7Dw3iHn40GgTcnv5CWGpa0vrKnnLEGrgRB7kR/pyvfsjapkHz0PDvuinQov+MgJfV8B8PHdPC94dsS0DEWJplxhYojtsYa1VZy5zTEMNWICz1QG1yKHN1JQtpbEreHG6DVYvqwnKvK/XN5yiEeiamhD2oKnSh36PexIR0h0AAPO29Ln+anqpRlqJ0nET2CNS04e0vpV4VDJrG6BnyGUQ6CCo7THSq97F4Ne0nY9fpYu5WTFTCh1tTm+nSey0fP/xk22oINl/41VTI/Vk5pNQuuhHUvQupJHw9cD74aKzRddwvgfuAQjPlEuxxsqgFTltTiPF6lZQNeoMIc1OMCRsnl1xNqIepnb7Q5O1CGq+BqtOWh3G4/SPQI5ZUIkOAZegsnPpGWYMrRd7s6LJn5LrBYaY6IvRxmpGOig3tjOUy3fqk7coyTeJXmQ=="
        '';
        gitconfig = pkgs.writeText "gitconfig" ''
[color]
  ui = "auto"

[core]
  autocrlf = "input"
  editor = "${vim}/bin/vim"
  pager = "${pkgs.less}/bin/less -+F"
  whitespace = "cr-at-eol"

[diff]
  renames = "copies"

[format]
  pretty = "%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd) %C(bold blue)<%an>%Creset"

[merge]
  conflictstyle = "diff3"
  tool = "${pkgs.vim}/bin/vimdiff"

[mergetool]
  prompt = "true"

[pull]
  ff = "only"

[push]
  default = "simple"

[user]
  email = "github@heywoodlh.io"
  name = "Spencer Heywood"

[include]
  path = ~/.gitconfig
  path = ~/.config/git/config

${onepassword_config}
        '';
      in {
        packages = rec {
          git = pkgs.writeShellScriptBin "git" ''
            export GIT_CONFIG_GLOBAL=${gitconfig}
            ${pkgs.git}/bin/git $@
          '';
          default = git;
        };
      }
    );
}
