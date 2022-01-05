{
  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.follows = "nix-home/nixpkgs";
    nix-home.url = "git+ssh://git@github.com/colinxs/home?dir=nix-home";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils = {
      inputs.nixpkgs.follows = "nix-home/nixpkgs";
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, nix-home, flake-compat, flake-utils, ... }:
    let supportedSystems = [ "x86_64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        inherit (pkgsHome) mur dev;
        pkgsHome = nix-home.legacyPackages."${system}";
        
        inherit (pkgs) lib; 
        pkgs = (nixpkgs.legacyPackages."${system}").extend (_: _: {
          inherit mur dev;
        });
        # callPackage = lib.callPackageWith (pkgs // { inherit mur dev; });
        # callPackages = lib.callPackagesWith (pkgs // { inherit mur dev; });
      in
      {
        packages = pkgs.callPackages ./default.nix {
        };
      });
}
