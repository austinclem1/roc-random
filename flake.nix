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
              archive = "roc_nightly-linux_x86_64-2026-08-18-e9be50a.tar.gz";
              hash = "sha256-xKulaRwSvDsps4VcNTBrFWg2N+0zivaS/hCDNUouYC8=";
              directory = "roc_nightly-linux_x86_64-2026-08-18-e9be50a";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-08-18-e9be50a.tar.gz";
              hash = "sha256-wT978otb7xr3nj3zfKnMj6h1TiNjkH2b1TaOXAZculM=";
              directory = "roc_nightly-linux_arm64-2026-08-18-e9be50a";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-08-18-e9be50a.tar.gz";
              hash = "sha256-ShWZFJu1epy8uIw2ZxONFdh0xvDKJpxTspZ3n2DrQbk=";
              directory = "roc_nightly-macos_x86_64-2026-08-18-e9be50a";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-08-18-e9be50a.tar.gz";
              hash = "sha256-qJ9hlngNGueR32s9aPck7joFNb1mzKEar1bUC9/aIKc=";
              directory = "roc_nightly-macos_apple_silicon-2026-08-18-e9be50a";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-08-18-e9be50a";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-08-18-e9be50a/${nightly.archive}";
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
