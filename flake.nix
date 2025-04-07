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
          src = self;
          version = fetchVersion;
          inherit stdenv;
        };
      in rec {
        nixpkgs = pkgs;

        callPackage = pkgs.lib.callPackageWith (pkgs // { inherit slint; });

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

    packages = rec {
      default = slint-cpp;
      slint-cpp = legacyPackages.slint.api.cpp;
    };

    overlays = rec {
      default = slint;

      slint = finalPkgs: prevPkgs: {
        inherit (legacyPackages) slint;
      };
    };

    devShells = rec {
      default = slintDev;

      # Main developer shell.
      slintDev = pkgs.mkShell.override { inherit stdenv; } rec {
        name = "slint-dev";

        packages = [
          pkgs.git

          llvm.tooling.lldb
          llvm.tooling.clang-tools
        ] ++ lib.optionals stdenv.isLinux [
          pkgs.cntr
        ];

        inputsFrom = [
          legacyPackages.slint.api.cpp
        ];
      };
    };
  });
}
