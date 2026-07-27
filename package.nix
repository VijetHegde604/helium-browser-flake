{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  dconf,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  glib-networking,
  gsettings-desktop-schemas,
  gtk3,
  libGL,
  libdrm,
  libgbm,
  libnotify,
  libuuid,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  systemd,
  wayland,
  xorg,
}:

let
  pname = "helium-browser";
  version = "0.14.9.1";

  runtimeLibs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    dconf
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    glib-networking
    gsettings-desktop-schemas
    gtk3
    libGL
    libdrm
    libgbm
    libnotify
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pciutils
    pipewire
    systemd
    wayland
  ];
in

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
    wrapGAppsHook3
  ];

  dontWrapGApps = true;

  buildInputs = runtimeLibs ++ [
    xorg.libX11
    xorg.libXScrnSaver
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
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
    hash = "sha256-BmYX3xKpzVsyxRxmypMpXRnp6+Z5wLcaEY8aEYN+Zz0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = runtimeLibs;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt/helium" "$out/bin"
    cp -r ./* "$out/opt/helium/"

    makeWrapper "$out/opt/helium/helium" "$out/bin/helium" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH:${gtk3}/share/gsettings-schemas/${gtk3.name}:${glib}/share:${gtk3}/share" \
      --set-default CHROME_WRAPPER "$out/bin/helium" \
      --add-flags "--ozone-platform-hint=auto"

    for size in 16 24 32 48 64 128 256; do
      icon="$out/opt/helium/product_logo_''${size}.png"
      if [ -e "$icon" ]; then
        install -Dm644 "$icon" "$out/share/icons/hicolor/''${size}x''${size}/apps/helium.png"
      fi
    done

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "helium";
      desktopName = "Helium";
      genericName = "Web Browser";
      comment = "Browse the web";
      exec = "helium %U";
      icon = "helium";
      startupNotify = true;
      startupWMClass = "Helium";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "application/xhtml+xml"
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    })
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Privacy-focused browser based on ungoogled Chromium";
    homepage = "https://helium.computer/";
    changelog = "https://github.com/imputnet/helium-linux/releases/tag/${version}";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
