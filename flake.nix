{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      perSystem =
        {
          pkgs,
          ...
        }:
        let
          nightly = {
            x86_64-linux = {
              archive = "roc_nightly-linux_x86_64-2026-10-14-38a3029.tar.gz";
              hash = "sha256-sXmJavp4qmKpk3U+xMlwfizyRciEIN/yNu5rqo6oiUs=";
              directory = "roc_nightly-linux_x86_64-2026-10-14-38a3029";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-10-14-38a3029.tar.gz";
              hash = "sha256-gGa6RBt1goF3UzvrT9slNRxMSFsVlaqeEWlytmzj6+M=";
              directory = "roc_nightly-linux_arm64-2026-10-14-38a3029";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-10-14-38a3029.tar.gz";
              hash = "sha256-FeuUR7Sj5sSVpNRv3kQ0hGCvyG3T3b65NZEbs95zEy4=";
              directory = "roc_nightly-macos_x86_64-2026-10-14-38a3029";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-10-14-38a3029.tar.gz";
              hash = "sha256-F2nLbjpmiZArtDswVitMMgCskP75q58UXkyZkqZ9MHE=";
              directory = "roc_nightly-macos_apple_silicon-2026-10-14-38a3029";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-10-14-38a3029";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-10-14-38a3029/${nightly.archive}";
              inherit (nightly) hash;
            };
            dontBuild = true;
            unpackPhase = "tar -xzf $src";
            sourceRoot = ".";
            installPhase = ''
              mkdir -p $out/bin $out/lib
              install -m755 ${nightly.directory}/roc $out/bin/roc
              cp -R ${nightly.directory}/lib/. $out/lib/
            '';
          };
        in
        {
          devShells.default = pkgs.mkShell {
            name = "roc-random";
            packages = [
              roc-nightly
              pkgs.actionlint
              pkgs.nixfmt-rfc-style
              pkgs.nodePackages.prettier
            ];
          };
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
