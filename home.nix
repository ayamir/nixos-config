{
  inputs,
  config,
  pkgs,
  ...
}:
let
  switchTmuxTheme = pkgs.writeShellScriptBin "switch-tmux-theme" ''
    MODE=$1
    CHADRC=~/.config/nvim/lua/chadrc.lua

    echo "$MODE" > ~/.config/tmux/current-theme

    if [ "$MODE" = "light" ]; then
      ${pkgs.tmux}/bin/tmux source ~/.config/tmux/themes/latte.conf 2>/dev/null || true
      NVIM_THEME="catppuccin-latte"
    else
      ${pkgs.tmux}/bin/tmux source ~/.config/tmux/themes/mocha.conf 2>/dev/null || true
      NVIM_THEME="catppuccin"
    fi

    if [ -f "$CHADRC" ]; then
      ${pkgs.perl}/bin/perl -i -pe "s/theme = \"catppuccin(?:-latte)?\"/theme = \"$NVIM_THEME\"/" "$CHADRC"
    fi

    SERVERS=$(${pkgs.lsof}/bin/lsof -U 2>/dev/null | awk '/nvim/ && /\/run\/user/ && !/fzf/ {print $9}')
    if [ -n "$SERVERS" ]; then
      for server in $SERVERS; do
        ${pkgs.neovim}/bin/nvim --server "$server" \
          --remote-expr "luaeval(\"require('nvchad.utils').reload()\")" \
          2>/dev/null || true
      done
    fi
  '';

  tmuxThemeWatcher = pkgs.writeShellScriptBin "tmux-theme-watcher" ''
    query_scheme() {
      ${pkgs.dbus}/bin/dbus-send --session --print-reply \
        --dest=org.freedesktop.portal.Desktop \
        /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.Read \
        string:org.freedesktop.appearance string:color-scheme 2>/dev/null |
        grep -o 'uint32 [0-9]' | awk '{print $2}'
    }

    apply_scheme() {
      local value
      value=$(query_scheme)
      if [ "$value" = "1" ]; then
        ${switchTmuxTheme}/bin/switch-tmux-theme dark
      else
        ${switchTmuxTheme}/bin/switch-tmux-theme light
      fi
    }

    apply_scheme

    ${pkgs.dbus}/bin/dbus-monitor --session \
      "type='signal',interface='org.freedesktop.portal.Settings',member='SettingChanged'" |
      grep --line-buffered 'org.freedesktop.appearance' |
      while read -r _; do
        apply_scheme
      done
  '';

  imeSwitcherScript = pkgs.writeShellScriptBin "ime-switch" ''
    export GI_TYPELIB_PATH="${pkgs.glib.out}/lib/girepository-1.0:${pkgs.gobject-introspection}/lib/girepository-1.0''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
    exec ${
      pkgs.python3.withPackages (ps: [
        ps.dbus-python
        ps.pygobject3
      ])
    }/bin/python3 ${./ime-switch.py} "$@"
  '';
in
{
  imports = [
  ];

  home.username = "ayamir";
  home.homeDirectory = "/home/ayamir";
  home.packages = with pkgs; [
    alacritty
    kitty
    tmux
    htop
    cava

    switchTmuxTheme
    tmuxThemeWatcher
    claude-code
    clash-verge-rev
    sarasa-gothic

    copyq
    kdePackages.kcolorchooser
    typora
    logseq

    gh
    vscode
    tree-sitter

    feishu
    telegram-desktop
    wechat-uos
    qq
    plasmusic-toolbar
    localsend
    discord
    wpsoffice
    gopeed
    yt-dlp

    (pkgs.callPackage ./packages/vutronmusic.nix { })
    imeSwitcherScript

    (catppuccin-kde.override {
      flavour = [
        "mocha"
        "latte"
        "frappe"
        "macchiato"
      ];
      accents = [ "blue" ];
    })
    catppuccin-cursors.mochaDark
    catppuccin-cursors.latteLight
    pkgs.libnotify

    linux-wallpaperengine
  ];

  programs.simple-wallpaper-engine = {
    enable = true;
    xdgAutostart = true;
  };

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = [
        "JetBrains Mono Nerd Font"
        "Liga consolaslxgw"
        "Maple Mono NF CN"
      ];
      theme = "light:Catppuccin Latte,dark:Catppuccin Mocha";
      font-style = "SemiBold";
      font-family-italic = "Lilex Nerd Font";
      font-style-italic = "SemiBold Italic";
      font-family-bold-italic = "Lilex Nerd Font";
      font-style-bold-italic = "Bold Italic";
      font-size = 12;
      background-opacity = 0.9;
      macos-option-as-alt = true;
      link-url = true;
      cursor-text = "#000000";
      clipboard-read = "allow";
      clipboard-write = "allow";
      copy-on-select = "clipboard";
    };
  };

  xdg.desktopEntries = {
    google-chrome-beta = {
      name = "Google Chrome Beta";
      exec = "google-chrome-beta --enable-features=TouchpadOverscrollHistoryNavigation --password-store=basic --gtk-version=4 %U";
      terminal = false;
      icon = "google-chrome-beta";
      categories = [
        "Network"
        "WebBrowser"
      ];
    };
    wechat = {
      name = "Wechat";
      genericName = "Messaging app";
      exec = "wechat-uos -- %U";
      terminal = false;
      icon = "com.tencent.wechat";
      categories = [
        "Application"
        "Utility"
      ];
    };
    obsidian = {
      name = "Obsidian";
      exec = "obsidian %u";
      terminal = false;
      icon = "obsidian";
      categories = [ "Office" ];
      mimeType = [ "x-scheme-handler/obsidian" ];
      settings = {
        StartupWMClass = "obsidian";
      };
    };
  };

  programs.neovim = {
    enable = true;
    # Python and Lua packages can be easily installed with the corresponding `home-manager` options.
    extraPython3Packages =
      ps: with ps; [
        numpy
      ];
  };

  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
    in
    {
      enable = true;
      enabledExtensions = with spicePkgs.extensions; [
        adblockify
        hidePodcasts
        shuffle
      ];
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "latte";
    };

  xdg.configFile."ime-switcher/rules.json".text = builtins.toJSON {
    rules = {
      "kitty" = "keyboard-us";
      "Alacritty" = "keyboard-us";
      "com.mitchellh.ghostty" = "keyboard-us";
      "krunner" = "keyboard-us";
      "org.kde.konsole" = "keyboard-us";
      "code" = "keyboard-us";
      "code-url-handler" = "keyboard-us";
      "google-chrome-beta" = "";
      "org.telegram.desktop" = "";
      "obsidian" = "";
      "org.kde.kate" = "";
    };
    default_im = "";
    remember_state = true;
  };

  systemd.user.services.tmux-theme-watcher = {
    Unit = {
      Description = "Sync tmux/nvim theme with system light/dark mode";
    };
    Service = {
      ExecStart = "${tmuxThemeWatcher}/bin/tmux-theme-watcher";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.ime-switcher = {
    Unit = {
      Description = "KDE Wayland + Fcitx5 自动输入法切换器";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${imeSwitcherScript}/bin/ime-switch run";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = [ "PYTHONUNBUFFERED=1" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."tmux/themes/latte.conf".source = ./tmux-themes/latte.conf;
  xdg.configFile."tmux/themes/mocha.conf".source = ./tmux-themes/mocha.conf;

  xdg.configFile."kanata/config.kbd".text = ''
    (defsrc
      caps lctl lalt lmet)

    (deflayer base
      lctl @ctrl_th lmet lalt)

    (defalias
      ctrl_th (tap-hold-release 300 300
        M-spc
        caps))
  '';

  systemd.user.services.kanata = {
    Unit = {
      Description = "kanata keyboard remapper";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.kanata}/bin/kanata --cfg %h/.config/kanata/config.kbd";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.startServices = "sd-switch";
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
