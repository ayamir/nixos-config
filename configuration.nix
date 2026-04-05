# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./packages/wallpaper-engine-kde-plugin.nix
    ./packages/plasma6-window-title-applet.nix
  ];

  # Enable flakes
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org/"
        "https://mirrors.cernet.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://noctalia.cachix.org"
        # "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        # "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
      trusted-users = [
        "root"
        "ayamir"
      ];
      auto-optimise-store = true;
      pure-eval = false;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };
  };

  nixos.pkgs = {
    wallpaper-engine-kde-plugin.enable = true;
    plasma6-window-title-applet.enable = true;
  };

  # Setting for bool options
  boot = {
    loader = {
      timeout = 15;
      systemd-boot.enable = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.kernelModules = [ "amdgpu" ];
    supportedFilesystems = [ "ntfs" ];
  };

  # Define your hostname.
  networking.hostName = "nixos";

  # Configure network proxy if necessary
  networking.proxy.default = "http://127.0.0.1:7890/";
  networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = "/opt/mihomo/config.yaml";
    webui = pkgs.metacubexd;
  };

  # Pre-provision geodata files so mihomo doesn't need to download them at startup
  systemd.services.mihomo.serviceConfig.ExecStartPre =
    let
      dataDir = "/var/lib/private/mihomo";
      geoip = pkgs.v2ray-geoip;
      geosite = pkgs.v2ray-domain-list-community;
      mmdb = pkgs.dbip-country-lite;
    in
    "+${pkgs.writeShellScript "mihomo-geodata" ''
      install -m 0644 ${geoip}/share/v2ray/geoip.dat ${dataDir}/geoip.dat
      install -m 0644 ${geosite}/share/v2ray/geosite.dat ${dataDir}/geosite.dat
      install -m 0644 ${mmdb}/share/dbip/dbip-country-lite.mmdb ${dataDir}/country.mmdb
    ''}";

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
          qt6Packages.fcitx5-chinese-addons
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
  services.displayManager.sddm = {
    enable = true;
    enableHidpi = true;
    theme = "breeze";
  };
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
        rocmPackages.clr.icd
      ];
      enable32Bit = true;
    };
  };
  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "10.3.0"; # Navi 23 有时需要这个
      HTTPS_PROXY = "http://127.0.0.1:7890"; # 换成你的代理端口
      HTTP_PROXY = "http://127.0.0.1:7890";
      NO_PROXY = "localhost,127.0.0.1";
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
    after = [
      "network.target"
      "sound.target"
    ];
    wantedBy = [ "default.target" ];
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
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "uinput"
      "mihomo"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "ayamir" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  security.polkit.enable = true;

  # Install fish
  programs.fish.enable = true;

  # Install neovim
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
  hardware.uinput.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libxcb
  ];
  programs.steam.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Fonts
  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    fontconfig.confPackages = [
      (pkgs.runCommand "60-emoji-embeddedbitmap" { } ''
        mkdir -p $out/etc/fonts/conf.d
        cat > $out/etc/fonts/conf.d/60-emoji-embeddedbitmap.conf << 'EOF'
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Re-enable embedded bitmap for color emoji fonts (CBDT/CBLC),
               overriding 53-no-bitmaps.conf which runs at position 53. -->
          <match target="font">
            <test name="color"><bool>true</bool></test>
            <edit name="embeddedbitmap" mode="assign"><bool>true</bool></edit>
          </match>
        </fontconfig>
        EOF
      '')
    ];
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      sarasa-gothic
      twemoji-color-font
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.lilex
      pkgs.maple-mono.truetype
      pkgs.maple-mono.NF-unhinted
      pkgs.maple-mono.NF-CN-unhinted
      (pkgs.stdenvNoCC.mkDerivation {
        pname = "consolas-lxgw-wenkai-mono";
        version = "fb06baa";
        srcs = [
          (pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/MichaelC001/Consolas-Nerd-LXGW-Wenkai-Mono/fb06baa8739d20c5e02cf19ba2554b3a231a700a/consolaslxgw.ttf";
            sha256 = "0mxh4vqdxhz60azs1sszjchcmlwjc5wamg7a4ivsndlk23rys6xb";
          })
          (pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/MichaelC001/Consolas-Nerd-LXGW-Wenkai-Mono/fb06baa8739d20c5e02cf19ba2554b3a231a700a/Ligaconsolaslxgw.ttf";
            sha256 = "08g107n2algz6f5plfp99l4jb3wgj8zywlfjcks39nmspq2a2212";
          })
        ];
        unpackPhase = "true";
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          cp $srcs $out/share/fonts/truetype/
        '';
      })
    ];
    fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight"; # 可选: none, slight, medium, full
      };
      subpixel = {
        rgba = "rgb"; # 根据显示器调整: rgb, bgr, vrgb, vbgr
        lcdfilter = "default";
      };
      defaultFonts = {
        serif = [
          "Noto Serif CJK SC"
          "Sarasa Gothic SC"
        ];
        sansSerif = [
          "Noto Sans SC"
          "Sarasa Gothic SC"
          "Liberation Sans"
        ];
        monospace = [
          "Maple Mono NF CN"
          "Liga consolaslxgw"
          "JetBrains Mono Nerd Font"
          "Liberation Mono"
        ];
        emoji = [
          "Noto Color Emoji"
          "Twitter Color Emoji"
        ];
      };
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test qual="any" name="family"><string>Sans</string></test>
            <edit binding="weak" mode="append" name="family">
              <string>Noto Color Emoji</string>
            </edit>
          </match>
          <match target="pattern">
            <test qual="any" name="family"><string>sans-serif</string></test>
            <edit binding="weak" mode="append" name="family">
              <string>Noto Color Emoji</string>
            </edit>
          </match>
          <match target="pattern">
            <test qual="any" name="family"><string>monospace</string></test>
            <edit binding="weak" mode="append" name="family">
              <string>Noto Color Emoji</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    LIBCLANG_PATH = "${pkgs.libclang.lib}/lib";
    # LD_LIBRARY_PATH = "/run/current-system/sw/lib:${pkgs.stdenv.cc.cc.lib}/lib";
  };
  environment.systemPackages = with pkgs; [
    home-manager

    vim
    neovim
    wget
    curl
    fish
    fastfetch
    git
    git-open
    lazygit

    rar
    zip
    p7zip
    xz
    unzip

    inxi
    lshw
    libva
    mesa-demos
    clinfo
    microcode-amd

    ripgrep # recursively searches directories for a regex pattern
    jq # A lightweight and flexible command-line JSON processor
    yq-go # yaml processor https://github.com/mikefarah/yq
    eza # A modern replacement for ‘ls’
    fzf # A command-line fuzzy finder
    zoxide
    yazi
    fd
    tokei
    dust
    procs
    bat
    fsearch
    wl-clipboard
    rofi
    neovide

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
    sqlite
    mise
    uv
    stdenv.cc.cc.lib

    bc
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
    nixd

    # productivity
    hugo # static site generator
    glow # markdown previewer in terminal

    btop # replacement of htop/nmon
    iotop # io monitoring
    iftop # network monitoring
    amdgpu_top
    radeontop
    radeon-profile
    radeontools

    # system call monitoring
    gdb
    strace # system call monitoring
    ltrace # library call monitoring
    lsof # list open files

    # system tools
    sysstat
    lm_sensors # for `sensors` command
    ethtool
    pciutils # lspci
    usbutils # lsusb

    inputs.kwin-effects-better-blur-dx.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.browser-previews.packages.${pkgs.stdenv.hostPlatform.system}.google-chrome-beta

    kdePackages.breeze
    kdePackages.krohnkite
    kdePackages.polkit-kde-agent-1
    kdePackages.sddm-kcm

    libimobiledevice
    ifuse # optional, to mount using 'ifuse'

    typora
    logseq
    obsidian
    obsidian-export

    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.qmd
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.rtk

    # niri + noctalia shell
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    brightnessctl
    imagemagick
    wlsunset
    ddcutil
    cliphist

    # niri 配套工具
    chezmoi
    libinput-gestures # 触摸板手势 → 命令
    gpu-screen-recorder
    wtype
    grim # 截图
    slurp # 区域选择（配合 grim）
    swayidle # 空闲/息屏管理
    xwayland-satellite # X11 应用支持（niri 无内建 XWayland）
    libnotify # notify-send 工具
  ];
  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };
  programs.kdeconnect.enable = true;

  services = {
    asusd = {
      enable = true;
    };
  };
  services.supergfxd.enable = true;

  systemd.services.jupyter.serviceConfig.User = lib.mkForce "ayamir";

  services.jupyter = {
    enable = true;
    port = 8888;
    password = "";
    ip = "127.0.0.1";
    notebookDir = "/home/ayamir/repos/ayamir/learn-infra/notebook";
    kernels =
      let
        mkKernel = name: env: {
          displayName = name;
          language = "python";
          argv = [
            "${env.interpreter}"
            "-m"
            "ipykernel_launcher"
            "-f"
            "{connection_file}"
          ];
          logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
          logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
        };
        pythonBase = pkgs.python3.withPackages (
          ps: with ps; [
            ipykernel
            numpy
            pandas
            matplotlib
            seaborn
            scipy
            requests
          ]
        );
        aiInfra = pkgs.python3.withPackages (
          ps: with ps; [
            ipykernel
            numpy
            pandas
            matplotlib
            torch
            torchvision
            tqdm
            tensorboard
            datasets
            transformers
            ray
            dask
            distributed
            pyarrow
            duckdb
            seaborn
            scipy
            scikit-learn
            statsmodels
            sympy
            plotly
            requests
            beautifulsoup4
            pillow
            python-lsp-server
            pylsp-mypy
            pylsp-rope
          ]
        );
      in
      {
        python-base = mkKernel "Python Base" pythonBase;
        ai-infra = mkKernel "AI Infra" aiInfra;
      };
  };

  programs.niri.enable = true;

  services.upower.enable = true;

  programs.direnv.enable = true;

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

  networking.firewall = {
    # 把 tun 设备加入信任接口
    trustedInterfaces = [ "Meta" ]; # mihomo 默认 tun 设备名
    # 或者关闭 checkReversePath（透明代理常见问题）
    checkReversePath = false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).

  system.stateVersion = "24.11"; # Did you read the comment?
}
