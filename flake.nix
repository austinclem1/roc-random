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
              archive = "roc_nightly-linux_x86_64-2026-10-15-38e6c42.tar.gz";
              hash = "sha256-np3A/ruOfCjagghsXVgYNU7C98iLEriymbOmA2GH25w=";
              directory = "roc_nightly-linux_x86_64-2026-10-15-38e6c42";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-10-15-38e6c42.tar.gz";
              hash = "sha256-XVakWv1vseyjlF6qD+oSBHlAJoDx9r5U9JbqcH9eOS8=";
              directory = "roc_nightly-linux_arm64-2026-10-15-38e6c42";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-10-15-38e6c42.tar.gz";
              hash = "sha256-9blvnEhkEXRzjsHajXagX5J5EX8LvC+jJctcYrRjRdQ=";
              directory = "roc_nightly-macos_x86_64-2026-10-15-38e6c42";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-10-15-38e6c42.tar.gz";
              hash = "sha256-Fcwq7w44F2HZY079ZJE+6x0ZwzBuq0+nFEW+krEj0C8=";
              directory = "roc_nightly-macos_apple_silicon-2026-10-15-38e6c42";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-10-15-38e6c42";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-10-15-38e6c42/${nightly.archive}";
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
