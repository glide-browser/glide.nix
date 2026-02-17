{
  home-manager,
  self,
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.glide-browser;

  applicationName = "Glide Browser";
  modulePath = [
    "programs"
    "glide-browser"
  ];

  mkFirefoxModule = import "${home-manager.outPath}/modules/programs/firefox/mkFirefoxModule.nix";
in
{
  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = applicationName;
      description = "Extensible and keyboard-focused web browser, based on Firefox (binary package)";
      wrappedPackageName = "(self.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin)";
      unwrappedPackageName = "(self.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin-unwrapped)";
      visible = true;
      platforms.linux = {
        configPath = ".config/glide/glide";
      };
      platforms.darwin = {
        configPath = "Library/Application Support/glide";
      };
    })
  ];

  config = mkIf cfg.enable {
    programs.glide-browser = {
      package = lib.mkDefault (
        pkgs.wrapFirefox (self.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin-unwrapped.override
          {
            policies = cfg.policies;
          }
        ) {
          pname = "glide-browser-bin";
        }
      );
    };

    home.file =
      let
        inherit (pkgs.stdenv) isDarwin;
        nativeMessagingHostPath =
          if isDarwin then
            "~/Library/Application Support/Glide Browser/NativeMessagingHosts"
          else
            ".glide-browser/native-messaging-hosts";
        packageJoin = pkgs.symlinkJoin {
          name = "glide-native-messaging-hosts";
          paths = lib.flatten (
            lib.concatLists [
              cfg.nativeMessagingHosts
            ]
          );
        };
      in
      mkIf (cfg.nativeMessagingHosts != [ ]) {
        "${nativeMessagingHostPath}" = {
          source = "${packageJoin}/lib/mozilla/native-messaging-hosts";
          recursive = true;
          ignorelinks = true;
        };
      };
  };
}
