{
  lib, clangStdenv, fetchFromGitHub,

  skia
}:

(skia.overrideAttrs (final: prev: {
  pname   = "rust-skia";
  version = "m135-0.83.1";

  src = fetchFromGitHub {
    owner = "rust-skia";
    repo  = "skia";
    rev   = "m135-0.83.1";
    hash  = "sha256-TSGPJl9DfWQtrkNIhv40s8VcuudCjbiSh+QjLc0hKN4=";
  };

  gnFlags = [
    "skia_enable_pdf=true"
    "skia_enable_gpu=true"
    "skia_enable_skshaper=true"
    "skia_use_gl=true"
    "skia_use_system_libjpeg_turbo = true"
  ] ++ (lib.remove "is_component_build=true" prev.gnFlags);

  postInstall = ''
    echo "Copying duplicate include paths for bindings generation"
    cp -r $out/include/skia/* $out/include/
    cp -r -L $src/src $out/

    flags=$(for f in obj/*.ninja; do sed -nE 's/defines = (.*)/\1/p' "$f"; done | tr ' ' '\n' | sort | uniq | tr '\n' ' ')
    echo "Define flags: $flags"

    echo "$flags" > $out/include/skia/skia-defines.txt
  '';
})).override {
  stdenv = clangStdenv;
}
