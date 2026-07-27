{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,

  alsa-lib,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libGL,
  libdrm,
  libgbm,
  libnotify,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  pipewire,
  wayland,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "helium";
  version = "0.14.9.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
    hash = "sha256-BmYX3xKpzVsyxRxmypMpXRnp6+Z5wLcaEY8aEYN+Zz0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libGL
    libdrm
    libgbm
    libnotify
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pipewire
    wayland

    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/helium
    cp -r ./* $out/opt/helium

    mkdir -p $out/bin

    makeWrapper $out/opt/helium/helium \
      $out/bin/helium \
      --add-flags "--ozone-platform-hint=auto"

    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp $out/opt/helium/product_logo_256.png \
      $out/share/icons/hicolor/256x256/apps/helium.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "helium";
      desktopName = "Helium";
      exec = "helium %U";
      icon = "helium";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "text/html"
      ];
    })
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Privacy-focused browser based on ungoogled Chromium";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
