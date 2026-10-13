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
              archive = "roc_nightly-linux_x86_64-2026-10-13-b17d287.tar.gz";
              hash = "sha256-O2E7FVvm6gTJoa5OMV+0z5EeLQtwlnCNB+8UdkfaV4s=";
              directory = "roc_nightly-linux_x86_64-2026-10-13-b17d287";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-10-13-b17d287.tar.gz";
              hash = "sha256-RCCNVZjsU80j1BlLu9Y6xH5pKT1Rk6zDGPgWNGshgDA=";
              directory = "roc_nightly-linux_arm64-2026-10-13-b17d287";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-10-13-b17d287.tar.gz";
              hash = "sha256-qYtgYw83cvIfIrktO/el7W0Dg1yGolFFWSbxp2OYfiI=";
              directory = "roc_nightly-macos_x86_64-2026-10-13-b17d287";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-10-13-b17d287.tar.gz";
              hash = "sha256-KjzKpHjjrAVXyIu4gP7EOBED29LuWG8wrBeyLZw75vE=";
              directory = "roc_nightly-macos_apple_silicon-2026-10-13-b17d287";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-10-13-b17d287";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-10-13-b17d287/${nightly.archive}";
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
