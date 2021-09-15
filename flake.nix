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

      pkgsHome = nix-home.legacyPackages."${system}";
      
      pkgs = nixpkgs.legacyPackages."${system}";
      inherit (pkgs) lib;
      
      ccacheCC = pkgs.wrapCC (pkgs.ccache.links { 
        # unwrappedCC = pkgs.gcc10.overrideAttrs (oA: { cc = (oA.cc.override { reproducibleBuild = false; profiledCompiler = true; }); })
        unwrappedCC = pkgs.fastStdenv.cc.cc;
        extraConfig = ''
          export CCACHE_COMPRESS=1
          export CCACHE_DIR=/var/cache/ccache
          export CCACHE_UMASK=007
        '';
      });

      stdenv = pkgs.overrideCC pkgs.stdenv ccacheCC;

      callPackage = lib.callPackageWith (pkgs // { stdenv = pkgs.ccacheStdenv; });
    in
    {
      packages.x86_64-linux.julia = callPackage ./default.nix {
        inherit (pkgs.darwin.apple_sdk.frameworks) ApplicationServices CoreServices;
      };
      # packages.x86_64-linux.julia = pkgs.hello.override { inherit stdenv; };
    };
}
