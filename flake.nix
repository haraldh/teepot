{
  description = "teepot";

  nixConfig = {
    extra-substituters = [ "https://attic.teepot.org/cache" ];
    extra-trusted-public-keys = [ "cache:uLQovCi1QU+B4PPXhue3z7y2NqznyEJIsGiENpNZtiI=" ];
  };

  inputs = {
    nixpkgs-25-11.url = "github:nixos/nixpkgs/nixos-25.11";
    nixsgx-flake.url = "github:haraldh/nixsgx";
    nixpkgs.follows = "nixsgx-flake/nixpkgs";
    snowfall-lib.follows = "nixsgx-flake/snowfall-lib";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixsgx-flake/nixpkgs";
    };

    crane.url = "github:ipetkov/crane?ref=efd36682371678e2b6da3f108fdb5c613b3ec598"; # v0.20.3
  };

  outputs =
    inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall.namespace = "teepot";

      channels-config = {
        allowUnfree = true;
      };

      overlays = with inputs; [
        nixsgx-flake.overlays.default
        rust-overlay.overlays.default
        (next: prev: {
          inherit (inputs.nixpkgs-25-11.legacyPackages.${prev.system})
            cargo-deny
            ;
        })
      ];

      alias = {
        packages = {
          default = "teepot";
        };
        shells = {
          default = "teepot";
        };
        devShells = {
          default = "teepot";
        };
      };

      outputs-builder = channels: {
        formatter = channels.nixpkgs.nixfmt-rfc-style;
      };
    };
}
