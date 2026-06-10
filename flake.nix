{
  description = "highlight — highlight selected text on any page";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-webext.url = "github:rivavolt/nix-webext";
  };

  outputs = { self, nixpkgs, nix-webext }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          manifest = builtins.fromJSON (builtins.readFile ./manifest.json);
        in
        # Plain MV3, no build step. nix-webext takes the raw source plus the file
        # list, applies the per-browser background transform (Chrome
        # service_worker / Firefox event-page scripts), and emits the signed-at-
        # activation CRX manifest + Firefox XPI. extId is the stable Chrome ID the
        # old committed key derived (key now lives in fleet sops).
        nix-webext.lib.mkBrowserExtension {
          inherit pkgs;
          pname = "highlight";
          version = manifest.version;
          extId = "cfbijkcjpncoflpladdmdombmhnefcek";
          src = self;
          files = [ "manifest.json" "background.js" "content.js" "styles.css" ];
        });
    };
}
