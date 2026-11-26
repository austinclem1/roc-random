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
              archive = "roc_nightly-linux_x86_64-2026-11-26-890d6c8.tar.gz";
              hash = "sha256-Cm7s08h4sK9Y5Te33u2e3KC1UEf4XyjKBTtDOGCt/ac=";
              directory = "roc_nightly-linux_x86_64-2026-11-26-890d6c8";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-11-26-890d6c8.tar.gz";
              hash = "sha256-Ia96p0hikA+ipDxmEGgrMPAN1vy0Wcde3bCdfTa1ziQ=";
              directory = "roc_nightly-linux_arm64-2026-11-26-890d6c8";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-11-26-890d6c8.tar.gz";
              hash = "sha256-6OSPB3vo7FMF2MQu8dVsLfv1afNg4S906I7b2yRp0hU=";
              directory = "roc_nightly-macos_x86_64-2026-11-26-890d6c8";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-11-26-890d6c8.tar.gz";
              hash = "sha256-LBFksXN+PcH/mm5btXyWOY5hnSHqz9FAYk+zVefqXFs=";
              directory = "roc_nightly-macos_apple_silicon-2026-11-26-890d6c8";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-11-26-890d6c8";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-11-26-890d6c8/${nightly.archive}";
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
