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
              archive = "roc_nightly-linux_x86_64-2026-10-12-2664a27.tar.gz";
              hash = "sha256-uKd7P4ZgfcbcwXPS7rgF+fbhMUkTF3xQ6/c1YpOFNLc=";
              directory = "roc_nightly-linux_x86_64-2026-10-12-2664a27";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-10-12-2664a27.tar.gz";
              hash = "sha256-z9QCxsQDnQz+pYx9STLM2KSULuy2X5owfQZRTv4uFOg=";
              directory = "roc_nightly-linux_arm64-2026-10-12-2664a27";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-10-12-2664a27.tar.gz";
              hash = "sha256-iIRWD2kck1QMH6OxoKR75+4QBhnQFiaVgxB869XZN+c=";
              directory = "roc_nightly-macos_x86_64-2026-10-12-2664a27";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-10-12-2664a27.tar.gz";
              hash = "sha256-2f9f3Zehe8zntid1iArgfRwIVRAgotKkl85dgAvacIE=";
              directory = "roc_nightly-macos_apple_silicon-2026-10-12-2664a27";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-10-12-2664a27";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-10-12-2664a27/${nightly.archive}";
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
