{
  description = "GNOME desktop flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11"; # pinned for gnome-extensions-cli instability
    flake-utils.url = "github:numtide/flake-utils";
    fish-flake = {
      url = "github:heywoodlh/flakes?dir=fish";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tmux-flake = {
      url = "github:heywoodlh/flakes?dir=tmux";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fish-flake.follows = "fish-flake";
    };
    vim-flake = {
      url = "github:heywoodlh/flakes?dir=vim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fish-flake.follows = "fish-flake";
    };
    vim-ime = {
      flake = false;
      url = "github:heywoodlh/vim-input-editor";
    };
    nordic = {
      flake = false;
      url = "https://github.com/EliverLara/Nordic/releases/download/v2.2.0/Nordic.tar.xz";
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    flake-utils,
    fish-flake,
    tmux-flake,
    vim-flake,
    vim-ime,
    nordic,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      stable-pkgs = nixpkgs-stable.legacyPackages.${system};
      myTmux = tmux-flake.packages.${system}.tmux;
      myVim = vim-flake.defaultPackage.${system};
      vimIme = "${vim-ime}/vim-ime.py";
      wallpaper = ./wallpapers/nix-nord.png;
      jetbrains-font = builtins.fetchurl {
        url = "https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip";
        sha256 = "sha256:1gvv5w0vfzndzp8k7g15j5i3yvnpr5z3imrwjs5flq19xp37cqvg";
      };

      battpop = pkgs.writeShellScript "battpop" ''
        ${pkgs.libnotify}/bin/notify-send $(${pkgs.acpi}/bin/acpi -b | ${pkgs.gnugrep}/bin/grep -Eo [0-9]+%)
      '';
      datepop = pkgs.writeShellScript "datepop" ''
        ${pkgs.libnotify}/bin/notify-send "$(${pkgs.coreutils}/bin/date "+%T")"
      '';
      dconf-ini = pkgs.writeText "dconf.ini" ''
        [apps/guake/general]
        abbreviate-tab-names=false
        compat-delete='delete-sequence'
        default-shell='${myTmux}/bin/tmux'
        display-n=0
        display-tab-names=0
        gtk-prefer-dark-theme=true
        gtk-theme-name='Adwaita-dark'
        gtk-use-system-default-theme=true
        hide-tabs-if-one-tab=false
        history-size=1000
        load-guake-yml=true
        max-tab-name-length=100
        mouse-display=true
        open-tab-cwd=true
        prompt-on-quit=true
        quick-open-command-line='${pkgs.xdg-utils}/bin/xdg-open %(file_path)s'
        restore-tabs-notify=false
        restore-tabs-startup=false
        save-tabs-when-changed=false
        schema-version='3.9.0'
        scroll-keystroke=true
        start-at-login=true
        use-default-font=false
        use-login-shell=false
        use-popup=false
        use-scrollbar=false
        use-trayicon=false
        window-halignment=0
        window-height=50
        window-losefocus=false
        window-refocus=false
        window-tabbar=false
        window-width=100

        [apps/guake/keybindings/local]
        focus-terminal-left='<Primary>braceleft'
        focus-terminal-right='<Primary>braceright'
        split-tab-horizontal='<Primary>underscore'
        split-tab-vertical='<Primary>bar'

        [apps/guake/style]
        cursor-shape=1

        [apps/guake/style/background]
        transparency=100

        [apps/guake/style/font]
        allow-bold=true
        palette='#3B3B42425252:#BFBF61616A6A:#A3A3BEBE8C8C:#EBEBCBCB8B8B:#8181A1A1C1C1:#B4B48E8EADAD:#8888C0C0D0D0:#E5E5E9E9F0F0:#4C4C56566A6A:#BFBF61616A6A:#A3A3BEBE8C8C:#EBEBCBCB8B8B:#8181A1A1C1C1:#B4B48E8EADAD:#8F8FBCBCBBBB:#ECECEFEFF4F4:#D8D8DEDEE9E9:#2E2E34344040'
        palette-name='Nord'
        style='JetBrains Mono 14'

        [org/gnome/desktop/background]
        color-shading='solid'
        picture-options='zoom'
        picture-uri='${wallpaper}'
        picture-uri-dark='${wallpaper}'

        [org/gnome/desktop/input-sources]
        xkb-options=@as ['caps:super']

        [org/gnome/desktop/interface]
        clock-show-seconds=true
        clock-show-weekday=true
        color-scheme='prefer-dark'
        enable-hot-corners=false
        font-antialiasing='grayscale'
        font-hinting='slight'
        gtk-theme='Nordic'
        icon-theme='Nordic-darker'
        toolkit-accessibility=true

        [org/gnome/desktop/notifications]
        show-in-lock-screen=false

        [org/gnome/desktop/peripherals/touchpad]
        tap-to-click=true
        two-finger-scrolling-enabled=true

        [org/gnome/desktop/screensaver]
        color-shading='solid'
        picture-options='zoom'
        picture-uri='file://${wallpaper}'
        picture-uri-dark='file://${wallpaper}'

        [org/gnome/desktop/wm/keybindings]
        activate-window-menu=@as ['disabled']
        close=@as ['<Super>q']
        maximize=@as ['disabled']
        minimize=@as ['<Super>comma']
        move-to-monitor-down=@as ['disabled']
        move-to-monitor-left=@as ['disabled']
        move-to-monitor-right=@as ['disabled']
        move-to-monitor-up=@as ['disabled']
        move-to-workspace-1=@as ['<Shift><Super>1']
        move-to-workspace-2=@as ['<Shift><Super>2']
        move-to-workspace-3=@as ['<Shift><Super>3']
        move-to-workspace-4=@as ['<Shift><Super>4']
        move-to-workspace-down=@as ['disabled']
        move-to-workspace-up=@as ['disabled']
        switch-input-source=@as ['disabled']
        switch-input-source-backward=@as ['disabled']
        switch-to-workspace-1=@as ['<Super>1']
        switch-to-workspace-2=@as ['<Super>2']
        switch-to-workspace-3=@as ['<Super>3']
        switch-to-workspace-4=@as ['<Super>4']
        switch-to-workspace-left=@as ['<Super>bracketleft']
        switch-to-workspace-right=@as ['<Super>bracketright']
        toggle-maximized=@as ['<Super>Up']
        toggle-message-tray=@as ['disabled']
        unmaximize=@as ['disabled']

        [org/gnome/desktop/wm/preferences]
        button-layout='close,minimize,maximize:appmenu'
        num-workspaces=10

        [org/gnome/epiphany/web]
        enable-user-css=true
        enable-webextensions=true
        homepage-url='about:newtab'
        remember-passwords=false

        [org/gnome/mutter]
        dynamic-workspaces=false
        workspaces-only-on-primary=false

        [org/gnome/settings-daemon/plugins/media-keys]
        custom-keybindings=@as ['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8/']
        logout=@as ['<Shift><Super>e']
        next=@as ['<Shift><Control>n']
        play=@as ['<Shift><Control>space']
        previous=@as ['<Shift><Control>p']
        terminal='disabled'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
        binding='<Super>Return'
        command='${pkgs.gnome.gnome-terminal}/bin/gnome-terminal'
        name='terminal super'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
        binding='<Ctrl><Alt>t'
        command='${pkgs.gnome.gnome-terminal}/bin/gnome-terminal'
        name='terminal ctrl_alt'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
        binding='<Ctrl><Super>s'
        command='${pkgs._1password-gui}/bin/1password --quick-access'
        name='rofi-1pass'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4]
        binding='<Super><Shift>s'
        command='${pkgs.gnome.gnome-screenshot}/bin/gnome-screenshot -a -f /tmp/screenshot.png && ${pkgs.xclip}/bin/xclip -in -selection clipboard -target image/png /tmp/screenshot.png"'
        name='screenshot'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5]
        binding='<Shift><Control>e'
        command='${vimIme} --cmd "${pkgs.gnome.gnome-terminal}/bin/gnome-terminal --geometry=60x8 -- ${myVim}/bin/vim" --outfile "/home/heywoodlh/tmp/vim-ime.txt"'
        name='vim-ime'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6]
        binding='<Shift><Control>b'
        command='${battpop}'
        name='battpop'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7]
        binding='<Control>grave'
        command='${pkgs.guake}/bin/guake'
        name='guake'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8]
        binding='<Shift><Control>d'
        command='${datepop}'
        name='datepop'

        [org/gnome/shell]
        disable-user-extensions=false
        disabled-extensions=@as ['disabled','ubuntu-dock@ubuntu.com','ding@rastersoft.com','nightthemeswitcher@romainvigier.fr']
        enabled-extensions=@as ['caffeine@patapon.info','gsconnect@andyholmes.github.io','just-perfection-desktop@just-perfection','native-window-placement@gnome-shell-extensions.gcampax.github.com','pop-shell@system76.com','user-theme@gnome-shell-extensions.gcampax.github.com','switcher@landau.fi','gnomebedtime@ionutbortis.gmail.com','forge@jmmaranan.com']
        favorite-apps=@as ['firefox.desktop','wezterm.desktop']
        had-bluetooth-devices-setup=true
        remember-mount-password=false
        welcome-dialog-last-shown-version='42.4'

        [org/gnome/shell/extensions/bedtime-mode]
        bedtime-mode-active=true
        color-tone-factor=80

        [org/gnome/shell/extensions/forge]
        css-last-update=uint32 37

        [org/gnome/shell/extensions/forge/keybindings]
        window-snap-two-third-left=['<Control><Alt>e']
        window-snap-two-third-right=@as []
        window-swap-last-active=@as []
        window-toggle-float=['<Super>y']

        [org/gnome/shell/extensions/just-perfection]
        accessibility-menu=true
        app-menu=true
        app-menu-icon=true
        background-menu=true
        controls-manager-spacing-size=22
        dash=true
        dash-icon-size=0
        double-super-to-appgrid=true
        gesture=true
        hot-corner=false
        notification-banner-position=2
        osd=false
        panel=false
        panel-arrow=true
        panel-corner-size=1
        panel-in-overview=true
        ripple-box=false
        search=false
        show-apps-button=true
        startup-status=0
        theme=true
        window-demands-attention-focus=true
        window-picker-icon=false
        window-preview-caption=true
        window-preview-close-button=true
        workspace=true
        workspace-background-corner-size=15
        workspace-popup=false
        workspaces-in-app-grid=true

        [org/gnome/shell/extensions/paperwm]
        show-window-position-bar=false
        use-default-background=true

        [org/gnome/shell/extensions/paperwm/keybindings]
        move-left=@as ['<Shift><Super>braceleft']
        move-right=@as ['<Shift><Super>braceright']
        switch-left=@as ['<Super>bracketleft']
        switch-right=@as ['<Super>bracketright']
        toggle-maximize-width=@as ['<Super>Up']

        [org/gnome/shell/extensions/pop-shell]
        activate-launcher=@as ['<Super>space']
        focus-right=@as ['disabled']
        tile-by-default=true
        tile-enter=@as ['disabled']

        [org/gnome/shell/extensions/switcher]
        font-size=uint32 24
        max-width-percentage=uint32 48
        show-switcher=@as ['<Super>space']

        [org/gnome/shell/extensions/user-theme]
        name='Nordic-darker'

        [org/gnome/shell/keybindings]
        switch-to-application-1='disabled'
        switch-to-application-2='disabled'
        switch-to-application-3='disabled'
        switch-to-application-4='disabled'

        [org/gnome/terminal/legacy]
        default-show-menubar=false
        headerbar=false

        [org/gnome/terminal/legacy/profiles:]
        default='3797f158-f495-4609-995f-286da69c8d86'
        list=@as ['3797f158-f495-4609-995f-286da69c8d86','3797f158-f495-4609-995f-286da69c8d87']

        [org/gnome/terminal/legacy/profiles:/:3797f158-f495-4609-995f-286da69c8d86]
        background-color='#2E3440'
        bold-color='#D8DEE9'
        bold-color-same-as-fg=true
        cursor-background-color='rgb(216,222,233)'
        cursor-colors-set=true
        cursor-foreground-color='rgb(59,66,82)'
        cursor-shape='ibeam'
        custom-command='${myTmux}/bin/tmux'
        font='JetBrains Mono NL 14'
        foreground-color='#D8DEE9'
        highlight-background-color='rgb(136,192,208)'
        highlight-colors-set=true
        highlight-foreground-color='rgb(46,52,64)'
        nord-gnome-terminal-version='0.1.0'
        palette=@as ['#3B4252','#BF616A','#A3BE8C','#EBCB8B','#81A1C1','#B48EAD','#88C0D0','#E5E9F0','#4C566A','#BF616A','#A3BE8C','#EBCB8B','#81A1C1','#B48EAD','#8FBCBB','#ECEFF4']
        scrollbar-policy='never'
        use-custom-command=true
        use-system-font=false
        use-theme-background=false
        use-theme-colors=false
        use-theme-transparency=false
        use-transparent-background=false
        visible-name='Nord'

        [org/gnome/terminal/legacy/profiles:/:3797f158-f495-4609-995f-286da69c8d87]
        background-color='#2E3440'
        bold-color='#D8DEE9'
        bold-color-same-as-fg=true
        cursor-background-color='rgb(216,222,233)'
        cursor-colors-set=true
        cursor-foreground-color='rgb(59,66,82)'
        cursor-shape='ibeam'
        custom-command='bash'
        font='JetBrains Mono NL 14'
        foreground-color='#D8DEE9'
        highlight-background-color='rgb(136,192,208)'
        highlight-colors-set=true
        highlight-foreground-color='rgb(46,52,64)'
        nord-gnome-terminal-version='0.1.0'
        palette=@as ['#3B4252','#BF616A','#A3BE8C','#EBCB8B','#81A1C1','#B48EAD','#88C0D0','#E5E9F0','#4C566A','#BF616A','#A3BE8C','#EBCB8B','#81A1C1','#B48EAD','#8FBCBB','#ECEFF4']
        scrollbar-policy='never'
        use-custom-command=true
        use-system-font=false
        use-theme-background=false
        use-theme-colors=false
        use-theme-transparency=false
        use-transparent-background=false
        visible-name='Vanilla'

        [org/gnome/tweaks]
        show-extensions-notice=false
      '';
      gnome-install-extensions = pkgs.writeShellScript "gnome-ext-install" ''
        declare -a extensions=("caffeine@patapon.info"
                               "gnomebedtime@ionutbortis.gmail.com"
                               "gsconnect@andyholmes.github.io"
                               "just-perfection-desktop@just-perfection"
                               "native-window-placement@gnome-shell-extensions.gcampax.github.com"
                               "forge@jmmaranan.com"
                               "switcher@landau.fi"
                               "user-theme@gnome-shell-extensions.gcampax.github.com")

        for extension in "''${extensions[@]}"
        do
          ${stable-pkgs.gnome-extensions-cli}/bin/gext install "$extension"
          ${stable-pkgs.gnome-extensions-cli}/bin/gext enable "$extension"
        done
      '';
      dconf-nix = pkgs.stdenv.mkDerivation {
        name = "dconf-nix";
        builder = pkgs.bash;
        args = [ "-c" "${pkgs.dconf2nix}/bin/dconf2nix -i ${dconf-ini} -o $out" ];
      };
    in {
      packages = rec {
        dconf = dconf-nix;
        gnome-desktop-setup = pkgs.writeShellScriptBin "gnome-desktop-setup" ''
          ## Install JetBrains nerd font
          mkdir -p ~/.local/share/fonts/ttf
          for file in "JetBrainsMono-Regular.ttf" "JetBrainsMonoNL-Regular.ttf"
          do
            if [[ ! -e ~/.local/share/fonts/ttf/$file ]]
            then
              ${pkgs.unzip}/bin/unzip -p ${jetbrains-font} fonts/ttf/$file > ~/.local/share/fonts/ttf/$file
            fi
          done
          ${pkgs.fontconfig}/bin/fc-cache -f -v ~/.local/share/fonts

          ## Install Nordic theme
          if [[ ! -d ~/.themes/Nordic ]]
          then
            mkdir -p ~/.themes/Nordic
            cp -r ${nordic}/* ~/.themes/Nordic
          fi

          ## Install extensions
          ${gnome-install-extensions}

          ## Apply dconf
          if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
            export DCONF_DBUS_RUN_SESSION=""
          else
            export DCONF_DBUS_RUN_SESSION="${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon"
          fi
          $DCONF_BUS_RUN_SESSION ${pkgs.dconf}/bin/dconf load / < ${dconf-ini}

          ## Ensure ~/.nix-profile/share/applications is indexed by GNOME
          if ! grep -Eq "^XDG_DATA_DIRS" ~/.profile
          then
            export XDG_DATA_DIRS="$HOME/.nix-profile/share:$XDG_DATA_DIRS"
            printf "\nXDG_DATA_DIRS=\"$XDG_DATA_DIRS\"\n" >> ~/.profile
          fi
        '';
        default = gnome-desktop-setup;
      };

      formatter = pkgs.alejandra;
    });
}
