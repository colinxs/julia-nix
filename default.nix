{ lib
, dev
, pkgs
, callPackage
, callPackages

# nativeBuildInputs Required by Julia
# ,  python3
# ,  gfortran
# ,  perl
# ,  curl
# ,  gawk
# ,  gnupatch
# ,  cmake
# ,  pkg-config
# ,  which
#
# # TODO temp/debug
# ,  ripgrep
# ,  file
# ,  cacert
# ,  openssl
}:


with lib;

# See:
# https://github.com/JuliaLang/julia/blob/master/doc/build/build.md
# https://github.com/JuliaLang/julia/blob/master/doc/build/distributing.md
# https://github.com/JuliaLang/julia/blob/master/doc/build/linux.md

let
  julia-utils = callPackages ./julia-utils.nix { };

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
in {
  julia-stable = callPackage ./1.7 { 
    inherit (julia-utils) checkVersion buildJulia;
  };
}
