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
  ffmpeg_9,
  gtk3,
  libxtst,
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

  version = "0.1.65a";
in

stdenv.mkDerivation {
  inherit pname version;

  src =
    let
      sources = {
        "x86_64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
          sha256 = "sha256-gjNbNbJOiK7ih8WhrQzE8o7MxQL/VGhv0mvLegLqwlc=";
        };
        "aarch64-linux" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-aarch64.tar.xz";
          sha256 = "sha256-rxqblqAeYNtr/jrcedJuxp+4urvYkYU/G5oJoZ6shxA=";
        };
        "x86_64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-x86_64.dmg";
          sha256 = "sha256-fIDWwgDCtM3E5YM/GINFZZosFv85iytJ8aChyuU7AXw=";
        };
        "aarch64-darwin" = fetchurl {
          url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.macos-aarch64.dmg";
          sha256 = "sha256-wbjp7xxI0mDMWcBCG/eF0H0XCw4fP7kZaHVsl4LaTNY=";
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
    libxtst
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

  installPhase = ''
    runHook preInstall
  ''
  + (
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
      ''
  )
  + ''
    runHook postInstall
  '';

  passthru = {
    inherit binaryName;
    inherit applicationName;
    libName = "glide-browser-bin-${version}";
    ffmpegPackage = ffmpeg_9;
    withFFmpeg = true;
    withGSSAPI = true;
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
