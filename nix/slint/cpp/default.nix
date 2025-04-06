{
  src, version,

  lib, stdenv, rustPlatform, addDriverRunpath,

  cmake, pkg-config, cargo, corrosion, rustc, ninja,

  libGL, xorg, libxkbcommon, wayland, fontconfig
}:

stdenv.mkDerivation rec {
  pname = "slint-api-cpp";

  inherit version;
  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
    cargo
    rustc
    rustPlatform.bindgenHook
    rustPlatform.cargoSetupHook
    addDriverRunpath
  ];

  buildInputs = [
    libGL
    xorg.libxcb
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libxcb
    libxkbcommon
    wayland
    corrosion
  ];

  propagatedBuildInputs = [
    fontconfig
  ];

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
  };

  auditable = false;
  doCheck = false;

  #postPatch = ''
  #  ln -s ${lockFile} Cargo.lock
  #'';
}
