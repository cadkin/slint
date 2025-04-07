{
  src, version,

  lib, stdenv, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "slint-viewer";

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
    "--package slint-viewer"
  ];

  auditable = false;
  doCheck = false;
}
