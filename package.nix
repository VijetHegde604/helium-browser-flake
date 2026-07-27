{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  copyDesktopItems,
  wrapGAppsHook3,
  makeDesktopItem,

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
  libsecret,
  libva,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  xorg,
}:

let
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
    libsecret
    libva
    libxkbcommon
    mesa
    nspr
    nss
    pango
    pciutils
    pipewire
    systemd
    vulkan-loader
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
      "${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix XDG_DATA_DIRS : "$out/share:${gsettings-desktop-schemas}/share:${gtk3}/share" \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules:${dconf}/lib/gio/modules" \
      --add-flags "--ozone-platform-hint=auto"

    # Helium ships Chromium's chrome-sandbox helper, but this derivation does
    # not install it setuid. NixOS users should rely on the system Chromium
    # sandbox support configured by their profile/system rather than a package
    # local setuid helper.
    #
    # GPU behavior is intentionally limited to the upstream Ozone auto-detection
    # flag above. We expose Vulkan/VA-API/GBM libraries for Chromium's runtime
    # probes, but do not force feature flags that can vary by driver/session.

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

  meta = {
    description = "Privacy-focused browser based on ungoogled Chromium";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
