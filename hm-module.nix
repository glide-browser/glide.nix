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
  inherit (lib)
    getAttrFromPath
    isPath
    mkIf
    mkOption
    setAttrByPath
    types
    ;

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
      wrappedPackageName = "glide-browser";
      unwrappedPackageName = "glide-browser-unwrapped";
      visible = true;
      platforms.linux = {
        configPath = ".config/glide/glide";
      };
      platforms.darwin = {
        # TODO: don't know?
        configPath = "Library/Application Support/Glide Browser";
      };
    })
  ];

  options.programs.glide-browser = { };

  config = mkIf cfg.enable {
    programs.glide-browser = {
      package = lib.mkDefault (
        (pkgs.wrapFirefox (self.packages.${pkgs.stdenv.hostPlatform.system}."glide-browser-unwrapped") { })
      );
    };
  };
}
