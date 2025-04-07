{
  src, version,

  lib, stdenv, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "slint-compiler";

  inherit version;
  inherit src;

  nativeBuildInputs = [
    # NOP
  ];

  buildInputs = [
    # NOP
  ];

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
  };

  cargoBuildFlags = [
    "--package slint-compiler"
  ];

  auditable = false;
  doCheck = false;
}
