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
  undmg,
  nix-update-script,
  applicationName ? "Glide",
  policies ? { },
}:

let
  binaryName = "glide";

  glidePolicies = (config.glide-browser.policies or { }) // policies;

  policiesJson = writeText "glide-browser-policies.json" (
    builtins.toJSON { policies = glidePolicies; }
  );

  pname = "glide-browser-bin-unwrapped";

  version = "0.1.62a";
in

stdenv.mkDerivation {
  inherit pname version;

  src =
    let
      sources = {
        "x86_64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
          sha256 = "sha256-sOiopWNSksCdbqRavKrWT9kpBIxoo8zdMRrD0nMWKg8=";
        };
        "aarch64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-aarch64.tar.xz";
          sha256 = "sha256-z05DbevxiSe/xDvZKZxft1ebqVC6+Pk6VC4YGu2Uvs0=";
        };
        "x86_64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-x86_64.dmg";
          sha256 = "sha256-A04qHbc1UcPCoZPe5etd0pId1zQxfChfBri11uRpB7g=";
        };
        "aarch64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-aarch64.dmg";
          sha256 = "sha256-a2xUjGt5y7Z0U9imTbbcyytVh6gSGrluWtJE6RlBWMU=";
        };
      };
    in
    sources.${stdenv.hostPlatform.system};

  sourceRoot = lib.optional stdenv.hostPlatform.isDarwin ".";

  nativeBuildInputs = [
    wrapGAppsHook3
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    autoPatchelfHook
    patchelfUnstable
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    undmg
  ];

  buildInputs = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libXtst
  ];

  runtimeDependencies = [
    curl
    pciutils
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    libva.out
  ];

  appendRunpaths = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    "${pipewire}/lib"
  ];

  # Firefox uses "relrhack" to manually process relocations from a fixed offset
  patchelfFlags = [ "--no-clobber-old-sections" ];

  # don't break code signing
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase =
    if stdenv.hostPlatform.isDarwin then
      ''
        mkdir -p $out/Applications
        mv Glide*.app "$out/Applications/${applicationName}.app"
      ''
    else
      ''
        mkdir -p $prefix/lib $out/bin
        cp -r . $prefix/lib/glide-browser-bin-${version}

        ln -s $prefix/lib/glide-browser-bin-${version}/glide $out/bin/${binaryName}

        # See: https://github.com/mozilla/policy-templates/blob/master/README.md
        mkdir -p $out/lib/glide-browser-bin-${version}/distribution/
        ln -s ${policiesJson} $out/lib/glide-browser-bin-${version}/distribution/policies.json
      '';

  passthru = {
    inherit binaryName;
    inherit applicationName;
    libName = "glide-browser-bin-${version}";
    ffmpegSupport = true;
    gssSupport = true;
    inherit gtk3;
    updateScript = nix-update-script {
      extraArgs = [
        "--url"
        "https://github.com/glide-browser/glide"
      ];
    };
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
    mainProgram = "glide";
  };
}
