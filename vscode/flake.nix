{
  description = "heywoodlh vscode config";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  inputs.vscode-config.url = "gitlab:kylesferrazza/vscode-config";

  outputs = inputs@{
    self,
    nixpkgs,
    flake-utils,
    nix-vscode-extensions,
    vscode-config,
  }:
  flake-utils.lib.eachDefaultSystem (system: let

      mkVSCode = inputs.vscode-config.mkVSCode.${system};

      allExtensions = nix-vscode-extensions.extensions.${system};

      heywoodlh-vscode = mkVSCode {
        settings = {
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
          "terminal.integrated.macOptionIsMeta" = true;
          "terminal.integrated.shellIntegration.enabled" = true;
          "terraform.telemetry.enabled" = false;
          "update.showReleaseNotes" = false;
          "vim.useSystemClipboard" = true;
          "vsicons.dontShowNewVersionMessage" = true;
          "workbench.colorTheme" = "Nord";
          "workbench.welcomePage.walkthroughs.openOnInstall" = false;
        };
        extensions = with allExtensions.vscode-marketplace; [
          arcticicestudio.nord-visual-studio-code
          eamodio.gitlens
          github.copilot
          jnoortheen.nix-ide
          ms-python.python
          vscodevim.vim
        ];
      };
    in {
      packages.default = heywoodlh-vscode;
    });
}

