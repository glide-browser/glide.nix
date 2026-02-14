# glide.nix

A binary package for [Glide Browser](https://glide-browser.app) until Glide is in nixpkgs ([PR](https://github.com/NixOS/nixpkgs/pull/447604)).

This is mostly based off of https://git.pyrox.dev/pyrox/nix/src/branch/main/packages/glide-browser-bin/package.nix, and adapted to support multiple architectures.

The browser can be configured declaratively by passing policies to the package:

### With flakes
```nix
environment.systemPackages = [
  (inputs.glide.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    policies = {
	  AutofillAddressEnabled = true;
	  AutofillCreditCardEnabled = false;
	  DisableAppUpdate = true;
	  DisableFeedbackCommands = true;
	  DisableFirefoxStudies = true;
	  DisablePocket = true;
	  DisableTelemetry = true;
	  DontCheckDefaultBrowser = true;
	  NoDefaultBookmarks = true;
	  OfferToSaveLogins = false;
	  EnableTrackingProtection = {
		Value = true;
		Locked = true;
		Cryptomining = true;
		Fingerprinting = true;
	  };
	};
  })
];
```
With `glide` being your flake input for glide.

### Without flakes
```nix
environment.systemPackages = [
  (pkgs.callPackage /path/to/glide.nix/package.nix {
	policies = {
	  AutofillAddressEnabled = true;
	  AutofillCreditCardEnabled = false;
	  DisableAppUpdate = true;
	  DisableFeedbackCommands = true;
	  DisableFirefoxStudies = true;
	  DisablePocket = true;
	  DisableTelemetry = true;
	  DontCheckDefaultBrowser = true;
	  NoDefaultBookmarks = true;
	  OfferToSaveLogins = false;
	  EnableTrackingProtection = {
		Value = true;
		Locked = true;
		Cryptomining = true;
		Fingerprinting = true;
	  };
	};
  })
];
```

For more policies [read this](https://mozilla.github.io/policy-templates/).
