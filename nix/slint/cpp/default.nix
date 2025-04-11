{
  src, version,

  lib, stdenv, fetchFromGitHub, linkFarm, runCommand, rustPlatform, addDriverRunpath,

  cmake, pkg-config, gn, cargo, corrosion, rustc, ninja,

  slint,

  libGL, xorg, libxkbcommon, wayland, fontconfig,

  backend ? "winit", renderer ? "femtovg",

  qt6,
  seatd, udev, libinput, libgbm,

  rust-skia-patched, python3
}:

assert lib.assertOneOf "backend"  backend  [ "winit"   "qt"   "linuxkms" ];
assert lib.assertOneOf "renderer" renderer [ "femtovg" "skia" "software" ];

stdenv.mkDerivation rec {
  pname = "slint-cpp";

  inherit version;
  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
    cargo
    rustc
    rustPlatform.cargoSetupHook
    addDriverRunpath
  ] ++ lib.optionals (renderer == "skia") [
    python3
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    corrosion
    libGL
    xorg.libxcb
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    libxkbcommon
    wayland
  ] ++ lib.optionals (backend == "qt") [
    qt6.qtbase
  ] ++ lib.optionals (backend == "linuxkms") [
    seatd
    udev
    libinput
    libgbm
  ] ++ lib.optionals (renderer == "skia") [
    rust-skia-patched
    fontconfig
  ];

  propagatedBuildInputs = [
    slint.tools.compiler
  ];

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${src}/Cargo.lock";
  };

  auditable = false;

  cmakeFlags = [
    (lib.cmakeFeature "SLINT_COMPILER"                     "${slint.tools.compiler}/bin/slint-compiler")
    (lib.cmakeBool    "SLINT_FEATURE_BACKEND_WINIT"        (backend  == "winit"))
    (lib.cmakeBool    "SLINT_FEATURE_BACKEND_QT"           (backend  == "qt"))
    (lib.cmakeBool    "SLINT_FEATURE_BACKEND_LINUXKMS"     (backend  == "linuxkms"))
    (lib.cmakeBool    "SLINT_FEATURE_RENDERER_FEMTOVG"     (renderer == "femtovg"))
    (lib.cmakeBool    "SLINT_FEATURE_RENDERER_SKIA"        (renderer == "skia"))
    (lib.cmakeBool    "SLINT_FEATURE_RENDERER_SKIA_OPENGL" (renderer == "skia"))
    (lib.cmakeBool    "SLINT_FEATURE_RENDERER_SKIA_VULKAN" (renderer == "skia"))
    (lib.cmakeBool    "SLINT_FEATURE_RENDERER_SOFTWARE"    (renderer == "software"))
  ];

  dontWrapQtApps = true;
  doCheck = false;

  postFixup = ''
    function addDynamicLibrariesRunpath() {
      local file="$1"
      local origRpath="$(patchelf --print-rpath "$file")"
      patchelf --set-rpath "${lib.makeLibraryPath ([ libGL libxkbcommon wayland fontconfig ] ++ rust-skia-patched.buildInputs)}:$origRpath" "$file"
    }

    so="$out/lib/libslint_cpp.so"

    addDynamicLibrariesRunpath "$so"
    addDriverRunpath "$so"
  '';

  env = lib.optionalAttrs (renderer == "skia") {
    SKIA_SOURCE_DIR = "${rust-skia-patched}/";
    SKIA_LIBRARY_SEARCH_PATH = "${rust-skia-patched}/lib";
    SKIA_BUILD_DEFINES = builtins.readFile "${rust-skia-patched}/include/skia/skia-defines.txt";
  };
}
