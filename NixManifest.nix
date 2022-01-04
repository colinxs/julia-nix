{ pkgs ? import <nixpkgs> { } }: {
  "julia" =
    let
      fetcher = pkgs.fetchzip;
      pname = "julia";
      fetcherName = "pkgs.fetchzip";
      version = "1.7.1";
      name = "julia-1.7.1";
      outPath = fetcher fetcherArgs;
      meta = {
        "tag" = "v1.7.1";
        "rev" = "ac5cc99908d463582e66db3368b9b48fae1e2525";
        "assets" = {
          "julia-1.7.1-full.tar.gz" =
            let
              fetcher = pkgs.fetchurl;
              fetcherName = "pkgs.fetchurl";
              outPath = fetcher fetcherArgs;
              fetcherArgs = { url = "https://github.com/JuliaLang/julia/releases/download/v1.7.1/julia-1.7.1-full.tar.gz"; curlOpts = "-L --header Accept:application/octet-stream"; hash = "sha256-rdhpEht+eI/0h6I0/TlIRGnbs97SmxcEHGPEdXUV3Vg="; };
            in
            { inherit fetcher fetcherName outPath fetcherArgs; };
        };
      };
      fetcherArgs = { url = "https://github.com/julialang/julia/archive/ac5cc99908d463582e66db3368b9b48fae1e2525.tar.gz"; name = "ac5cc99"; hash = "sha256-OlIA0RpZH9K9I+/XBudVBFjk4nTz49tNM+6y0OHniuQ="; };
    in
    { inherit fetcher pname fetcherName version name outPath meta fetcherArgs; };
}
