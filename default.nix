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
, libssh2
, p7zip
  # linear algebra
, blas
, openblas
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

let
  julia = (pkgs.callPackage ./NixManifest.nix { inherit pkgs; }).julia;
  src = julia.meta.assets."julia-${julia.version}-full.tar.gz";

  checkVersion = x: y:
    let
      x' = splitVersion x;
      y' = splitVersion y;
    in
         (if length y' > 0 then elemAt x' 0 == elemAt y' 0 else true)
      && (if length y' > 1 then elemAt x' 1 == elemAt y' 1 else true)
      && (if length y' > 2 then elemAt x' 2 == elemAt y' 2 else true);

  # TODO
  toPretty = x:
    let f = generators.toPretty {};
    in if isString x then x else f x;

  myTrace = x: builtins.trace (toPretty x) x;

  makeDep = { use ? true, buildInputs ? [ ], makeFlags ? [ ], ldLibraryPath ? true }: {
    inherit use buildInputs makeFlags ldLibraryPath;
  };

  parseDeps = deps:
    let
      deps' = filter (dep: dep.use) (map makeDep deps);
      buildInputs = flatten (map (dep: dep.buildInputs) deps');
      LD_LIBRARY_PATH = makeLibraryPath (flatten (map (dep: dep.buildInputs) (filter (dep: dep.ldLibraryPath) deps')));
      makeFlags = flatten (map (dep: dep.makeFlags) deps');
    in
    builtins.trace
      (toPretty {
        inherit LD_LIBRARY_PATH;
        makeFlags = toPretty makeFlags;
        buildInputs = toPretty (map (x: x.name) buildInputs);
      })
      { inherit buildInputs LD_LIBRARY_PATH makeFlags; };

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
  deps = parseDeps [
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
    {
      use = checkVersion openblas.version "0.3";
      buildInputs = [ openblas ];
      makeFlags = [
        "USE_SYSTEM_BLAS=1"
        "USE_BLAS64=${if openblas.blas64 then "1" else "0"}"
      ];
    }

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
      makeFlags=["USE_SYSTEM_LIBSSH2=1"];
    }
    {
      use = checkVersion libnghttp2.version "1";
      buildInputs = [ libnghttp2.lib ];
      makeFlags=["USE_SYSTEM_NGHTTP2=1"];
    }
    {
      use = checkVersion curl.version "7";
      buildInputs = [ curl ];
      makeFlags=["USE_SYSTEM_CURL=1"];
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
      makeFlags=["USE_SYSTEM_P7ZIP=1"];
    }
  ];
in
stdenv.mkDerivation rec {
  inherit (julia) pname version;
  inherit src;

  patches = [
    # ./patches/1.6/0001-reduce-precompile-failure-severity-to-a-warning-3990.patch
    ./patches/1.6/generate_precompile.patch
  ];

  postPatch = ''
    patchShebangs . contrib
    shopt -s globstar
    for f in ./deps/**/*; do
      if [ -f "$f" ]; then
        sed -i 's/--jobs=$(JOBS)//g' "$f" || echo "===== FAILED: $f"
      fi
    done
    shopt -u globstar
    rg '\--jobs'
  '';

  dontUseCmakeConfigure = true;
  enableParallelBuilding = true;
  
  # TODO
  __noChroot = true;


  buildInputs = []
    ++ deps.buildInputs # TODO
    ++ lib.optionals stdenv.isDarwin [
    CoreServices
    ApplicationServices
  ];

  nativeBuildInputs = with pkgs; [
    # Required by Julia
    python3
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

    # TODO
    ripgrep
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
      "ARCH=${arch}"
      "MARCH=${march}"
      "JULIA_CPU_TARGET=${cpuTarget}"
      # "PREFIX=$(out)" TODO prefix vs PREFIX
      "prefix=$(out)" 
      # "SHELL=${stdenv.shell}" # TODO should already be set in stdenv/generic/setup.sh
     
      # TODO
      "USE_BINARYBUILDER=1"
      # "VERBOSE=1"
      # "JOBS=$NIX_BUILD_CORES"
      # "MAKE_NB_JOBS=$NIX_BUILD_CORES"
      # "-j$NIX_BUILD_CORES"
    ]
    ++ deps.makeFlags;


  # Needed for Libgit2 tests
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # TODO
  LD_LIBRARY_PATH = deps.LD_LIBRARY_PATH;

  preBuild = ''
    # makeFlagsArray+=(
    #   "JOBS=$NIX_BUILD_CORES"
    #   "MAKE_NB_JOBS=$NIX_BUILD_CORES"
    #   "-j$NIX_BUILD_CORES"
    # )
    # export MAKEFLAGS="-j $NIX_BUILD_CORES"

    sed -e '/^install:/s@[^ ]*/doc/[^ ]*@@' -i Makefile
    sed -e '/[$](DESTDIR)[$](docdir)/d' -i Makefile
    #export LD_LIBRARY_PATH
  '';
    # export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}

  # Julia's tests require read/write access to $HOME
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

  # passthru = {
  #   inherit majorVersion minorVersion maintenanceVersion;
  #   site = "share/julia/site/v${majorVersion}.${minorVersion}";
  # };

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
