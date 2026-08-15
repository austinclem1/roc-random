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
              archive = "roc_nightly-linux_x86_64-2026-08-14-549b94e.tar.gz";
              hash = "sha256-apA1EJwdt/PmB4WQ1h8QtaY3LjDB+FY+vRdRG7hxp0A=";
              directory = "roc_nightly-linux_x86_64-2026-08-14-549b94e";
            };
            aarch64-linux = {
              archive = "roc_nightly-linux_arm64-2026-08-14-549b94e.tar.gz";
              hash = "sha256-f5eR16z8iFh6DDlMt82wHfD4Yq3/CkyxM4RVxDeUCno=";
              directory = "roc_nightly-linux_arm64-2026-08-14-549b94e";
            };
            x86_64-darwin = {
              archive = "roc_nightly-macos_x86_64-2026-08-14-549b94e.tar.gz";
              hash = "sha256-0osKw4dFWk+Pjt6fqGvuErwXXKlIk7m6CEh84oC8hP8=";
              directory = "roc_nightly-macos_x86_64-2026-08-14-549b94e";
            };
            aarch64-darwin = {
              archive = "roc_nightly-macos_apple_silicon-2026-08-14-549b94e.tar.gz";
              hash = "sha256-sU2+9n6pBDDdeFlF+sXyJOw8amL+s9LRrvQqcY5xadg=";
              directory = "roc_nightly-macos_apple_silicon-2026-08-14-549b94e";
            };
          }.${pkgs.stdenv.hostPlatform.system};

          roc-nightly = pkgs.stdenvNoCC.mkDerivation {
            pname = "roc-nightly";
            version = "2026-08-14-549b94e";
            src = pkgs.fetchurl {
              url = "https://github.com/roc-lang/nightlies/releases/download/nightly-2026-08-14-549b94e/${nightly.archive}";
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
