{
  inputs,
  config,
  pkgs,
  ...
}: {
  imports = [
  ];

  home.username = "ayamir";
  home.homeDirectory = "/home/ayamir";
  home.packages = with pkgs; [
    alacritty
    kitty
    tmux
    htop

    google-chrome
    firefox
    clash-nyanpasu
    sarasa-gothic
    (vivaldi.overrideAttrs (oldAttrs: {
      dontWrapQtApps = false;
      dontPatchELF = true;
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.kdePackages.wrapQtAppsHook];
    }))

    copyq
    kdePackages.kcolorchooser

    gh
    vscode

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
  ];

  # 启用 starship，这是一个漂亮的 shell 提示符
  programs.starship = {
    enable = true;
    settings = {
      aws.disabled = true;
      gcloud.disabled = true;
      line_break.disabled = true;
    };
  };

  xdg.desktopEntries = {
    wechat = {
      name = "Wechat";
      genericName = "Messaging app";
      exec = "wechat-uos -- %U";
      terminal = false;
      icon = "com.tencent.wechat";
      categories = ["Application" "Utility"];
    };
  };

  programs.neovim = {
    enable = true;
    # Python and Lua packages can be easily installed with the corresponding `home-manager` options.
    extraPython3Packages = ps:
      with ps; [
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
