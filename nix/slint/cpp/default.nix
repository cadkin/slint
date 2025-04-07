{
  src, version,

  lib, stdenv, rustPlatform, addDriverRunpath,

  cmake, pkg-config, cargo, corrosion, rustc, ninja,

  slint,

  libGL, xorg, libxkbcommon, wayland, fontconfig,

  backend ? "winit", renderer ? "femtovg",

  qt6, seatd
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
  ];

  buildInputs = [
    corrosion
  ] ++ lib.optionals (backend == "qt") [
    qt6.qtbase
  ] ++ lib.optionals (backend == "linuxkms") [
    seatd
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
      patchelf --set-rpath "${lib.makeLibraryPath [ libGL libxkbcommon wayland fontconfig ]}:$origRpath" "$file"
    }

    so="$out/lib/libslint_cpp.so"

    addDynamicLibrariesRunpath "$so"
    addDriverRunpath "$so"
  '';
}
