{ lib
, pkgs
, stdenv
, fetchzip
  # build tools
, gfortran
, m4
, makeWrapper
, patchelf
, perl
, which
, python2
, cmake
  # libjulia dependencies
, libunwind
, readline
, utf8proc
, zlib
  # standard library dependencies
, curl
, fftwSinglePrec
, fftw
, libgit2
, mpfr
, openlibm
, openspecfun
, pcre2
, libnghttp2
  # linear algebra
, blas
, lapack
, arpack
  # Darwin frameworks
, CoreServices
, ApplicationServices
}:

assert (!blas.isILP64) && (!lapack.isILP64);

with lib;

# See:
# https://github.com/JuliaLang/julia/blob/master/doc/build/build.md
# https://github.com/JuliaLang/julia/blob/master/doc/build/distributing.md
# https://github.com/JuliaLang/julia/blob/master/doc/build/linux.md

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

let
  julia = (pkgs.callPackage ./NixManifest.nix { inherit pkgs; }).julia;
  src = julia.meta.assets."julia-${julia.version}-full.tar.gz";

  makeDep = { use ? true, deps ? [ ], flags ? [ ], ldLibraryPath ? true }: {
    inherit use deps flags ldLibraryPath;
  };

  parseDeps = deps:
    let
      deps' = map makeDep dep;
      buildInputs = flatten (map (dep: dep.deps) deps');
      LD_LIBRARY_PATH = makeLibraryPath (filter (dep: dep.ldLibraryPath) deps');
      makeFlags = flatten (map (dep: dep.flags) deps');
    in
    builtins.trace
      (generators.toPretty { } {
        inherit LD_LIBRARY_PATH makeFlags;
        buildInputs = map (x: x.name) buildInputs;
      })
      { inherit buildInputs LD_LIBRARY_PATH makeFlags; };

  deps = parseDeps [
    # {
    #   flags=["USE_SYSTEM_CSL=1"];
    # }
    # {
    #   flags=["USE_SYSTEM_LLVM=1"];
    # }
    {
      deps = [ libunwind ];
      flags = [
        "USE_SYSTEM_LIBUNWIND=1"
        # "DISABLE_LIBUNWIND=0"
      ];
    }
    {
      deps = [ pcre2.dev ];
      flags = [
        "USE_SYSTEM_PCRE=1"
        "PCRE_CONFIG=${pcre2.dev}/bin/pcre2-config"
        "PCRE_INCL_PATH=${pcre2.dev}/include/pcre2.h"
      ];
    }
    {
      deps = [ openlibm ];
      flags = [
        "USE_SYSTEM_OPENLIBM=1"
        # "USE_SYSTEM_LIBM=0"
        # "UNTRUSTED_SYSTEM_LIBM=0"
      ];
    }
    # {
    #   flags=["USE_SYSTEM_DSFMT=1"];
    # }
    {
      use = !stdenv.isDarwin;
      deps = [ blas ];
      # deps = [ openblas ];
      flags = [
        "USE_SYSTEM_BLAS=1"
        "USE_BLAS64=${if blas.isILP64 then "1" else "0"}"
      ];
    }
    {
      deps = [ lapack ];
      flags = [ "USE_SYSTEM_LAPACK=1" ];
    }
    # {
    #   flags=["USE_SYSTEM_GMP=1"];
    # }
    {
      deps = [ mpfr ];
      flags = [ "USE_SYSTEM_MPFR=1" ];
    }
    # {
    #   flags=["USE_SYSTEM_SUITESPARSE=1"];
    # }
    # {
    #   flags=["USE_SYSTEM_LIBUV=1"];
    # }
    {
      deps = [ utf8proc ];
      flags = [ "USE_SYSTEM_UTF8PROC=1" ];
    }
    # {
    #   flags=["USE_SYSTEM_MBEDTLS=1"];
    # }
    # {
    #   flags=["USE_SYSTEM_LIBSSH2=1"];
    # }
    # {
    #   deps = [ libnghttp2.lib ];
    #   flags=["USE_SYSTEM_NGHTTP2=1"];
    # }
    # {
    #   deps = [ curl ];
    #   flags=["USE_SYSTEM_CURL=1"];
    # }
    {
      deps = [ libgit2 ];
      flags = [ "USE_SYSTEM_LIBGIT2=1" ];
    }
    {
      deps = patchelf;
      flags = [ "USE_SYSTEM_PATCHELF=1" ];
    }
    {
      deps = zlib;
      flags = [ "USE_SYSTEM_ZLIB=1" ];
    }
    # {
    #   flags=["USE_SYSTEM_P7ZIP=1"];
    # }
  ];
in
stdenv.mkDerivation rec {
  inherit (julia) pname version;
  inherit src;

  patches = [
    # ./patches/1.5/use-system-utf8proc-julia-1.3.patch
  ];

  postPatch = ''
    patchShebangs . contrib
  '';

  dontUseCmakeConfigure = true;

  buildInputs = []
    # ++ deps.buildInputs # TODO
    ++ lib.optionals stdenv.isDarwin [
    CoreServices
    ApplicationServices
  ];

  LD_LIBRARY_PATH = deps.LD_LIBRARY_PATH;

  nativeBuildInputs = with pkgs; [
    # Required by Julia
    python2
    # python3
    gfortran
    perl
    curl
    wget
    m4
    gawk
    gnupatch
    cmake
    pkg-config
    which
    # patchelf
   
    # Extra
    makeWrapper
  ];

  # See ./Make.inc for full set of flags
  makeFlags =
    let
      # TODO core2 on x86?
      arch = head (splitString "-" stdenv.system);
      march = {
        x86_64 = stdenv.hostPlatform.gcc.arch or "x86-64";
        i686 = "pentium4";
        aarch64 = "armv8-a";
      }.${arch} or (throw "unsupported architecture: ${arch}");
      # Julia requires Pentium 4 (SSE2) or better
      cpuTarget = {
        x86_64 = "x86-64";
        i686 = "pentium4";
        aarch64 = "generic";
      }.${arch} or (throw "unsupported architecture: ${arch}");
    in
    [
      "ARCH=${arch}" # TODO see 'Prevent picking up $ARCH from the environment variable' in Make.inc
      "MARCH=${march}"
      "JULIA_CPU_TARGET=${cpuTarget}"
      "PREFIX=$(out)"
      "prefix=$(out)" # TODO prefix vs PREFIX
      "SHELL=${stdenv.shell}"
     
      # TODO
      "USE_BINARYBUILDER=1"
    ]
    ++ deps.makeFlags;

  # TODO
  __noChroot = true;

  # TODO
  preBuild = ''
    sed -e '/^install:/s@[^ ]*/doc/[^ ]*@@' -i Makefile
    sed -e '/[$](DESTDIR)[$](docdir)/d' -i Makefile
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
  '';

  enableParallelBuilding = true;

  # Julia's tests require read/write access to $HOME
  # TODO check
  preCheck = ''
    export HOME="$NIX_BUILD_TOP"
  '';
  doCheck = true;
  checkTarget = "test";

  # TODO check
  postInstall = ''
    # Symlink shared libraries from LD_LIBRARY_PATH into lib/julia,
    # as using a wrapper with LD_LIBRARY_PATH causes segmentation
    # faults when program returns an error:
    #   $ julia -e 'throw(Error())'
    find $(echo $LD_LIBRARY_PATH | sed 's|:| |g') -maxdepth 1 -name '*.${
      if stdenv.isDarwin then "dylib" else "so"
    }*' | while read lib; do
      if [[ ! -e $out/lib/julia/$(basename $lib) ]]; then
        ln -sv $lib $out/lib/julia/$(basename $lib)
      fi
    done
  '';

  passthru = {
    inherit majorVersion minorVersion maintenanceVersion;
    site = "share/julia/site/v${majorVersion}.${minorVersion}";
  };

  # TODO
  # meta = {
  #   description = "High-level performance-oriented dynamical language for technical computing";
  #   homepage = "https://julialang.org/";
  #   license = lib.licenses.mit;
  #   maintainers = with lib.maintainers; [ raskin rob garrison ];
  #   platforms = [ "i686-linux" "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
  #   # Unfortunately, this derivation does not pass Julia's test suite. See
  #   # https://github.com/NixOS/nixpkgs/pull/121114.
  #   broken = true;
  # };
}
