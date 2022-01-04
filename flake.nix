{
  inputs = {
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

  outputs = { self, nix-home, flake-compat, flake-utils, ... }:
    let supportedSystems = [ "x86_64-linux" ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        inherit (pkgs) mur dev;
        pkgs = nix-home.legacyPackages."${system}";
      in
      {
        packages.julia = pkgs.callPackage ./default.nix {
        };
      });
}
