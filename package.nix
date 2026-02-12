{
  lib,
  stdenv,
  fetchurl,
  config,
  wrapGAppsHook3,
  autoPatchelfHook,
  alsa-lib,
  curl,
  dbus-glib,
  gtk3,
  libXtst,
  libva,
  pciutils,
  pipewire,
  adwaita-icon-theme,
  writeText,
  patchelfUnstable, # have to use patchelfUnstable to support --no-clobber-old-sections
  nix-update-script,
  policies ? { },
}:

let
  binaryName = "glide-browser";

  glidePolicies = (config.glide-browser.policies or { }) // policies;

  policiesJson = writeText "glide-browser-policies.json" (
    builtins.toJSON { policies = glidePolicies; }
  );

  pname = "glide-browser-unwrapped";

  version = "0.1.59a";
in

stdenv.mkDerivation {
  inherit pname version;

  src =
    let
      sources = {
        "x86_64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
          sha256 = "sha256-kEGSWjpljjyoszMDL5ekew1IsBg8PhL24scqjYdlgfo=";
        };
        "aarch64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-aarch64.tar.xz";
          sha256 = "sha256-2OPsCpchIzOU/rCFL37apTVHHPj8hO4yfNWurMUzKyQ=";
        };
        "x86_64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-x86_64.dmg";
          sha256 = "sha256-ah2NSUlKPKHzhIoN9JckAhXx37wY8GBgkyTlXKDFyoA=";
        };
        "aarch64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-aarch64.dmg";
          sha256 = "sha256-mD/fUY2TQwb07n6i7FHBg76ChGWneJhdp3iUIfRjkHo=";
        };
      };
    in
    sources.${stdenv.hostPlatform.system};

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
  ];

  buildInputs = [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libXtst
  ];

  runtimeDependencies = [
    curl
    libva.out
    pciutils
  ];

  appendRunpaths = [ "${pipewire}/lib" ];

  # Firefox uses "relrhack" to manually process relocations from a fixed offset
  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $prefix/lib $out/bin
    cp -r . $prefix/lib/glide-browser-bin-${version}
    ln -s $prefix/lib/glide-browser-bin-${version}/glide $out/bin/${binaryName}-unwrapped
    # See: https://github.com/mozilla/policy-templates/blob/master/README.md
    mkdir -p $out/lib/glide-browser-bin-${version}/distribution/
    ln -s ${policiesJson} $out/lib/glide-browser-bin-${version}/distribution/policies.json

    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--url"
        "https://github.com/glide-browser/glide"
      ];
    };
    applicationName = "Glide Browser";
    libName = "glide-browser-bin-${version}";
    ffmpegSupport = true;
    gssSupport = true;
    inherit gtk3;
  };

  meta = {
    changelog = "https://glide-browser.app/changelog#${version}";
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
    mainProgram = "glide-browser-unwrapped";
  };
}
