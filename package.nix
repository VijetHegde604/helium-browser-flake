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

stdenv.mkDerivation rec {
  pname = "helium-browser";
  version = "0.14.9.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
    hash = "sha256-BmYX3xKpzVsyxRxmypMpXRnp6+Z5wLcaEY8aEYN+Zz0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
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

    for icon in $out/opt/helium/product_logo_*.png; do
      [ -e "$icon" ] || continue
      size="''${icon##*_}"
      size="''${size%.png}"
      case "$size" in
        [0-9]* ) ;;
        * ) continue ;;
      esac

      install -Dm644 "$icon" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/helium.png"
    done

    mkdir -p $out/share/applications
    upstreamDesktop="$(find $out/opt/helium -name '*.desktop' -print -quit)"
    if [ -n "$upstreamDesktop" ]; then
      install -Dm644 "$upstreamDesktop" $out/share/applications/helium.desktop
      sed -i -E \
        -e '0,/^Exec=/{s|^Exec=.*|Exec=helium %U|}' \
        -e '0,/^Icon=/{s|^Icon=.*|Icon=helium|}' \
        $out/share/applications/helium.desktop
      if ! grep -q '^StartupWMClass=' $out/share/applications/helium.desktop; then
        awk '
          /^\[Desktop Action / && ! inserted {
            print "StartupWMClass=Helium"
            inserted = 1
          }
          { print }
          END {
            if (! inserted) {
              print "StartupWMClass=Helium"
            }
          }
        ' $out/share/applications/helium.desktop > $out/share/applications/helium.desktop.tmp
        mv $out/share/applications/helium.desktop.tmp $out/share/applications/helium.desktop
      fi
    else
      cat > $out/share/applications/helium.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Helium
GenericName=Web Browser
Comment=Access the Internet
Exec=helium %U
Terminal=false
Icon=helium
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;image/webp;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=Helium
Keywords=browser;internet;web;www;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Exec=helium --new-window %U

[Desktop Action new-private-window]
Name=New Private Window
Exec=helium --incognito %U
EOF
    fi

    runHook postInstall
  '';

  meta = {
    description = "Privacy-focused browser based on ungoogled Chromium";
    homepage = "https://helium.computer/";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
  };
}
