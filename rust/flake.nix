{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        name = "myapp";
        version = "0.1.0";
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (import inputs.rust-overlay)
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nil
            (rust-bin.stable.latest.default.override {
              extensions = ["rust-src"];
            })
            rust-analyzer
          ];
        };

        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            mdformat.enable = true;
            rustfmt.enable = true;
          };
        };

        packages.default = pkgs.rustPlatform.buildRustPackage {
          pname = name;
          inherit version;

          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;

          buildInputs = with pkgs; [
            # If your project depends on the openssl crate, you need to add
            openssl
            openssl.dev
          ];

          nativeBuildInputs = with pkgs; [
            pkgs-config
          ];
        };

        # If you develop a library, you should remove this `apps.default` attribute.
        apps.default = {
          type = "app";
          program = "${self'.packages.default}/bin/${name}";
        };
      };
    };
}
