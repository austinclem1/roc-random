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
              archive = "roc_nightly-linux_x86_64-2026-08-13-2fdd90e.tar.gz";
              hash = "sha256-ODVmIwVdLpuhACHALiIe4gA/mmsua5u9/t+j53lPoPk=";
              directory = "roc_nightly-linux_x86_64-2026-08-13-2fdd90e";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-08-13-2fdd90e.tar.gz";
              hash = "sha256-2toZcyf+LbF+awsDRY5yfmgIQqFPY3alLUcf3Dux6yM=";
              directory = "roc_nightly-linux_arm64-2026-08-13-2fdd90e";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-08-13-2fdd90e.tar.gz";
              hash = "sha256-B62/lz4bmLRTX00ITpqrmV+x5tT0xaHlDuKAzcKGBqg=";
              directory = "roc_nightly-macos_x86_64-2026-08-13-2fdd90e";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-08-13-2fdd90e.tar.gz";
              hash = "sha256-4Fd6esLFj4nLKd0gxu4d9CXFBobH41S0yvDi3pklm1o=";
              directory = "roc_nightly-macos_apple_silicon-2026-08-13-2fdd90e";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-08-13-2fdd90e";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-08-13-2fdd90e/${nightly.archive}";
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
