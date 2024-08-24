{
  description = "A static website builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f (
            let
              pkgs = import nixpkgs { inherit system; };
            in
            {
              inherit pkgs;
            }
          )
        );
    in
    rec {
      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell { inputsFrom = [ packages.${pkgs.system}.default ]; };
        }
      );
      packages = forEachSupportedSystem (
        { pkgs }:
        {
          default = (
            pkgs.buildNpmPackage rec {
              pname = npmDeps.pname;
              version = npmDeps.version;

              meta =
                let
                  package_json = builtins.fromJSON (builtins.readFile ./package.json);
                in
                {
                  inherit (package_json) author;
                  license = pkgs.lib.licenses.gpl3Only;
                };

              src = ./.;

              nativeBuildInputs = [
                pkgs.dart-sass
                # packages used by foundry-vtt-types scripts, which for some reason aren't being installed
                (pkgs.writeShellScriptBin "is-ci" "exit 0")
                pkgs.nodePackages.patch-package
              ];

              nodejs = pkgs.nodejs_20;
              npmDeps = pkgs.importNpmLock {
                npmRoot = ./.;
                fetcherOpts = {
                  "node_modules/@league-of-foundry-developers/foundry-vtt-types" = {
                    ref = "v12/main";
                    rev = pkgs.lib.strings.removePrefix "github:League-of-Foundry-Developers/foundry-vtt-types#" (
                      (pkgs.lib.importJSON ./package.json)
                      .devDependencies."@league-of-foundry-developers/foundry-vtt-types"
                    );
                  };
                };
              };
              npmConfigHook = pkgs.importNpmLock.npmConfigHook;
              preConfigure = ''
                echo $PATH
              '';
              installPhase = ''
                cp -r ./build/ $out/
              '';
            }
          );
        }
      );
    };
}
