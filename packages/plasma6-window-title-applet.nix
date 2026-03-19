{
  config,
  lib,
  pkgs,
  ...
}: let
  plasma6-window-title-applet = pkgs.stdenv.mkDerivation rec {
    pname = "plasma6-window-title-applet";
    version = "0.9.0";

    src = pkgs.fetchFromGitHub {
      owner = "dhruv8sh";
      repo = "plasma6-window-title-applet";
      rev = "v${version}";
      hash = "sha256-pFXVySorHq5EpgsBz01vZQ0sLAy2UrF4VADMjyz2YLs=";
    };

    dontBuild = true;

    postPatch = ''
      substituteInPlace contents/ui/main.qml \
        --replace-fail "import org.kde.plasma.private.appmenu 1.0 as AppMenuPrivate" ""
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plasma/plasmoids/org.kde.windowtitle
      cp -r contents metadata.json $out/share/plasma/plasmoids/org.kde.windowtitle/
      runHook postInstall
    '';

    meta = with lib; {
      description = "Plasma 6 applet that shows the application title and icon for active window";
      homepage = "https://github.com/dhruv8sh/plasma6-window-title-applet";
      license = licenses.gpl2Only;
      platforms = platforms.linux;
    };
  };
in {
  options.nixos.pkgs.plasma6-window-title-applet = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable plasma6-window-title-applet.";
    };
  };

  config = lib.mkIf config.nixos.pkgs.plasma6-window-title-applet.enable {
    environment.systemPackages = [plasma6-window-title-applet];
  };
}
