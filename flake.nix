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
        overlays = [
          (final: prev: {
            # replaceStdenv = { pkgs }: builtins.trace "HERE" pkgs.ccacheStdenv;
            stdenv = prev.ccacheStdenv;
            ccacheWrapper = prev.ccacheWrapper.override {
              extraConfig = ''
                export CCACHE_COMPRESS=1
                export CCACHE_DIR=/var/cache/ccache
                export CCACHE_UMASK=007
                # if [ ! -d "$CCACHE_DIR" ]; then
                #   echo "====="
                #   echo "Directory '$CCACHE_DIR' does not exist"
                #   echo "Please create it with:"
                #   echo "  sudo mkdir -m0770 '$CCACHE_DIR'"
                #   echo "  sudo chown root:nixbld '$CCACHE_DIR'"
                #   echo "====="
                #   exit 1
                # fi
                # if [ ! -w "$CCACHE_DIR" ]; then
                #   echo "====="
                #   echo "Directory '$CCACHE_DIR' is not accessible for user $(whoami)"
                #   echo "Please verify its access permissions"
                #   echo "====="
                #   exit 1
                # fi
              '';
            };
          })
        ];
      };
      # pkgs = nixpkgs.legacyPackages.x86_64-linux;
      pkgsHome = nix-home.legacyPackages.x86_64-linux; 
      args = { inherit (pkgs.darwin.apple_sdk.frameworks) ApplicationServices CoreServices; }; 
    in {
      packages.x86_64-linux.julia = pkgs.callPackage ./default.nix args;
      # packages.x86_64-linux.julia = pkgs.callPackage ./default-simple.nix args; 
    };
}
