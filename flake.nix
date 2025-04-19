{
  description = "A declarative GUI toolkit to build native user interfaces";

  inputs = {
    nixpkgs.url   = github:NixOS/nixpkgs;
    utils.url     = github:numtide/flake-utils;
  };

  outputs = inputs @ { self, utils, ... }: utils.lib.eachDefaultSystem (system: let
    config = rec {
      pkgs = import inputs.nixpkgs {
        inherit system;
      };

      stdenv = llvm.stdenv;

      llvm = rec {
        packages = pkgs.llvmPackages_19;
        stdenv   = packages.stdenv;

        tooling = rec {
          lldb = packages.lldb;
          clang-tools = packages.clang-tools;
          clang-tools-libcxx = clang-tools.override {
            enableLibcxx = true;
          };
        };
      };
    };
  in with config; rec {
    inherit config;

    fetchVersion = let
      toml = lib.pipe ./Cargo.toml [
        builtins.readFile
        builtins.fromTOML
      ];
    in toml.workspace.package.version;

    lib = rec {
      mkPackages = { pkgs, stdenv ? pkgs.stdenv }: let
        mkSlintArgs = {
          # Filter out nix sources so they don't incur extra rebuilds.
          src = lib.pipe ./. [
            lib.sources.cleanSource
            lib.fileset.fromSource
            (fileset: lib.fileset.difference
              fileset
              (lib.fileset.fileFilter (file: file.hasExt "nix") ./.)
            )
            (fileset: lib.fileset.toSource { root = ./.; inherit fileset; })
          ];
          version = fetchVersion;
          inherit stdenv;
        };
      in rec {
        nixpkgs = pkgs;

        callPackage = lib.callPackageWith (pkgs // { inherit slint; });

        slint = rec {
          api = {
            cpp = callPackage ./nix/slint/cpp mkSlintArgs;
          };
          tools = {
            compiler = callPackage ./nix/slint/compiler mkSlintArgs;
            viewer   = callPackage ./nix/slint/viewer   mkSlintArgs;
          };
        };
      };
    } // config.pkgs.lib;

    legacyPackages = {
      inherit (lib.mkPackages { inherit pkgs stdenv; } ) nixpkgs slint;
    };

    overlays = rec {
      default = slint;

      slint = finalPkgs: prevPkgs: {
        inherit (legacyPackages) slint;
      };
    };
  });
}
