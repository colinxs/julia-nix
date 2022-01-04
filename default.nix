{ lib
, dev
, pkgs
, callPackage
, callPackages
, stdenv

# nativeBuildInputs Required by Julia
,  python3
,  gfortran
,  perl
,  curl
,  gawk
,  gnupatch
,  cmake
,  pkg-config
,  which

,  # TODO temp/debug
,  ripgrep
,  file
,  cacert
,  openssl
}:


with lib;

# See:
# https://github.com/JuliaLang/julia/blob/master/doc/build/build.md
# https://github.com/JuliaLang/julia/blob/master/doc/build/distributing.md
# https://github.com/JuliaLang/julia/blob/master/doc/build/linux.md

let
  inherit (julia-utils) checkVersion toPretty myTrace makeDep parseDeps;
  julia-utils = callPackages ./julia-utils { };

  julia = (callPackage ./NixManifest.nix { }).julia;
  src = julia.meta.assets."julia-${julia.version}-full.tar.gz";

  # Patched deps (see ./deps/patches in Julia repo)
  # - gmp
  # - libgit2
  # - libunwind
  # - llvm
  # - mbedtls
  # - openblas
  # - p7zip
  # - pcre2
  # - SuiteSparse
in
