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
      # pkgs = import nixpkgs { config.allowBroken = true; };
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      pkgsHome = nix-home.legacyPackages.x86_64-linux; 
      args = { inherit (pkgs.darwin.apple_sdk.frameworks) ApplicationServices CoreServices; };
    in {
      packages.x86_64-linux.julia = pkgs.callPackage ./default.nix args;
      # packages.x86_64-linux.julia = pkgs.callPackage ./default-simple.nix args; 
    };
}
