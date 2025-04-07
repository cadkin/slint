{
  src, version,

  lib, stdenv, rustPlatform, addDriverRunpath,

  libGL, xorg, libxkbcommon, wayland, fontconfig
}:

rustPlatform.buildRustPackage rec {
  pname = "slint-viewer";

  inherit version;
  inherit src;

  nativeBuildInputs = [
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
  ];

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
  };

  cargoBuildFlags = [
    "--package slint-viewer"
  ];

  auditable = false;
  doCheck = false;

  postFixup = ''
    function addDynamicLibrariesRunpath() {
      local file="$1"
      local origRpath="$(patchelf --print-rpath "$file")"
      patchelf --set-rpath "${lib.makeLibraryPath [
        libGL
        libxkbcommon
        wayland
        fontconfig
        xorg.libxcb
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
      ]}:$origRpath" "$file"
    }

    exec="$out/bin/slint-viewer"

    addDynamicLibrariesRunpath "$exec"
    addDriverRunpath "$exec"
  '';
}

