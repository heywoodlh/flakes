{
  description = "heywoodlh vscode config";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  inputs.vscode-config = {
    url = "gitlab:kylesferrazza/vscode-config/a85e9023";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.fish-flake = {
    url = "github:heywoodlh/flakes?dir=fish";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{
    self,
    nixpkgs,
    flake-utils,
    nix-vscode-extensions,
    vscode-config,
    fish-flake,
  }:
  flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      mkVSCode = vscode-config.mkVSCode.${system};

      allExtensions = nix-vscode-extensions.extensions.${system};
      myfish = fish-flake.packages.${system}.fish;
      fishProfile = {
        "fish" = {
          "path" = "${myfish}/bin/fish";
        };
      };
      vscode-settings = {
        # Privacy/telemetry settings
        "Lua.telemetry.enable" = false;
        "clangd.checkUpdates" = false;
        "code-runner.enableAppInsights" = false;
        "docker-explorer.enableTelemetry" = false;
        "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', 'monospace', 'Droid Sans Mono', 'monospace', 'Droid Sans Fallback'";
        "extensions.ignoreRecommendations" = true;
        "gitlens.showWelcomeOnInstall" = false;
        "gitlens.showWhatsNewAfterUpgrades" = false;
        "java.help.firstView" = "none";
        "java.help.showReleaseNotes" = false;
        "julia.enableTelemetry" = false;
        "kite.showWelcomeNotificationOnStartup" = false;
        "liveServer.settings.donotShowInfoMsg" = true;
        "material-icon-theme.showWelcomeMessage" = false;
        "pros.showWelcomeOnStartup" = false;
        "pros.useGoogleAnalytics" = false;
        "redhat.telemetry.enabled" = false;
        "remote.SSH.useLocalServer" = false;
        "rpcServer.showStartupMessage" = false;
        "shellcheck.disableVersionCheck" = true;
        "sonarlint.disableTelemetry" = true;
        "telemetry.enableCrashReporter" = false;
        "telemetry.enableTelemetry" = false;
        "telemetry.telemetryLevel" = "off";
        "terraform.telemetry.enabled" = false;
        "update.showReleaseNotes" = false;
        "vsicons.dontShowNewVersionMessage" = true;
        "workbench.welcomePage.walkthroughs.openOnInstall" = false;
        # Appearance settings
        "editor.minimap.enabled" = false;
        "update.mode" = "none";
        "workbench.activityBar.location" = "hidden";
        "workbench.colorTheme" = "Nord";
        "workbench.remoteIndicator.showExtensionRecommendations" = false;
        "workbench.startupEditor" = false;
        "workbench.statusBar.visible" = false;
        "workbench.tips.enabled" = false;
        "workbench.tree.indent" = 4;
        # Terminal settings
        "terminal.integrated.macOptionIsMeta" = true;
        "terminal.integrated.shellIntegration.enabled" = true;
        "terminal.integrated.profiles.linux" = fishProfile;
        "terminal.integrated.profiles.osx" = fishProfile;
        "terminal.integrated.defaultProfile.linux" = "fish";
        "terminal.integrated.defaultProfile.osx" = "fish";
        # Vim settings
        "vim.shell" = "${pkgs.bash}/bin/bash";
        "vim.useSystemClipboard" = true;
        # Misc settings
        "git.openRepositoryInParentFolders" = "always";
        "security.workspace.trust.enabled" = false;
        "task.allowAutomaticTasks" = "off";
        "direnv.path.executable" = "${pkgs.direnv}/bin/direnv";
      };

      extensionList = with allExtensions.vscode-marketplace; [
        arcticicestudio.nord-visual-studio-code
        coder.coder-remote
        eamodio.gitlens
        github.codespaces
        github.copilot
        jnoortheen.nix-ide
        mkhl.direnv
        ms-azuretools.vscode-docker
        ms-kubernetes-tools.vscode-kubernetes-tools
        ms-python.python
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        timonwong.shellcheck
        vscodevim.vim
      ];

      heywoodlh-vscode = mkVSCode {
        settings = vscode-settings;
        extensions = extensionList;
      };
      extensionCount = builtins.toString(builtins.length extensionList);
      exportJson = object: output: pkgs.writeText "${output}" (builtins.toJSON object);
      vscodeSettingsJson = exportJson vscode-settings "settings.json";
      printSettings = pkgs.writeShellScript "print-settings" ''
        # Remove references to nix and fish
        cat ${vscodeSettingsJson} | ${pkgs.jq}/bin/jq '.' | ${pkgs.gnused}/bin/sed 's|/nix/store.*/bin/\(.*\)|\1|' | ${pkgs.gnused}/bin/sed 's/fish/bash/g'
      '';
      printExtensions = pkgs.writeShellScript "print-extensions" ''
        PATH=${pkgs.bash}/bin:${pkgs.coreutils}/bin:${pkgs.jq}/bin:${pkgs.gnused}/bin:$PATH
        ${heywoodlh-vscode}/bin/code --list-extensions | tail -${extensionCount}
      '';
      vscodeDir = if pkgs.stdenv.isDarwin then "Library/Application Support/Code/User" else ".config/Code/User";
      nixlessSetup = pkgs.writeText "setup-script" ''
        #!/usr/bin/env bash
        rootdir="$(dirname $0)"
        cp -v "$rootdir"/settings.json "$HOME/${vscodeDir}/settings.json"
        if which code &> /dev/null
        then
          cat "$rootdir"/extensions.txt | xargs -L 1 code --install-extension
        else
          echo "code command not found, skipping extension installation"
        fi
      '';
      vscodeExporter = pkgs.writeShellScript "exporter" ''
        outDir=$1
        PATH=${pkgs.coreutils}/bin:${pkgs.jq}/bin:${pkgs.gnused}/bin:$PATH
        mkdir -p "$outDir"
        ${printSettings} > "$outDir"/settings.json
        ${printExtensions} > "$outDir"/extensions.txt
        cp ${nixlessSetup} "$outDir"/setup.sh && chmod +x "$outDir"/setup.sh
      '';
      exportVscode = pkgs.stdenv.mkDerivation {
        name = "export-vscode";
        builder = pkgs.bash;
        args = [ "-c" "${vscodeExporter} $out" ];
      };
    in {
      packages = {
        vscode-settings-json = vscodeSettingsJson;
        export-vscode = exportVscode;
        setup-vscode = pkgs.writeShellScriptBin "setup-vscode" ''
          # Remove references to Nix and fish
          ${printSettings} > "$HOME/${vscodeDir}/settings.json"
          if which code &> /dev/null
          then
            ${printExtensions} | xargs -L 1 code --install-extension
          else
            echo "code command not found, skipping extension installation"
          fi
        '';
        default = heywoodlh-vscode;
      };
    });
}

