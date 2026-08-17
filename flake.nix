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
              archive = "roc_nightly-linux_x86_64-2026-08-17-b9ca140.tar.gz";
              hash = "sha256-Lp+XnyVCH8GigHSqHHJbSbIdn+lwzWaV99XahiNIizI=";
              directory = "roc_nightly-linux_x86_64-2026-08-17-b9ca140";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-08-17-b9ca140.tar.gz";
              hash = "sha256-egkPQMl5phePZ5oo0h2SNAX5IdNIMa19hvLZDsMrgYs=";
              directory = "roc_nightly-linux_arm64-2026-08-17-b9ca140";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-08-17-b9ca140.tar.gz";
              hash = "sha256-EVQWSUP1uXURAwn541XCH07zlWqezRzJIUZj2/hncjk=";
              directory = "roc_nightly-macos_x86_64-2026-08-17-b9ca140";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-08-17-b9ca140.tar.gz";
              hash = "sha256-k65IRf7RmskigLSKTrV8YGxrDRUiwBMy2pzdatuE/GE=";
              directory = "roc_nightly-macos_apple_silicon-2026-08-17-b9ca140";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-08-17-b9ca140";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-08-17-b9ca140/${nightly.archive}";
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
