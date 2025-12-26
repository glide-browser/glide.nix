{
  lib,
  stdenv,
  fetchurl,
  # keep-sorted start
  adwaita-icon-theme,
  alsa-lib,
  autoPatchelfHook,
  copyDesktopItems,
  curl,
  dbus-glib,
  gtk3,
  hicolor-icon-theme,
  libXtst,
  libva,
  mesa,
  makeBinaryWrapper,
  makeDesktopItem,
  patchelfUnstable,
  pciutils,
  pipewire,
  wrapGAppsHook3,
  nix-update-script,
  ffmpeg_7,
  libGL,
  libX11,
  libXScrnSaver,
  libpciaccess,
  # Additional libraries for WebGL and GFX support
  libffi,
  libgcrypt,
  libxcomposite,
  libxdamage,
  libxrandr,
  libXt,
  libevent,
  # Ensure OpenGL and WebGL support
  libGLU,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "glide-browser";
  version = "0.1.57a";

  src =
    let
      sources = {
        "x86_64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${finalAttrs.version}/glide.linux-x86_64.tar.xz";
          sha256 = "1bdmrpbbq1zxpgd06sc8xvph29q3ivlc3k6fbv9xs33sq03jzb84";
        };
        "aarch64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${finalAttrs.version}/glide.linux-aarch64.tar.xz";
          sha256 = "1qyki7cfmkhi2p1wfgy1ymr6m52b8vn5a34gn7gfybk616vlvj23";
        };
        "x86_64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${finalAttrs.version}/glide.macos-x86_64.dmg";
          sha256 = "0zz7jd77jqd6frfg1mq19bafdmy4zidl30xhcymqcbgqpv98fflf";
        };
        "aarch64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${finalAttrs.version}/glide.macos-aarch64.dmg";
          sha256 = "078gx609mfbg486nmlxs7pqjc4n81hxxwf9sqdmqvyafzdyc9lh5";
        };
      };
    in
    sources.${stdenv.hostPlatform.system};

  nativeBuildInputs = [
    copyDesktopItems
    makeBinaryWrapper
  ]
  ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
    patchelfUnstable
    wrapGAppsHook3
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    gtk3
    hicolor-icon-theme
    libXtst
    libGL
    libX11
    libXScrnSaver
    libpciaccess
    ffmpeg_7
    libffi
    libgcrypt
    libxcomposite
    libxdamage
    libxrandr
    libXt
    alsa-lib
    libevent
    mesa
    libGLU
  ];

  runtimeDependencies = lib.optionals stdenv.isLinux [
    curl
    libva.out
    mesa
    pciutils
    libGL
  ];

  appendRunpaths = lib.optionals stdenv.isLinux [
    "${pipewire}/lib"
    "${libGL}/lib"
  ];

  # Firefox uses "relrhack" to manually process relocations from a fixed offset
  patchelfFlags = lib.optionals stdenv.isLinux [ "--no-clobber-old-sections" ];

  unpackPhase = lib.optionalString stdenv.isDarwin ''
    runHook preUnpack

    /usr/bin/hdiutil attach -nobrowse -readonly $src
    cp -r /Volumes/Glide/Glide.app .
    /usr/bin/hdiutil detach /Volumes/Glide

    runHook postUnpack
    '';
  preFixup = lib.optionals stdenv.isLinux ''
    gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ ffmpeg_7 ]}"
      )
  '';

  installPhase =
    if stdenv.isLinux then
      ''
        runHook preInstall

        mkdir -p $out/bin $out/share/icons/hicolor/ $out/lib/glide-browser-bin-${finalAttrs.version}
        cp -t $out/lib/glide-browser-bin-${finalAttrs.version} -r *
        chmod +x $out/lib/glide-browser-bin-${finalAttrs.version}/glide
        iconDir=$out/share/icons/hicolor
        browserIcons=$out/lib/glide-browser-bin-${finalAttrs.version}/browser/chrome/icons/default

        for i in 16 32 48 64 128; do
          iconSizeDir="$iconDir/''${i}x$i/apps"
          mkdir -p $iconSizeDir
          cp $browserIcons/default$i.png $iconSizeDir/glide-browser.png
        done

        ln -s $out/lib/glide-browser-bin-${finalAttrs.version}/glide $out/bin/glide
        ln -s $out/bin/glide $out/bin/glide-browser

        runHook postInstall
      ''
    else
      ''
        runHook preInstall

        mkdir -p $out/Applications
        cp -r Glide.app $out/Applications/

    runHook postInstall

  # WebGL/Graphics settings via environment variables
  shellHook = lib.optionals stdenv.isLinux ''
    export MOZ_DISABLE_RDD_SANDBOX=1  # Disable RDD sandbox to prevent WebGL issues
    export MOZ_WEBRENDER=1  # Enable WebRender for GPU acceleration
    export MOZ_ACCELERATED=1  # Enable hardware acceleration for WebGL
    export WebglAllowWindowsNativeGl=true  # Allow native GL for WebGL
    export AllowWebgl2=true  # Enable WebGL2 support
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "glide-browser-bin";
      exec = "glide-browser --name glide-browser %U";
      icon = "glide-browser";
      desktopName = "Glide Browser";
      genericName = "Web Browser";
      terminal = false;
      startupNotify = true;
      startupWMClass = "glide-browser";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      actions = {
        new-window = {
          name = "New Window";
          exec = "glide-browser --new-window %U";
        };
        new-private-window = {
          name = "New Private Window";
          exec = "glide-browser --private-window %U";
        };
        profile-manager-window = {
          name = "Profile Manager";
          exec = "glide-browser --ProfileManager";
        };
      };
    })
  ];

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/glide-browser/glide"
    ];
  };

  meta = {
    changelog = "https://glide-browser.app/changelog#${finalAttrs.version}";
    description = "Extensible and keyboard-focused web browser, based on Firefox (binary package)";
    homepage = "https://glide-browser.app/";
    license = lib.licenses.mpl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    maintainers = with lib.maintainers; [ pyrox0 ];
    mainProgram = "glide-browser";
  };
})
