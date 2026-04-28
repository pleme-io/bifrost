{
  description = "Toride — split-horizon DNS daemon for LAN/Tailscale networks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    crate2nix.url = "github:nix-community/crate2nix";
    flake-utils.url = "github:numtide/flake-utils";
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, crate2nix, flake-utils, substrate }:
    let
      flakeOutputs = (import "${substrate}/lib/rust-tool-release-flake.nix" {
        inherit nixpkgs crate2nix flake-utils;
      }) {
        toolName = "toride";
        src = self;
        repo = "pleme-io/bifrost";
      };
    in
    flakeOutputs // {
      homeManagerModules.default = import ./module {
        hmHelpers = import "${substrate}/lib/hm-service-helpers.nix" { lib = nixpkgs.lib; };
        packages = flakeOutputs.packages;
      };

      # System-level bridge: reads blackmatter.networkTopology → sets HM toride options
      nixosModules.default = import ./module/system-bridge.nix;
      darwinModules.default = import ./module/system-bridge.nix;
    };
}
