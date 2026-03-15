{
  inputs,
  config,
  pkgs,
  ...
}:
let
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

    claude-code
    brave
    clash-nyanpasu
    sarasa-gothic

    copyq
    kdePackages.kcolorchooser

    gh
    vscode
    tree-sitter

    feishu
    telegram-desktop
    wechat-uos
    qq
    qcm
    localsend
    discord
    wpsoffice
    spotify
    gopeed

    nur.repos.instantos.spotify-adblock
    imeSwitcherScript
  ];

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = [
        "Liga consolaslxgw"
        "Maple Mono NF CN"
      ];
      theme = "catppuccin-mocha";
      font-style = "SemiBold";
      font-family-bold = "Lilex";
      font-family-italic = "Lilex";
      font-style-italic = "SemiBold";
      font-family-bold-italic = "Lilex";
      font-style-bold-italic = "Bold";
      font-size = 14;
      background-opacity = 0.9;
      macos-option-as-alt = true;
      link-url = true;
      cursor-text = "#000000";
      clipboard-read = "allow";
      clipboard-write = "allow";
      copy-on-select = "clipboard";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = false;
    };
  };

  xdg.configFile."autostart/clash-nyanpasu.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Version=1.0
    Name=clash-nyanpasu
    Comment=clash-nyanpasustartup script
    Exec=${config.home.homeDirectory}/.nix-profile/bin/clash-nyanpasu
    StartupNotify=false
    Terminal=false
  '';

  xdg.desktopEntries = {
    google-chrome-beta = {
      name = "Google Chrome Beta";
      exec = "google-chrome-beta --enable-features=TouchpadOverscrollHistoryNavigation %U";
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
  };

  programs.neovim = {
    enable = true;
    # Python and Lua packages can be easily installed with the corresponding `home-manager` options.
    extraPython3Packages =
      ps: with ps; [
        numpy
      ];
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
