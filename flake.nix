{
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  inputs.nix-home.url = "path:///home/colinxs/nix-home";
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };
  # inputs.src = {
  #   url = "github:julialang/julia/v1.6.2";
  #   flake = false;
  # };
  outputs = { self, nixpkgs, nix-home, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        # config = {
        #   replaceStdenv = { pkgs }: pkgs.ccacheStdenv;
        # };
        # overlays = [
        #   (final: prev: {
        #     ccacheWrapper = prev.ccacheWrapper.override {
        #       cc = cc;
        #       # cc = final.buildPackages.gcc8;
        #       # cc = prev.gcc9Stdenv.cc;
        #       # cc = prev.fastStdenv.cc;
        #       # cc = prev.buildPackages.gcc10.overrideAttrs (oA: {
        #       #   cc = oA.cc.override {
        #       #     reproducibleBuild = false;
        #       #     profiledCompiler = true; 
        #       #   };
        #       # });
        #
        #       # cc = prev.buildPackages.gcc10.overrideAttrs (old: {
        #       #   cc = old.cc.override {
        #       #     reproducibleBuild = false;
        #       #     profiledCompiler = with stdenv; (!isDarwin && (isi686 || isx86_64));
        #       #   };
        #       # });
        #       extraConfig = ''
        #         export CCACHE_COMPRESS=1
        #         export CCACHE_DIR=/var/cache/ccache
        #         export CCACHE_UMASK=007
        #         if [ ! -d "$CCACHE_DIR" ]; then
        #           echo "====="
        #           echo "Directory '$CCACHE_DIR' does not exist"
        #           echo "Please create it with:"
        #           echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
        #           echo "  sudo chown root:nixbld '$CCACHE_DIR'"
        #           echo "====="
        #           exit 1
        #         fi
        #         if [ ! -w "$CCACHE_DIR" ]; then
        #           echo "====="
        #           echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
        #           echo "Please verify its access permissions"
        #           echo "====="
        #           exit 1
        #      /nix/store/qjixqv5pzih3hk5hrif37gl7jkqvmnlw-ccache-links/bin/gcc   fi
        #       '';
        #     };
        #   })
        # ];
      };
      callPackage = pkgs.lib.callPackageWith (pkgs // { stdenv = pkgs.ccacheStdenv; });
      pkgsHome = nix-home.legacyPackages.x86_64-linux;
      # stdenv = pkgs.fastStdenv;
      # stdenv = pkgs.overrideCC pkgs.ccacheStdenv pkgs.fastStdenv.cc;
      # stdenv = pkgs.ccacheStdenv;

      # stdenv = pkgs.stdenv;

      cc = pkgs.makeOverrideable ({ cc }:
        (pkgs.wrapNonDeterministicGcc pkgs.gccStdenv cc)
        { inherit (pkgs.stdenv) cc; }
      );

      stdenv = pkgs.overrideCC pkgs.stdenv cc; 
        # cc = pkgs.fastStdenv.cc;
      # stdenv = pkgs.overrideCC pkgs.stdenv (pkgs.ccache.links {
      #   extraConfig = '' 
      #     export CCACHE_COMPRESS=1
      #     export CCACHE_DIR=/var/cache/ccache
      #     export CCACHE_UMASK=007
      #   '';
      #   # unwrappedCC = pkgs.fastStdenv.cc.cc;
      #   unwrappedCC = pkgs.stdenv.cc.cc;
      # });

      # stdenv = pkgs.ccacheStdenv;
      args = {
        inherit (pkgs.darwin.apple_sdk.frameworks) ApplicationServices CoreServices;
        # stdenv = pkgs.ccacheStdenv;
        # stdenv = pkgs.ccacheWrapper;
        # stdenv = pkgs.overrideCC pkgs.stdenv pkgs.ccacheWrapper;
      };
    in
    {
      # packages.x86_64-linux.julia = callPackage ./default.nix args;
      packages.x86_64-linux.julia = (pkgs.hello.override { inherit stdenv; }).overrideDerivation (oA: rec {
        configurePhase = ''
          echo "$(command -v gcc)"

          exit 1
        '';
      });

      # packages.x86_64-linux.julia = pkgs.callPackage ./default-simple.nix args; 
    };
}
