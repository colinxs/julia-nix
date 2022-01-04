{ lib, dev, stdenv }:

with builtins;
with lib;

let
in
{
  # TODO MOVE
  mkFunction = module: args: evalModules {
    modules = [ module args ];
  };

  checkVersion = x: y:
    let
      x' = splitVersion x;
      y' = splitVersion y;
    in
    (if length y' > 0 then elemAt x' 0 == elemAt y' 0 else true)
    && (if length y' > 1 then elemAt x' 1 == elemAt y' 1 else true)
    && (if length y' > 2 then elemAt x' 2 == elemAt y' 2 else true);

  buildJulia = { src, version, deps ? [ ], ... }@args:
    let
      args' = removeAttrs [
        "src"
        "version"
        "deps"
      ] args;

      depArgs = {
        buildInputs = flatten (map (dep: dep.buildInputs or [ ]) deps);
        makeFlags = flatten (map (dep: dep.makeFlags or [ ]) deps);
        LD_LIBRARY_PATH = makeLibraryPath (flatten (
          depArgs.buildInputs
        ));
      };

      defaultArgs = {
        dontUseCmakeConfigure = true;
        enableParallelBuilding = true;

        # TODO
        # __noChroot = true;

        # Needed for Libgit2 tests
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        postPatch = ''
          patchShebangs . contrib

          # shopt -s globstar
          # # for f in ./deps/**/Makefile ./deps/**/*.mk; do
          # for f in ./deps/**/*; do 
          #   if file --brief --mime-type "$f" | grep -q 'text'; then
          #     echo "Modifying $f"
          #     sed -ri 's/\s+\--jobs=\$\(JOBS\)//g' "$f" && echo "Modified $f" 
          #     sed -ri 's/\s+\--jobs\s*=\s*[0-9]+//g' "$f" && echo "Modified $f"
          #     sed -ri 's/\s+\-j\s*[0-9]+//g' "$f" && echo "Modified $f" 
          #   fi
          # done
          # shopt -u globstar
        '';

        # See ./Make.inc for full set of flags
        makeFlags =
          let
            # TODO core2 on x86?
            # Julia requires Pentium 4 (SSE2) or better
            arch = head (splitString "-" stdenv.system);
            march = {
              x86_64 = stdenv.hostPlatform.gcc.arch or "x86-64";
              i686 = "pentium4";
              aarch64 = "armv8-a";
            }.${arch} or (throw "unsupported architecture: ${arch}");
            cpuTarget = march // {
              # aarch64 = "generic";
            }.${arch} or (throw "unsupported architecture: ${arch}");
          in
          [
            "ARCH=${arch}"
            "MARCH=${march}"
            "JULIA_CPU_TARGET=${cpuTarget}"

            # TODO prefix vs PREFIX
            "PREFIX=$(out)"
            "prefix=$(out)"

            # TODO
            "USE_BINARYBUILDER=0"
            "VERBOSE=1"
            # "JOBS=$NIX_BUILD_CORES"
            # "MAKE_NB_JOBS=$NIX_BUILD_CORES"
            # "-j$NIX_BUILD_CORES"
          ];

        preBuild = ''
          # export LD_LIBRARY_PATH
          # export SSL_CERT_FILE

          # TODO
          sed -e '/^install:/s@[^ ]*/doc/[^ ]*@@' -i Makefile
          sed -e '/[$](DESTDIR)[$](docdir)/d' -i Makefile
        '';

        # TODO
        # Julia's tests require read/write access to $HOME
        # preCheck = ''
        #   export HOME="$NIX_BUILD_TOP"
        # '';
        doCheck = true;
        checkTarget = "test";

        # TODO check
        # TODO lndir?
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
      };

    finalArgs =
      let
        pred = path: lhs: rhs: !(isAttrs lhs && isAttrs rhs);
        merge = lhs: rhs:
          if isList lhs && isList rhs
          then lhs ++ rhs
          else [ lhs rhs ];
      in
      dev.mergeAttrsRecursiveBy pred merge;
    in
    traceSeqN 2 finalArgs (stdenv.mkDerivation finalArgs);
}
