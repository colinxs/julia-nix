{ lib
, dev
, pkgs
, callPackage

, buildJulia
, checkVersion

  # build tools
, makeWrapper

, patchelf
, gmp

  # libjulia dependencies
, utf8proc
, zlib

  # standard library dependencies
, curl
, libgit2
, mpfr
, openlibm
, pcre2

  # linear algebra
, blas ? pkgs.openblas
, lapack
, suitesparse
}:

with builtins;
with lib;

let
  julia = (callPackage ./NixManifest.nix { }).julia;
  src = julia.meta.assets."julia-${julia.version}-full.tar.gz";
in
buildJulia {
  inherit (julia) version;
  inherit src;
  patches = [
    # ./patches/1.6/0001-reduce-precompile-failure-severity-to-a-warning-3990.patch
    # ./patches/1.6/generate_precompile.patch
    # ./patches/1.6/suitesparse.patch
    ./patches/0005-nix-Enable-parallel-unit-tests-for-sandbox.patch
  ];
  nativeBuildInputs = with pkgs; [
    # Required by Julia
    python3
    gfortran
    perl
    curl
    m4
    gawk
    gnupatch
    cmake
    pkg-config
    which

    # TODO
    ripgrep
    file
    cacert
    openssl
  ];
  deps = [
    USE_SYSTEM_CSL
    USE_SYSTEM_CURL
    USE_SYSTEM_LIBBLASTRAMPOLINE
    USE_SYSTEM_LIBSSH
    USE_SYSTEM_LIBSUITESPARSE
    USE_SYSTEM_LIBUNWIND
    USE_SYSTEM_LIBWHICH
    USE_SYSTEM_MBEDTLS
    USE_SYSTEM_NGHTTP
    USE_SYSTEM_P
    USE_SYSTEM_PATCHELF
    USE_SYSTEM_PCRE
    USE_SYSTEM_UTF
    USE_SYSTEM_ZLIB
  #
  #   # {
  #   #   flags=["USE_SYSTEM_LLVM=1"];
  #   # }
  #
  #   {
  #     buildInputs = [ 
  #       pcre2.dev
  #     ];
  #     makeFlags = [
  #       "USE_SYSTEM_PCRE=1"
  #       "PCRE_CONFIG=${pcre2.dev}/bin/pcre2-config"
  #       "PCRE_INCL_PATH=${pcre2.dev}/include/pcre2.h"
  #     ];
  #   }
  #
  #   {
  #     buildInputs = [ 
  #       openlibm 
  #     ];
  #     makeFlags = [
  #       "USE_SYSTEM_OPENLIBM=1"
  #       "USE_SYSTEM_LIBM=0"
  #       # "UNTRUSTED_SYSTEM_LIBM=0"
  #     ];
  #   }
  #
  #   # {
  #   #   buildInputs = [ 
  #   #     (assert (checkVersion "2.2"  PKGNAME); PKGNAME;
  #   #   ];
  #   #   makeFlags = [ "USE_SYSTEM_DSFMT=1" ];
  #   # }
  #
  #   {
  #     buildInputs = [ 
  #       # (assert (checkVersion "2.2"  blas); blas;
  #       blas
  #     ];
  #     makeFlags = [
  #       "USE_SYSTEM_BLAS=1"
  #       "USE_BLAS64=${if blas.isILP64 then "1" else "0"}"
  #     ];
  #   }
  #
  #   {
  #     buildInputs = [
  #       # (assert (checkVersion lapack.version "3"); lapack)
  #       lapack
  #     ];
  #     makeFlags = [ "USE_SYSTEM_LAPACK=1" ];
  #   }
  #
  #   {
  #     buildInputs = [
  #       gmp
  #     ];
  #     makeFlags = [ "USE_SYSTEM_GMP=1" ];
  #   }
  #   
  #   {
  #     buildInputs = [
  #       # (assert (checkVersion mpfr.version "6.1"); mpfr)
  #       mpfr
  #     ];
  #     makeFlags = [ "USE_SYSTEM_MPFR=1" ];
  #   }
  #
  #   {
  #     buildInputs = [
  #       # (assert (checkVersion suitesparse.version "4.4"); suitesparse)
  #       suitesparse
  #     ];
  #     makeFlags = [ "USE_SYSTEM_SUITESPARSE=1" ];
  #   }
  #
  #   # NOTE: Julia uses a custom fork of libuv. Small.
  #   # {
  #   #   flags=["USE_SYSTEM_LIBUV=1"];
  #   # }
  #
  #   {
  #     buildInputs = [
  #       utf8proc
  #     ];
  #     makeFlags = [ "USE_SYSTEM_UTF=1" ];
  #   }
  #
  #   {
  #     use = false;
  #     buildInputs = [ libgit2 ];
  #     makeFlags = [ "USE_SYSTEM_LIBGIT=1" ];
  #   }
  #
  #   {
  #     use = true;
  #     buildInputs = [ patchelf ];
  #     makeFlags = [ "USE_SYSTEM_PATCHELF=1" ];
  #   }
  #
  #   {
  #     buildInputs = [ zlib ];
  #     makeFlags = [ "USE_SYSTEM_ZLIB=1" ];
  #   }
  # ];
}
