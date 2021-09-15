{ pkgs ? import <nixpkgs> { } }: {
  "julia" =
    let
      fetcher = pkgs.fetchzip;
      pname = "julia";
      fetcherName = "pkgs.fetchzip";
      version = "v1.6.2";
      name = "julia-v1.6.2";
      outPath = fetcher fetcherArgs;
      meta = {
        "tag" = "v1.6.2";
        "rev" = "1b93d53fc4bb59350ada898038ed4de2994cce33";
        "assets" = {
          "julia-1.6.2-full.tar.gz" =
            let
              fetcher = pkgs.fetchzip;
              fetcherName = "pkgs.fetchzip";
              outPath = fetcher fetcherArgs;
              fetcherArgs = { url = "https://github.com/JuliaLang/julia/releases/download/v1.6.2/julia-1.6.2-full.tar.gz"; curlOpts = "-L --header Accept:application/octet-stream"; sha256 = "1xw5ap28qs17xg92gaxnzwbr0ax1bmzqxkwad12n8ma9iwi3jrd4"; };
            in
            { inherit fetcher fetcherName outPath fetcherArgs; };
        };
      };
      fetcherArgs = { url = "https://github.com/julialang/julia/archive/1b93d53fc4bb59350ada898038ed4de2994cce33.tar.gz"; sha256 = "1q6qk9kdc01kfqdfk4qsp48iqqyyk750x3y4qlaiywhrcjzw1hnx"; };
    in
    { inherit fetcher pname fetcherName version name outPath meta fetcherArgs; };
}
