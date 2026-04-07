{
  description = "Toride — split-horizon DNS daemon for LAN/Tailscale networks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, substrate, devenv }:
  let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
    ];

    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.rustPlatform.buildRustPackage {
        pname = "toride";
        version = "0.1.0";
        src = ./.;
        cargoHash = "sha256-gbV1NY04pkNNkIxW/o1WW6ndvmIsOVcUC4UmJMmK29k=";
      };
    });
  in {
    inherit packages;

    homeManagerModules.default = import ./module {
      hmHelpers = import "${substrate}/lib/hm-service-helpers.nix" { lib = nixpkgs.lib; };
      inherit packages;
    };

    # System-level bridge: reads blackmatter.networkTopology → sets HM toride options
    nixosModules.default = import ./module/system-bridge.nix;
    darwinModules.default = import ./module/system-bridge.nix;

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = devenv.lib.mkShell {
        inputs = { inherit nixpkgs devenv; };
        inherit pkgs;
        modules = [{
          languages.rust.enable = true;
          packages = with pkgs; [ nixpkgs-fmt ];
        }];
      };
    });
  };
}
