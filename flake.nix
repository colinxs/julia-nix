{
  inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  inputs.src.url = "github:julialang/julia/v1.6.2";
  outputs = { self, nixpkgs, src }: 
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      # packages.x86_64-linux.julia = pkgs.callPackage ./default.nix { inherit src; }; 
      packages.x86_64-linux.julia = pkgs.callPackage ./default-simple.nix { inherit src; }; 
    };
}
