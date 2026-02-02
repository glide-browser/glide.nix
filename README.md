# glide.nix

A binary package for [Glide Browser](https://glide-browser.app) until Glide is in nixpkgs ([PR](https://github.com/NixOS/nixpkgs/pull/447604)).

This was originally based off of [pyrox](https://git.pyrox.dev/pyrox/nix)'s work, and adapted to support multiple architectures.

## Features

- Linux and macOS support
- Available for _x86_64_ and _aarch64_
- Policies support: [read this](https://mozilla.github.io/policy-templates/).
- Home Manager module

## Installation

### With flakes

Add it is as a flake input:

```nix
inputs = {
  glide = {
    url = "github:glide-browser/glide.nix";
    # optionally: follow your flake's inputs
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.home-manager.follows = "home-manager";
  };
}
```

#### environment.systemPackages or home.packages

```nix
environment.systemPackages = [
  (inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    policies = {
	  AutofillAddressEnabled = true;
	  AutofillCreditCardEnabled = false;
      # ...
	};
  })
];

home.packages = [
  (inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    policies = {
	  AutofillAddressEnabled = true;
	  AutofillCreditCardEnabled = false;
      # ...
	};
  })
];
```

#### Home Manager Module

```nix
programs.glide-browser.enable = true;

```

This repo uses `mkFirefoxModule` from Home Manager.
Take a look at [Home Manager references](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.enable) for more options.

### Without flakes

```nix
environment.systemPackages = [
  (pkgs.callPackage /path/to/glide.nix/package.nix {
	policies = {
	  AutofillAddressEnabled = true;
	  AutofillCreditCardEnabled = false;
      # ...
	};
  })
];
```
