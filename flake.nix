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
        overlays = [
          (final: prev: {
            ccacheWrapper = prev.ccacheWrapper.override {
              # cc = prev.fastStdenv.cc;
              # cc = prev.buildPackages.gcc10.overrideAttrs (old: {
              #   cc = old.cc.override {
              #     reproducibleBuild = false;
              #     profiledCompiler = with stdenv; (!isDarwin && (isi686 || isx86_64));
              #   };
              # });
              extraConfig = ''
                export CCACHE_COMPRESS=1
                export CCACHE_DIR=/var/cache/ccache
                export CCACHE_UMASK=007
                if [ ! -d "$CCACHE_DIR" ]; then
                  echo "====="
                  echo "Directory '$CCACHE_DIR' does not exist"
                  echo "Please create it with:"
                  echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
                  echo "  sudo chown root:nixbld '$CCACHE_DIR'"
                  echo "====="
                  exit 1
                fi
                if [ ! -w "$CCACHE_DIR" ]; then
                  echo "====="
                  echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
                  echo "Please verify its access permissions"
                  echo "====="
                  exit 1
                fi
              '';
            };
          })
        ];
      };
      callPackage = pkgs.lib.callPackageWith (pkgs // { stdenv = pkgs.ccacheStdenv; });
      stdenv = pkgs.ccacheStdenv;
      # pkgs = nixpkgs.legacyPackages.x86_64-linux;
      pkgsHome = nix-home.legacyPackages.x86_64-linux;
      # stdenv = with pkgs; overrideCC gccStdenv (wrapNonDeterministicGcc gccStdenv ccacheWrapper); 
      args = {
        inherit (pkgs.darwin.apple_sdk.frameworks) ApplicationServices CoreServices;
        # stdenv = pkgs.ccacheStdenv;
        # stdenv = pkgs.ccacheWrapper;
        # stdenv = pkgs.overrideCC pkgs.stdenv pkgs.ccacheWrapper;
      };
    in
    {
      # packages.x86_64-linux.julia = callPackage ./default.nix args;
      packages.x86_64-linux.julia = (pkgs.hello.overrideAttrs (oA: oA // { 
        # buildInputs = (oA.buildInputs or []) ++ [ pkgs.which ];
        preBuild = ''
          echo "$(${pkgs.which}/bin/which gcc)"
        '';
      }));
      # })).override {
      #   # inherit stdenv; 
      # };
        
      # packages.x86_64-linux.julia = pkgs.callPackage ./default-simple.nix args; 
    };
}
