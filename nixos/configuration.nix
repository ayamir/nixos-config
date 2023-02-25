# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
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
    config = {
      allowUnfree = true;
      # Enable electron
      permittedInsecurePackages = [
        "electron-18.1.0"
        "electron-19.0.7"
      ];
    };
  };

  # Settings for nix
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      substituters = [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
      # Enable flakes and nix-command
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
    };
    # auto gc
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
  };

  # Setting for bool options
  boot = {
    loader = {
      timeout = 15;
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = [ "amdgpu" "radeon" ];
    kernelParams = [
      "video=eDP-1:2560x1600@120"
      "video=HDMI-A-1:2560x1440@60"
    ];
  };

  # Setting for network
  networking = {
    hostName = "eva00";
    networkmanager.enable = true;
    proxy.default = "http://127.0.0.1:7890";
    proxy.noProxy = "127.0.0.1,localhost,internal.domain";
    hosts = {
      "185.199.109.133" = [ "raw.githubusercontent.com" ];
      "185.199.111.133" = [ "raw.githubusercontent.com" ];
      "185.199.110.133" = [ "raw.githubusercontent.com" ];
      "185.199.108.133" = [ "raw.githubusercontent.com" ];
    };
  };

  # Setting for time zone, locale and input method
  time.timeZone = "Asia/Shanghai";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "zh_CN.UTF-8";
      LC_IDENTIFICATION = "zh_CN.UTF-8";
      LC_MEASUREMENT = "zh_CN.UTF-8";
      LC_MONETARY = "zh_CN.UTF-8";
      LC_NAME = "zh_CN.UTF-8";
      LC_NUMERIC = "zh_CN.UTF-8";
      LC_PAPER = "zh_CN.UTF-8";
      LC_TELEPHONE = "zh_CN.UTF-8";
      LC_TIME = "zh_CN.UTF-8";
    };
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.enableRimeData = true;
      fcitx5.addons = with pkgs; [
        fcitx5-chinese-addons
        fcitx5-rime
      ];
    };
  };

  # Settings for AMD GPU
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.hip}"
  ];
  hardware = {
    opengl = {
      extraPackages = with pkgs; [
        amdvlk
        rocm-opencl-icd
        rocm-opencl-runtime
      ];
      driSupport = true;
      driSupport32Bit = true;
    };
  };

  # Enable HiDPI
  hardware.video.hidpi.enable = true;
  console.font =
    "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
  environment.variables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    _JAVA_OPTIONS = "-Dsun.java2d.uiScale=2";
  };

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Setting for audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
  };
  security.rtkit.enable = true;

  # Setting for desktop environment and SSH session
  services = {
    xserver = {
      dpi = 180;
      enable = true;
      layout = "us";
      xkbVariant = "";
      videoDrivers = [ "amdgpu" ];
      displayManager = { 
        sddm.enable = true;
      };
      desktopManager.plasma5.enable = true;
    };
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };
  };

  # Setting for users
  users.users = {
    ayamir = {
      shell = pkgs.fish;
      isNormalUser = true;
      description = "ayamir";
      extraGroups = [ "wheel" "docker" "networkmanager" "audio" ];
      packages = with pkgs; [
        gh
        lsd
        exa
        fish
        cava
        kitty
        logseq
        feishu
        # wezterm
        lazygit
        vivaldi
        tdesktop
        obsidian
        google-chrome
        vivaldi-ffmpeg-codecs
        whitesur-gtk-theme
        whitesur-icon-theme
        config.nur.repos.xddxdd.qq
        config.nur.repos.xddxdd.wechat-uos
        config.nur.repos.xddxdd.qqmusic
        config.nur.repos.linyinfeng.wemeet
        config.nur.repos.rewine.ttf-ms-win10
        config.nur.repos.rewine.ttf-wps-fonts
        config.nur.repos.linyinfeng.clash-for-windows
        config.nur.repos.eh5.netease-cloud-music
        config.nur.repos.rewine.electron-netease-cloud-music
      ];
    };
  };

  # Setting for sudo
  security.sudo.extraRules= [{
    users = [ "ayamir" ];
    commands = [{
        command = "ALL" ;
        options= [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
    }];
  }];

  # Setting for fonts
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [
      roboto
      fira-code
      noto-fonts
      sarasa-gothic
      noto-fonts-cjk
      liberation_ttf
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "IBMPlexMono" ]; })
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Sarasa Gothic SC" "Roboto" ];
        sansSerif = [ "Sarasa Gothic SC" "Roboto" ];
        monospace = [ "FiraCode" "JetBrainsMono" ];
      };
    };
  };

  # Enable systemd services
  systemd.services = {
    printing.enable = true;
  };

  # Set environment
  environment.sessionVariables = rec {
    XDG_CACHE_HOME  = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_BIN_HOME    = "\${HOME}/.local/bin";
    XDG_DATA_HOME   = "\${HOME}/.local/share";
    PATH = [ 
      "\${XDG_BIN_HOME}"
    ];
  };

  # Set system version
  system.stateVersion = "22.11";

  # Set system packages
  environment.systemPackages = with pkgs; [
    gh
    fd
    go
    lsd
    exa
    fzf
    git
    gcc
    gdb
    zip
    rar
    vim
    mpv
    fish
    curl
    wget
    tmux
    lldb
    llvm
    yarn
    clang
    cmake
    unzip
    p7zip
    nginx
    nodejs
    ffmpeg
    docker
    neovim
    sqlite
    zoxide
    gnumake
    ripgrep
    neofetch
    iptables
    htop-vim
    xdg-utils
    ffmpegthumbnailer
  ];
}
