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
  inherit (lib) mkIf types;
  inherit (lib.options) mkOption;

  cfg = config.programs.glide-browser;

  applicationName = "Glide";
  modulePath = [
    "programs"
    "glide-browser"
  ];

  mkFirefoxModule = import "${home-manager.outPath}/modules/programs/firefox/mkFirefoxModule.nix";

  pathOrStr = types.either types.path types.str;

  rawType = types.submodule {
    options = {
      __raw = mkOption {
        type = types.str;
      };
    };
  };

  modeEnum = types.enum [
    "normal"
    "insert"
    "visual"
    "hint"
    "ignore"
    "command"
    "op-pending"
  ];

  keymapOptionsType = types.submodule {
    options = {
      description = mkOption {
        type = types.nullOr types.str;
      };
      buffer = mkOption {
        type = types.nullOr types.bool;
        description = ''
          If `true`, applies the mapping for the current buffer instead of globally.
        '';
        default = null;
      };
      retain_key_display = mkOption {
        type = types.nullOr types.bool;
        description = ''
          If true, the key sequence will be displayed even after the mapping is executed.

          This is useful for mappings that are conceptually chained but are not *actually*, e.g. `diw`.
        '';
        default = null;
      };
    };
  };

  addonOptionsType = types.submodule {
    options = {
      force = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      private_browsing_allowed = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
    };
  };

  keymapType = types.submodule {
    options = {
      enable = mkOption {
        default = true;
        example = false;
        description = ''
          Whether to enable the keymap.
        '';
      };
      modes = mkOption {
        type = types.either modeEnum (types.nonEmptyListOf modeEnum);
        description = ''
          Modes to enable the keymap.
        '';
      };
      key = mkOption {
        type = types.str;
        description = ''
          The key to map.
        '';
        example = "<C-m>";
      };
      action = mkOption {
        type = types.either types.str rawType;
        description = ''
          The action to execute.
        '';
      };
      options = mkOption {
        type = types.nullOr keymapOptionsType;
        default = null;
      };
    };
  };

  searchEngineType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
      };

      keyword = mkOption {
        type = types.nullOr (types.either types.str (types.listOf types.str));
        default = null;
      };

      search_url = mkOption {
        type = types.str;
      };

      favicon_url = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      suggest_url = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      search_url_get_params = mkOption {
        type = types.nullOr types.str;
        description = "GET parameters to the search_url as a query string.";
        default = null;
      };

      search_url_post_params = mkOption {
        type = types.nullOr types.str;
        description = "POST parameters to the search_url as a query string.";
        default = null;
      };

      suggest_url_get_params = mkOption {
        type = types.nullOr types.str;
        description = "GET parameters to the suggest_url as a query string.";
        default = null;
      };

      suggest_url_post_params = mkOption {
        type = types.nullOr types.str;
        description = "POST parameters to the suggest_url as a query string.";
        default = null;
      };

      encoding = mkOption {
        type = types.nullOr types.str;
        description = "Encoding of the search term.";
        default = null;
      };

      is_default = mkOption {
        type = types.nullOr types.bool;
        description = "Sets the default engine to a built-in engine only.";
        default = null;
      };
    };
  };

  autocmdsType = types.submodule {
    options = {
      event = mkOption {
        type = types.enum [
          "UrlEnter"
          "ModeChanged"
          "KeyStateChanged"
          "ConfigLoaded"
          "WindowLoaded"
          "CommandLineExit"
        ];
      };
      pattern = mkOption {
        type = types.nullOr (
          types.oneOf [
            types.str
            rawType
            (types.submodule {
              options = {
                hostname = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                };
              };
            })
          ]
        );
      };
      callback = mkOption { };
    };
  };

  excmdsType = types.submodule {
    options = {
      info = {
        name = mkOption {
          type = types.str;
        };
        description = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
      };
      fn = mkOption {
        type = types.str;
      };
    };
  };

  addonType = types.submodule {
    options = {
      url = mkOption {
        type = types.str;
      };
      options = mkOption {
        type = types.nullOr addonOptionsType;
        default = null;
      };
    };
  };

  optionsType = types.submodule {
    options = {
      mapping_timeout = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      yank_highlight = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      yank_highlight_time = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      which_key_delay = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      jumplist_max_entries = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      hint_size = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      hint_chars = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      hint_label_generator = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      switch_mode_on_focus = mkOption {
        type = types.nullOr types.bool;
        default = null;
      };
      scroll_implementation = mkOption {
        type = types.nullOr (
          types.enum [
            "keys"
            "legacy"
          ]
        );
        default = null;
      };
      native_tabs = mkOption {
        type = types.nullOr (
          types.enum [
            "show"
            "hide"
            "autohide"
          ]
        );
        default = null;
      };
      newtab_url = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      go_next_patterns = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
      };
      go_previous_patterns = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
      };
      keymaps_use_physical_layout = mkOption {
        type = types.nullOr (
          types.enum [
            "never"
            "for_macos_option_modifier"
            "force"
          ]
        );
        default = null;
      };
      keyboard_layout = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      keyboard_layouts = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
      };
    };
  };

  indent = level: lib.concatStrings (builtins.genList (_: "  ") level);

  isEmpty = v: v == null || (builtins.isAttrs v && v == { }) || (builtins.isList v && v == [ ]);

  toTS =
    let
      go =
        level: value:

        if builtins.isAttrs value && value ? __raw then
          lib.strings.removePrefix "\n" (
            lib.strings.removeSuffix ";" (lib.strings.removeSuffix "\n" value.__raw)
          )

        else if builtins.isAttrs value then
          let
            filtered = lib.filterAttrs (_: v: !isEmpty v) value;

            entries = lib.mapAttrsToList (
              name: val: indent (level + 1) + name + ": " + go (level + 1) val
            ) filtered;
          in
          if entries == [ ] then
            "{}"
          else
            "{\n" + lib.concatStringsSep ",\n" entries + "\n" + indent level + "}"

        else if builtins.isList value then
          let
            filtered = builtins.filter (v: !isEmpty v) value;
            items = map (v: indent (level + 1) + go (level + 1) v) filtered;
          in
          if items == [ ] then "[]" else "[\n" + lib.concatStringsSep ",\n" items + "\n" + indent level + "]"
        else if builtins.isString value then
          "\"${value}\""

        else if builtins.isBool value then
          if value then "true" else "false"

        else if builtins.isInt value then
          toString value

        else
          throw "Unsupported type in toTypescript";

    in
    value: go 0 value;

  indentLines =
    str:
    let
      cleaned = lib.strings.removePrefix "\n" str;
      lines = lib.splitString "\n" cleaned;
    in
    lib.concatStringsSep "\n" (map (line: if line == "" then "" else "  " + line) lines);

  parsePathOrStr =
    v: lib.strings.removeSuffix "\n" (if builtins.typeOf v == "path" then builtins.readFile v else v);

  maps = {
    keymaps =
      v:
      map (
        x:
        if x.enable then
          let
            options = if x.options != null then ", ${toTS x.options}" else "";
          in
          ''glide.keymaps.set(${toTS x.modes}, "${x.key}", ${(toTS x.action)}${options});''
        else
          ""
      ) v;

    prefs =
      v: map ({ name, value }: ''glide.prefs.set("${name}", ${toTS value});'') (lib.attrsToList v);

    searchEngines = v: map (x: "glide.search_engines.add(${toTS x});") v;

    autocmds =
      v:
      map (
        x:
        let
          callback = toTS {
            __raw = x.callback;
          };
        in
        ''glide.autocmds.create("${x.event}", ${toTS x.pattern}, ${callback});''
      ) v;

    excmds = v: map (x: "glide.excmds.create(${toTS x.info}, ${toTS { __raw = x.fn; }});") v;

    styles = v: map (x: "glide.styles.add(`\n${indentLines (parsePathOrStr x)}`);") v;

    extraConfig =
      v: if builtins.typeOf v == "list" then map parsePathOrStr v else [ (parsePathOrStr v) ];

    addons =
      v:
      map (
        x:
        let
          options = if x.options != null then ", ${toTS x.options}" else "";
        in
        ''glide.addons.install("${x.url}"${options});''
      ) v;

    options =
      v:
      map (
        x:
        let
          type = builtins.typeOf x.value;
        in
        if type != "null" then "glide.o.${x.name} = ${toTS x.value};" else ""
      ) (lib.attrsToList v);
  };

  parse =
    value: mapFn:
    if value != [ ] && value != null then
      lib.concatStringsSep "\n" (builtins.filter (x: x != "") (mapFn value))
    else
      "";

  notNull = var: callback: if var != null then callback (lib.strings.removeSuffix "\n" var) else "";
in
{
  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = applicationName;
      description = "Extensible and keyboard-focused web browser, based on Firefox (binary package)";
      wrappedPackageName = "(self.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin)";
      unwrappedPackageName = "(self.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin-unwrapped)";
      platforms.linux = {
        configPath = ".config/glide/glide";
      };
      platforms.darwin = {
        configPath = "Library/Application Support/Glide Browser";
      };
    })
  ];

  options.programs.glide-browser = {
    settings = {
      mapleader = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      label_generators = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      options = mkOption {
        type = types.nullOr optionsType;
        default = null;
      };

      preferences = mkOption {
        type = types.attrsOf (
          types.oneOf [
            types.str
            types.int
            types.bool
          ]
        );
        default = { };
      };

      keymaps = mkOption {
        type = types.listOf keymapType;
        default = [ ];
      };

      search_engines = mkOption {
        type = types.listOf searchEngineType;
        default = [ ];
      };

      autocmds = mkOption {
        type = types.listOf autocmdsType;
        default = [ ];
      };

      excmds = mkOption {
        type = types.listOf excmdsType;
        default = [ ];
      };
    };

    addons = mkOption {
      type = types.listOf addonType;
      default = [ ];
    };

    extraConfig = mkOption {
      type = types.either pathOrStr (types.listOf pathOrStr);
      default = [ ];
    };

    styles = mkOption {
      type = types.listOf pathOrStr;
      default = [ ];
    };
  };

  config = mkIf cfg.enable {
    programs.glide-browser = {
      package = lib.mkDefault (
        pkgs.wrapFirefox
          (self.packages.${pkgs.stdenv.hostPlatform.system}.glide-browser-bin-unwrapped.override {
            policies = cfg.policies;
          })
          {
            pname = "glide-browser-bin";
          }
      );
    };

    home.file =
      let
        inherit (pkgs.stdenv) isDarwin;
        nativeMessagingHostPath =
          if isDarwin then
            "Library/Application Support/Glide Browser/NativeMessagingHosts"
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
      lib.mkMerge [
        (mkIf (cfg.nativeMessagingHosts != [ ]) {
          "${nativeMessagingHostPath}" = {
            source = "${packageJoin}/lib/mozilla/native-messaging-hosts";
            recursive = true;
            ignorelinks = true;
          };
        })
        {
          ".config/glide/glide.ts".text =
            "/// <reference path=\"${config.home.homeDirectory}/.config/glide/glide.d.ts\" />\n"
            + "// File generated by home manager \n\n"
            + (lib.concatStringsSep "\n\n" (
              builtins.filter (x: x != "") [
                (notNull cfg.settings.mapleader (x: "glide.g.mapleader = \"${x}\""))
                (notNull cfg.settings.label_generators (x: "glide.hints.label_generators = ${x}"))
                (parse cfg.settings.preferences maps.prefs)
                (parse cfg.settings.options maps.options)
                (parse cfg.settings.search_engines maps.searchEngines)
                (parse cfg.settings.excmds maps.excmds)
                (parse cfg.settings.keymaps maps.keymaps)
                (parse cfg.settings.autocmds maps.autocmds)
                (parse cfg.addons maps.addons)
                (parse cfg.extraConfig maps.extraConfig)
                (parse cfg.styles maps.styles)
              ]
            ))
            + "\n";
        }
      ];
  };
}
