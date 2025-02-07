{
  description = "GNOME desktop flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05"; # pinned for gnome-extensions-cli instability
    flake-utils.url = "github:numtide/flake-utils";
    fish-flake = {
      url = "github:heywoodlh/flakes?dir=fish";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vim-flake = {
      url = "github:heywoodlh/flakes?dir=vim";
      inputs.nixpkgs.follows = "nixpkgs";
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
      myShell = "${fish-flake.packages.${system}.tmux}/bin/tmux";
      myVim = vim-flake.packages.${system}.vim;
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
      guakeConf = {
        general = ''
          abbreviate-tab-names=false
          compat-delete='delete-sequence'
          default-shell='${myShell}'
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
          window-height=95
          window-losefocus=false
          window-refocus=false
          window-tabbar=false
          window-width=100
        '';
        keybindings.local = ''
          focus-terminal-left='<Primary>braceleft'
          focus-terminal-right='<Primary>braceright'
          split-tab-horizontal='<Primary>underscore'
          split-tab-vertical='<Primary>bar'
        '';
        style = {
          base = ''
            cursor-shape=0
          '';
          background = ''
            transparency=100
          '';
          font = ''
            allow-bold=true
            palette='#3B3B42425252:#BFBF61616A6A:#A3A3BEBE8C8C:#EBEBCBCB8B8B:#8181A1A1C1C1:#B4B48E8EADAD:#8888C0C0D0D0:#E5E5E9E9F0F0:#4C4C56566A6A:#BFBF61616A6A:#A3A3BEBE8C8C:#EBEBCBCB8B8B:#8181A1A1C1C1:#B4B48E8EADAD:#8F8FBCBCBBBB:#ECECEFEFF4F4:#D8D8DEDEE9E9:#2E2E34344040'
            palette-name='Nord'
            style='JetBrains Mono 14'
          '';
        };
      };
      dconf-ini = pkgs.writeText "dconf.ini" ''
        [apps/guake/general]
        ${guakeConf.general}
        [org/guake/general]
        ${guakeConf.general}

        [apps/guake/keybindings/local]
        ${guakeConf.keybindings.local}
        [org/guake/keybindings/local]
        ${guakeConf.keybindings.local}

        [apps/guake/style]
        ${guakeConf.style.base}
        [org/guake/style]
        ${guakeConf.style.base}

        [apps/guake/style/background]
        ${guakeConf.style.background}
        [org/guake/style/background]
        ${guakeConf.style.background}

        [apps/guake/style/font]
        ${guakeConf.style.font}
        [org/guake/style/font]
        ${guakeConf.style.font}

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
        play=@as ['<Shift><Control>space']
        terminal='disabled'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
        binding='<Super>Return'
        command='gnome-terminal'
        name='terminal super'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
        binding='<Ctrl><Alt>t'
        command='gnome-terminal'
        name='terminal ctrl_alt'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
        binding='<Ctrl><Super>s'
        command='${pkgs._1password-gui}/bin/1password --quick-access'
        name='1pass-quick-access'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4]
        binding='<Super><Shift>s'
        command='${pkgs.gnome-screenshot}/bin/gnome-screenshot -ac'
        name='screenshot'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5]
        binding='<Shift><Control>e'
        command='${vimIme} --cmd "gnome-terminal --geometry=60x8 -- ${myVim}/bin/vim" --outfile "/home/heywoodlh/tmp/vim-ime.txt"'
        name='vim-ime'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6]
        binding='<Shift><Control>b'
        command='${battpop}'
        name='battpop'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7]
        binding='<Control>grave'
        command='${stable-pkgs.guake}/bin/guake'
        name='guake'

        [org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom8]
        binding='<Shift><Control>d'
        command='${datepop}'
        name='datepop'

        [org/gnome/shell]
        disable-user-extensions=false
        disabled-extensions=@as ['disabled','ubuntu-dock@ubuntu.com','ding@rastersoft.com','nightthemeswitcher@romainvigier.fr', 'openbar@neuromorph', 'pop-shell@system76.com', 'switcher@landau.fi']
        enabled-extensions=@as ['caffeine@patapon.info','gsconnect@andyholmes.github.io','just-perfection-desktop@just-perfection','native-window-placement@gnome-shell-extensions.gcampax.github.com','user-theme@gnome-shell-extensions.gcampax.github.com','gnomebedtime@ionutbortis.gmail.com','forge@jmmaranan.com','hide-cursor@elcste.com', 'paperwm@paperwm.github.com', 'search-light@icedman.github.com']
        favorite-apps=@as ['firefox.desktop','wezterm.desktop']
        had-bluetooth-devices-setup=true
        remember-mount-password=false
        welcome-dialog-last-shown-version='42.4'

        [org/gnome/shell/extensions/bedtime-mode]
        bedtime-mode-active=false
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
        activate-launcher=@as ['disabled']
        focus-right=@as ['disabled']
        tile-by-default=true
        tile-enter=@as ['disabled']

        [org/gnome/shell/extensions/switcher]
        font-size=uint32 24
        max-width-percentage=uint32 48
        show-switcher=['<Super>space']

        [org/gnome/shell/extensions/search-light]
        blur-brightness=0.59999999999999998
        blur-sigma=30.0
        entry-font-size=1
        preferred-monitor=0
        scale-height=0.10000000000000001
        scale-width=0.10000000000000001
        shortcut-search=['<Super>space']

        [org/gnome/shell/extensions/openbar]
        accent-color=['0', '0.75', '0.75']
        accent-override=false
        apply-accent-shell=false
        apply-all-shell=false
        apply-flatpak=false
        apply-gtk=false
        apply-menu-notif=false
        apply-menu-shell=false
        auto-bgalpha=true
        autofg-bar=true
        autofg-menu=true
        autohg-bar=false
        autohg-menu=true
        autotheme-dark='Select Theme'
        autotheme-font=false
        autotheme-light='Select Theme'
        autotheme-refresh=false
        balpha=0.84999999999999998
        bartype='Islands'
        bcolor=['0.1568627506494522', '0.16470588743686676', '0.21176470816135406']
        bg-change=false
        bgalpha=0.94999999999999996
        bgalpha-wmax=1.0
        bgalpha2=0.69999999999999996
        bgcolor=['0.1568627506494522', '0.16470588743686676', '0.21176470816135406']
        bgcolor-wmax=['0.125', '0.125', '0.125']
        bgcolor2=['0', '0.7', '0.75']
        bgpalette=true
        border-wmax=false
        bordertype='solid'
        boxalpha=0.0
        boxcolor=['0.125', '0.125', '0.125']
        bradius=30.0
        bwidth=2.0
        candy1=['0', '0.61', '0.74']
        candy10=['0.09', '0.19', '0.72']
        candy11=['0.75', '0.49', '0.44']
        candy12=['1', '0.92', '0.12']
        candy13=['0.38', '0.63', '0.92']
        candy14=['0.37', '0.36', '0.39']
        candy15=['0.40', '0.23', '0.72']
        candy16=['1', '0.32', '0.32']
        candy2=['1', '0.41', '0.41']
        candy3=['0.63', '0.16', '0.8']
        candy4=['0.94', '0.60', '0.23']
        candy5=['0.03', '0.41', '0.62']
        candy6=['0.56', '0.18', '0.43']
        candy7=['0.95', '0.12', '0.67']
        candy8=['0.18', '0.76', '0.49']
        candy9=['0.93', '0.20', '0.23']
        candyalpha=0.98999999999999999
        candybar=false
        card-hint=10
        color-scheme='prefer-dark'
        corner-radius=false
        count1=0
        count10=0
        count11=0
        count12=0
        count2=0
        count3=0
        count4=0
        count5=0
        count6=0
        count7=0
        count8=0
        count9=0
        cust-margin-wmax=false
        dark-accent-color=['0', '0.75', '0.75']
        dark-bcolor=['0.1568627506494522', '0.16470588743686676', '0.21176470816135406']
        dark-bgcolor=['0.1568627506494522', '0.16470588743686676', '0.21176470816135406']
        dark-bgcolor-wmax=['0.125', '0.125', '0.125']
        dark-bgcolor2=['0', '0.7', '0.75']
        dark-bguri='/home/heywoodlh/.wallpaper.png'
        dark-boxcolor=['0.125', '0.125', '0.125']
        dark-candy1=['0', '0.61', '0.74']
        dark-candy10=['0.09', '0.19', '0.72']
        dark-candy11=['0.75', '0.49', '0.44']
        dark-candy12=['1', '0.92', '0.12']
        dark-candy13=['0.38', '0.63', '0.92']
        dark-candy14=['0.37', '0.36', '0.39']
        dark-candy15=['0.40', '0.23', '0.72']
        dark-candy16=['1', '0.32', '0.32']
        dark-candy2=['1', '0.41', '0.41']
        dark-candy3=['0.63', '0.16', '0.8']
        dark-candy4=['0.94', '0.60', '0.23']
        dark-candy5=['0.03', '0.41', '0.62']
        dark-candy6=['0.56', '0.18', '0.43']
        dark-candy7=['0.95', '0.12', '0.67']
        dark-candy8=['0.18', '0.76', '0.49']
        dark-candy9=['0.93', '0.20', '0.23']
        dark-dbgcolor=['0.125', '0.125', '0.125']
        dark-fgcolor=['1.0', '1.0', '1.0']
        dark-hcolor=['0.46666666865348816', '0.4627451002597809', '0.48235294222831726']
        dark-iscolor=['0.2980392277240753', '0.33725494146347046', '0.4156862795352936']
        dark-mbcolor=['1.0', '1.0', '1.0']
        dark-mbgcolor=['0.125', '0.125', '0.125']
        dark-mfgcolor=['1.0', '1.0', '1.0']
        dark-mhcolor=['0', '0.7', '0.9']
        dark-mscolor=['0', '0.7', '0.75']
        dark-mshcolor=['1.0', '1.0', '1.0']
        dark-palette1=['44', '44', '52']
        dark-palette10=['140', '140', '148']
        dark-palette11=['92', '100', '100']
        dark-palette12=['140', '148', '148']
        dark-palette2=['237', '238', '237']
        dark-palette3=['116', '117', '121']
        dark-palette4=['66', '67', '76']
        dark-palette5=['79', '81', '88']
        dark-palette6=['60', '60', '68']
        dark-palette7=['91', '92', '100']
        dark-palette8=['148', '148', '149']
        dark-palette9=['68', '76', '84']
        dark-shcolor=['0', '0', '0']
        dark-smbgcolor=['0.125', '0.125', '0.125']
        dark-winbcolor=['0.125', '0.125', '0.125']
        dashdock-style='Default'
        dbgalpha=0.84999999999999998
        dbgcolor=['0.125', '0.125', '0.125']
        dborder=false
        dbradius=100.0
        default-font='Sans 12'
        destruct-color=['0.75', '0.11', '0.16']
        disize=48.0
        dshadow=false
        fgalpha=1.0
        fgcolor=['1.0', '1.0', '1.0']
        font=""
        gradient=false
        gradient-direction='vertical'
        gtk-popover=false
        halpha=0.5
        handle-border=3.0
        hcolor=['0.46666666865348816', '0.4627451002597809', '0.48235294222831726']
        headerbar-hint=0
        heffect=false
        height=35.0
        hpad=1.0
        import-export=false
        isalpha=0.94999999999999996
        iscolor=['0.2980392277240753', '0.33725494146347046', '0.4156862795352936']
        light-accent-color=['0', '0.75', '0.75']
        light-bcolor=['1.0', '1.0', '1.0']
        light-bgcolor=['0.125', '0.125', '0.125']
        light-bgcolor-wmax=['0.125', '0.125', '0.125']
        light-bgcolor2=['0', '0.7', '0.75']
        light-bguri='/home/heywoodlh/.wallpaper.png'
        light-boxcolor=['0.125', '0.125', '0.125']
        light-candy1=['0', '0.61', '0.74']
        light-candy10=['0.09', '0.19', '0.72']
        light-candy11=['0.75', '0.49', '0.44']
        light-candy12=['1', '0.92', '0.12']
        light-candy13=['0.38', '0.63', '0.92']
        light-candy14=['0.37', '0.36', '0.39']
        light-candy15=['0.40', '0.23', '0.72']
        light-candy16=['1', '0.32', '0.32']
        light-candy2=['1', '0.41', '0.41']
        light-candy3=['0.63', '0.16', '0.8']
        light-candy4=['0.94', '0.60', '0.23']
        light-candy5=['0.03', '0.41', '0.62']
        light-candy6=['0.56', '0.18', '0.43']
        light-candy7=['0.95', '0.12', '0.67']
        light-candy8=['0.18', '0.76', '0.49']
        light-candy9=['0.93', '0.20', '0.23']
        light-dbgcolor=['0.125', '0.125', '0.125']
        light-fgcolor=['1.0', '1.0', '1.0']
        light-hcolor=['0', '0.7', '0.9']
        light-iscolor=['0.125', '0.125', '0.125']
        light-mbcolor=['1.0', '1.0', '1.0']
        light-mbgcolor=['0.125', '0.125', '0.125']
        light-mfgcolor=['1.0', '1.0', '1.0']
        light-mhcolor=['0', '0.7', '0.9']
        light-mscolor=['0', '0.7', '0.75']
        light-mshcolor=['1.0', '1.0', '1.0']
        light-palette1=['44', '44', '52']
        light-palette10=['140', '140', '148']
        light-palette11=['92', '100', '100']
        light-palette12=['140', '148', '148']
        light-palette2=['237', '238', '237']
        light-palette3=['116', '117', '121']
        light-palette4=['66', '67', '76']
        light-palette5=['79', '81', '88']
        light-palette6=['60', '60', '68']
        light-palette7=['91', '92', '100']
        light-palette8=['148', '148', '149']
        light-palette9=['68', '76', '84']
        light-shcolor=['0', '0', '0']
        light-smbgcolor=['0.125', '0.125', '0.125']
        light-winbcolor=['0.125', '0.125', '0.125']
        margin=3.0
        margin-wmax=2.0
        mbalpha=0.59999999999999998
        mbcolor=['1.0', '1.0', '1.0']
        mbg-gradient=false
        mbgalpha=0.94999999999999996
        mbgcolor=['0.125', '0.125', '0.125']
        menu-radius=21.0
        menustyle=true
        mfgalpha=1.0
        mfgcolor=['1.0', '1.0', '1.0']
        mhalpha=0.34999999999999998
        mhcolor=['0', '0.7', '0.9']
        monitors='all'
        msalpha=0.84999999999999998
        mscolor=['0', '0.7', '0.75']
        mshalpha=0.16
        mshcolor=['1.0', '1.0', '1.0']
        neon=false
        neon-wmax=false
        notif-radius=10.0
        palette1=['44', '44', '52']
        palette10=['140', '140', '148']
        palette11=['92', '100', '100']
        palette12=['140', '148', '148']
        palette2=['237', '238', '237']
        palette3=['116', '117', '121']
        palette4=['66', '67', '76']
        palette5=['79', '81', '88']
        palette6=['60', '60', '68']
        palette7=['91', '92', '100']
        palette8=['148', '148', '149']
        palette9=['68', '76', '84']
        pause-reload=false
        position='Top'
        prominent1=['100', '100', '100']
        prominent2=['100', '100', '100']
        prominent3=['100', '100', '100']
        prominent4=['100', '100', '100']
        prominent5=['100', '100', '100']
        prominent6=['100', '100', '100']
        qtoggle-radius=50.0
        radius-bottomleft=true
        radius-bottomright=true
        radius-topleft=true
        radius-topright=true
        reloadstyle=false
        removestyle=false
        set-fullscreen=false
        set-notifications=false
        set-overview=false
        set-yarutheme=false
        shadow=false
        shalpha=0.20000000000000001
        shcolor=['0', '0', '0']
        sidebar-hint=10
        sidebar-transparency=false
        slider-height=4.0
        smbgalpha=0.94999999999999996
        smbgcolor=['0.25', '0.30', '0.30']
        smbgoverride=true
        success-color=['0.15', '0.635', '0.41']
        traffic-light=false
        trigger-autotheme=false
        trigger-reload=true
        vpad=4.0
        warning-color=['0.96', '0.83', '0.17']
        width-bottom=true
        width-left=true
        width-right=true
        width-top=true
        winbalpha=0.75
        winbcolor=['0.125', '0.125', '0.125']
        winbradius=12.0
        winbwidth=0.0
        wmaxbar=false

        [org/gnome/shell/extensions/user-theme]
        name='Nordic-darker'

        [org/gnome/shell/keybindings]
        switch-to-application-1='disabled'
        switch-to-application-2='disabled'
        switch-to-application-3='disabled'
        switch-to-application-4='disabled'
        toggle-overview=@as ['disabled']

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
        custom-command='${myShell}'
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
                               "hide-cursor@elcste.com"
                               "user-theme@gnome-shell-extensions.gcampax.github.com"
                               "paperwm@paperwm.github.com"
                               "search-light@icedman.github.com")

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
