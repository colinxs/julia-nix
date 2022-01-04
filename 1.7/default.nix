{ lib
, dev
, pkgs

  # build tools
, makeWrapper

, patchelf

  # libjulia dependencies
, libunwind
, utf8proc
, zlib

  # standard library dependencies
, curl
, libgit2
, mpfr
, openlibm
, pcre2
, libnghttp2
, libssh2
, p7zip

  # linear algebra
, blas
, openblas
, lapack
}:

with builtins;
with lib;

let
  julia = (callPackage ./NixManifest.nix { }).julia;
  src = julia.meta.assets."julia-${julia.version}-full.tar.gz";
in
{
  inherit (julia) version;
  inherit src;
  patches = [
    # ./patches/1.6/0001-reduce-precompile-failure-severity-to-a-warning-3990.patch
    # ./patches/1.6/generate_precompile.patch
    # ./patches/1.6/suitesparse.patch
    ./patches/1.7/0005-nix-Enable-parallel-unit-tests-for-sandbox.patch
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

    # Extra
    makeWrapper

    # TODO
    ripgrep
    file
    cacert
    openssl
  ];
  deps = [
    # {
    #   flags=["USE_SYSTEM_CSL=1"];
    # }
    # {
    #   flags=["USE_SYSTEM_LLVM=1"];
    # }
    # {
    #   use = false;
    #   buildInputs = [ libunwind ];
    #   makeFlags = [
    #     "USE_SYSTEM_LIBUNWIND=1"
    #     # "DISABLE_LIBUNWIND=0"
    #   ];
    # }
    # {
    #   use = false;
    #   buildInputs = [ pcre2.dev ];
    #   makeFlags = [
    #     "USE_SYSTEM_PCRE=1"
    #     "PCRE_CONFIG=${pcre2.dev}/bin/pcre2-config"
    #     "PCRE_INCL_PATH=${pcre2.dev}/include/pcre2.h"
    #   ];
    # }
    {
      use = checkVersion openlibm.version "0.7";
      buildInputs = [ openlibm ];
      makeFlags = [
        "USE_SYSTEM_OPENLIBM=1"
        "USE_SYSTEM_LIBM=0"
        # "UNTRUSTED_SYSTEM_LIBM=0"
      ];
    }
    # {
    #   flags=["USE_SYSTEM_DSFMT=1"];
    # }

    # {
    #   use = checkVersion blas.version 
    #   # use = !stdenv.isDarwin;
    #   buildInputs = [ blas ];
    #   # buildInputs = [ openblas ];
    #   makeFlags = [
    #     "USE_SYSTEM_BLAS=1"
    #     "USE_BLAS64=${if blas.isILP64 then "1" else "0"}"
    #   ];
    # }
    # {
    #   use = checkVersion openblas.version "0.3";
    #   buildInputs = [ openblas ];
    #   makeFlags = [
    #     "USE_SYSTEM_BLAS=1"
    #     "USE_BLAS64=${if openblas.blas64 then "1" else "0"}"
    #   ];
    # }

    {
      use = checkVersion lapack.version "3";
      buildInputs = [ lapack ];
      makeFlags = [ "USE_SYSTEM_LAPACK=1" ];
    }
    # {
    #   flags=["USE_SYSTEM_GMP=1"];
    # }
    {
      use = checkVersion mpfr.version "4.1";
      buildInputs = [ mpfr ];
      makeFlags = [ "USE_SYSTEM_MPFR=1" ];
    }
    # {
    #   flags=["USE_SYSTEM_SUITESPARSE=1"];
    # }
    # {
    #   flags=["USE_SYSTEM_LIBUV=1"];
    # }
    {
      use = checkVersion utf8proc.version "2.6";
      buildInputs = [ utf8proc ];
      makeFlags = [ "USE_SYSTEM_UTF8PROC=1" ];
    }
    # {
    #   flags=["USE_SYSTEM_MBEDTLS=1"];
    # }
    {
      use = checkVersion libssh2.version "1.9";
      buildInputs = [ libssh2 ];
      makeFlags = [ "USE_SYSTEM_LIBSSH2=1" ];
    }
    {
      use = checkVersion libnghttp2.version "1.41";
      buildInputs = [ libnghttp2.lib ];
      makeFlags = [ "USE_SYSTEM_NGHTTP2=1" ];
    }
    {
      use = checkVersion curl.version "7";
      buildInputs = [ curl ];
      makeFlags = [ "USE_SYSTEM_CURL=1" ];
    }
    # {
    #   use = false;
    #   buildInputs = [ libgit2 ];
    #   makeFlags = [ "USE_SYSTEM_LIBGIT2=1" ];
    # }
    {
      use = true;
      buildInputs = [ patchelf ];
      makeFlags = [ "USE_SYSTEM_PATCHELF=1" ];
    }
    {
      use = checkVersion zlib.version "1.2";
      buildInputs = [ zlib ];
      makeFlags = [ "USE_SYSTEM_ZLIB=1" ];
    }
    {
      use = true;
      buildInputs = [ p7zip ];
      makeFlags = [ "USE_SYSTEM_P7ZIP=1" ];
    }
  ];
}
