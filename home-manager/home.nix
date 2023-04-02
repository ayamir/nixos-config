# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ inputs, outputs, lib, config, pkgs, nurlock, ... }: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
      # Enable electron
      permittedInsecurePackages = [
        "electron-18.1.0"
        "electron-19.0.7"
      ];
      packageOverrides = pkgs: {
        nur = import
          (builtins.fetchTarball {
            url = "https://github.com/nix-community/NUR/archive/${nurlock.rev}.tar.gz";
            sha256 = nurlock.narHash;
          })
          {
            inherit pkgs;
          };
      };
    };
  };

  home = {
    username = "ayamir";
    homeDirectory = "/home/ayamir";
  };

  home.packages = with pkgs; [
    # Tools
    gh
    hugo
    cava
    copyq
    kitty
    lazygit
    # wezterm
    # Note
    logseq
    obsidian
    # Daily
    feishu
    tdesktop
    unstable.go-musicfox
    nur.repos.xddxdd.qq
    nur.repos.xddxdd.wechat-uos
    nur.repos.linyinfeng.wemeet
    nur.repos.linyinfeng.clash-for-windows
    nur.repos.rewine.electron-netease-cloud-music
    # Browser
    google-chrome
    # vivaldi
    # vivaldi-ffmpeg-codecs
    # Theme
    whitesur-gtk-theme
    whitesur-icon-theme
  ];

  # Add stuff for your user as you see fit:
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      difftastic = {
        enable = true;
        background = "light";
        color = "auto";
        display = "side-by-side";
      };
    };
    gh = {
      enable = true;
      enableGitCredentialHelper = true;
      package = pkgs.gh;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
        editor = "nvim";
        alias = {
          co = "pr checkout";
          pv = "pr view";
        };
      };
    };
    lazygit = {
      enable = true;
      package = pkgs.lazygit;
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}

