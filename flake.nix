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
              archive = "roc_nightly-linux_x86_64-2026-08-19-edec830.tar.gz";
              hash = "sha256-Khu29F/pdgYWX4MEf/2H3SHASFMGZZaG8pKRTHw1P8Q=";
              directory = "roc_nightly-linux_x86_64-2026-08-19-edec830";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-08-19-edec830.tar.gz";
              hash = "sha256-MwDB3GJU7oTqbeHNZ7c07SHTcq7RyS9leZsGFs9V8XI=";
              directory = "roc_nightly-linux_arm64-2026-08-19-edec830";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-08-19-edec830.tar.gz";
              hash = "sha256-JAuLujaj6f9/i+d7s2q60nMPcHsyphyF0x+59E/rOOo=";
              directory = "roc_nightly-macos_x86_64-2026-08-19-edec830";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-08-19-edec830.tar.gz";
              hash = "sha256-b4TGqd5ud5qWTnNDL3yOAgZ394a2eHyLjXOr/5uMkgI=";
              directory = "roc_nightly-macos_apple_silicon-2026-08-19-edec830";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-08-19-edec830";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-08-19-edec830/${nightly.archive}";
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
