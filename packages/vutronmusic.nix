{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  dpkg,
  alsa-lib,
  libgcc,
  libxcb,
  libgbm,
  libxkbcommon,
  libdrm,
  libnotify,
  libsecret,
  libuuid,
  nss,
  nspr,
  mesa,
  udev,
  gtk3,
}:
let
  pname = "vutronmusic";
  version = "3.1.0";

  src = fetchurl {
    url = "https://github.com/stark81/VutronMusic/releases/download/v${version}/VutronMusic-${version}_linux_amd64.deb";
    hash = "sha256-LB8F/fdGoxMtzGaiECkMAfSsGFThvva9bMgLU6CgLRc=";
  };

  libraries = [
    alsa-lib
    libgcc.lib
    libxcb
    libgbm
    libxkbcommon
    libdrm
    libnotify
    libsecret
    libuuid
    nss
    nspr
    mesa
    udev
    gtk3
  ];
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
    dpkg
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
  ];

  buildInputs = libraries;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r opt $out/opt
    cp -r usr/share $out/share
    substituteInPlace $out/share/applications/vutron.desktop \
      --replace-warn "/opt/VutronMusic/vutron" "$out/bin/vutron"
    makeWrapper $out/opt/VutronMusic/vutron $out/bin/vutron \
      --argv0 "vutron" \
      --add-flags "$out/opt/VutronMusic/resources/app.asar" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libraries}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Good-looking third-party NetEase Cloud Music player";
    mainProgram = "vutron";
    homepage = "https://github.com/stark81/VutronMusic/";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
