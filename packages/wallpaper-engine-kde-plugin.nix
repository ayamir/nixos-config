{
  config,
  lib,
  pkgs,
  ...
}:
let
  wallpaper-engine-kde-plugin =
    with pkgs;
    stdenv.mkDerivation rec {
      pname = "wallpaperEngineKde";
      version = "f1b86e1ca7982b5b9f47d21ac2cb5c2adfb45902";
      src = fetchFromGitHub {
        owner = "catsout";
        repo = "wallpaper-engine-kde-plugin";
        rev = version;
        hash = "sha256-otdfGa63w1TfMhYFBauJvxV90OqLqJSEvWB2j0W0E5g=";
        fetchSubmodules = true;
      };

      nativeBuildInputs = [
        cmake
        kdePackages.extra-cmake-modules
        pkg-config
        gst_all_1.gst-libav
        shaderc
        ninja
      ];

      buildInputs = [
        mpv
        lz4
        vulkan-headers
        vulkan-tools
        vulkan-loader
      ]
      ++ (
        with kdePackages;
        with qt6Packages;
        [
          qtbase
          pkgs.qt6.qtbase
          pkgs.qt6.qtdeclarative
          pkgs.qt6.qtwebengine
          pkgs.qt6.qttools
          kpackage
          kdeclarative
          libplasma
          qtwebsockets
          qtwebengine
          qtwebchannel
          qtmultimedia
          qtdeclarative
        ]
      )
      ++ [ (python3.withPackages (python-pkgs: [ python-pkgs.websockets ])) ];

      cmakeFlags = [ "-DUSE_PLASMAPKG=OFF" ];
      dontWrapQtApps = true;

      meta = with lib; {
        description = "Wallpaper Engine KDE plasma plugin";
        homepage = "https://github.com/catsout/wallpaper-engine-kde-plugin";
        license = licenses.gpl2Plus;
        platforms = platforms.linux;
      };
    };
in
{
  options.nixos = {
    pkgs.wallpaper-engine-kde-plugin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Enable wallpaper-engine-kde-plugin.";
      };
    };
  };

  config = lib.mkIf (config.nixos.pkgs.wallpaper-engine-kde-plugin.enable) {
    environment.systemPackages = with pkgs; [
      wallpaper-engine-kde-plugin
      kdePackages.qtwebsockets
      kdePackages.qtwebchannel
      (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
    ];

    system.activationScripts = {
      wallpaper-engine-kde-plugin.text = ''
        wallpaperenginetarget=/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde
        mkdir -p /home/ayamir/.local/share/plasma/wallpapers
        chown -R ayamir:users /home/ayamir/.local/share/plasma
        ln -nsf ${wallpaper-engine-kde-plugin}/$wallpaperenginetarget /home/ayamir/.local/$wallpaperenginetarget
      '';
    };
  };
}
