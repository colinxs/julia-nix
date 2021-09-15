{
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  inputs.src = {
    url = "github:julialang/julia/v1.6.2";
    flake = false;
  };
  outputs = { self, nixpkgs, src }: 
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      args = { inherit src; inherit (pkgs.darwin.apple_sdk.frameworks) ApplicationServices CoreServices; };
    in {
      packages.x86_64-linux.julia = pkgs.callPackage ./default.nix args;
      # packages.x86_64-linux.julia = pkgs.callPackage ./default-simple.nix args; 
    };
}
