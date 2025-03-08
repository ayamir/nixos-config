# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./packages/wallpaper-engine-kde-plugin.nix
  ];

  # Enable flakes
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://mirrors.cernet.edu.cn/nix-channels/store" "https://mirror.sjtu.edu.cn/nix-channels/store"];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
  };

  nixos.pkgs = {
    wallpaper-engine-kde-plugin.enable = true;
  };

  # Setting for bool options
  boot = {
    loader = {
      timeout = 15;
      systemd-boot.enable = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = ["amdgpu"];
  };

  # Define your hostname.
  networking.hostName = "nixos";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://127.0.0.1:7890/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    inputMethod = {
      type = "fcitx5";
      enable = true;
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-chinese-addons
          fcitx5-material-color
          kdePackages.fcitx5-qt
          fcitx5-rime
          rime-data
        ];
      };
    };
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
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # AMD GPU settings
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];
  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        amdvlk
        rocmPackages.clr.icd
        driversi686Linux.amdvlk
      ];
      enable32Bit = true;
    };
  };

  # Bluetooth
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  services.blueman.enable = true;
  systemd.user.services.mpris-proxy = {
    description = "Mpris proxy";
    after = ["network.target" "sound.target"];
    wantedBy = ["default.target"];
    serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ayamir = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "ayamir";
    extraGroups = ["networkmanager" "wheel" "input"];
    packages = with pkgs; [
    ];
  };

  security.sudo.extraRules = [
    {
      users = ["ayamir"]; # 替换为你的用户名
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        } # 允许所有命令免密码
      ];
    }
  ];

  # Install fish
  programs.fish.enable = true;
  programs.neovim = {
    enable = true;
    vimAlias = true;
    defaultEditor = true;
    configure = {
      customRC = ''
        set relativenumber
      '';
    };
  };
  programs.nix-ld.enable = true;
  programs.steam.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Fonts
  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts-emoji
      twemoji-color-font
      (iosevka-bin.override {variant = "SGr-IosevkaFixed";})
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.commit-mono
      pkgs.nerd-fonts.blex-mono
      pkgs.nerd-fonts.ubuntu-mono
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = ["Liberation Serif"];
        sansSerif = ["Sarasa Gothic SC"];
        monospace = ["Iosevka Fixed" "JetBrains Mono"];
        emoji = ["Twemoji" "Noto Emoji"];
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    vim
    neovim
    wget
    curl
    fish
    neofetch
    git
    lazygit

    rar
    zip
    p7zip
    xz
    unzip

    inxi
    lshw
    libva
    glxinfo
    clinfo
    amdvlk
    microcodeAmd

    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    zoxide
    fd
    tokei
    dust
    procs
    bat
    fsearch
    wl-clipboard

    mpv
    vlc
    ffmpeg
    ffmpegthumbnailer

    cmake
    gnumake
    llvm
    gcc
    clang
    go
    rustup
    nodejs
    yarn
    python3

    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    ncdu

    # nix related
    #
    # it provides the command `nom` works just like `nix`
    # with more details log output
    nix-output-monitor

    # productivity
    hugo # static site generator
    glow # markdown previewer in terminal

    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring

    # system call monitoring
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb

    inputs.kwin-effects-forceblur.packages.${pkgs.system}.default
    inputs.zen-browser.packages."${pkgs.system}".specific

    libimobiledevice
    ifuse # optional, to mount using 'ifuse'
  ];
  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };
  programs.kdeconnect.enable = true;

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
  };
  services.supergfxd.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
