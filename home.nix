{
  inputs,
  config,
  pkgs,
  ...
}:
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

    claude-code
    brave
    clash-nyanpasu
    sarasa-gothic

    copyq
    kdePackages.kcolorchooser

    gh
    vscode
    tree-sitter

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
    utools
  ];

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      theme = "catppuccin-mocha";
      background-opacity = 0.9;
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
