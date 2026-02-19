{
  description = "Flake for glide-browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  inputs.home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, home-manager, nixpkgs, ... }:
  let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    packages = forAllSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        glide = pkgs.callPackage ./package.nix { };
      in rec {
        glide-browser-bin-unwrapped = glide;
        glide-browser-bin = pkgs.wrapFirefox glide-browser-bin-unwrapped {
          pname = "glide-browser";
        };
        default = glide-browser-bin;
      }
    );

    homeModules = {
      default = import ./hm-module.nix {
        inherit self home-manager;
      };
    };

    overlays.default = final: prev: {
      glide-browser-bin-unwrapped = final.callPackage ./package.nix { };
      glide-browser-bin = final.wrapFirefox (final.callPackage ./package.nix { }) {
        pname = "glide-browser";
      };
    };
  };
}
