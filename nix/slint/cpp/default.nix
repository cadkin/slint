{
  src, version,

  lib, stdenv, rustPlatform, addDriverRunpath,

  cmake, pkg-config, cargo, corrosion, rustc, ninja,

  libGL, xorg, libxkbcommon, wayland, fontconfig
}:

stdenv.mkDerivation rec {
  pname = "slint-cpp";

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

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
  };

  auditable = false;
  doCheck = false;

  postFixup = ''
    function addDynamicLibrariesRunpath() {
      local file="$1"
      local origRpath="$(patchelf --print-rpath "$file")"
      patchelf --set-rpath "${lib.makeLibraryPath [ libGL libxkbcommon wayland fontconfig ]}:$origRpath" "$file"
    }

    so="$out/lib/libslint_cpp.so"

    addDynamicLibrariesRunpath "$so"
    addDriverRunpath "$so"
  '';
}
