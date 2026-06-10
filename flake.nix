{
  description = "highlight — highlight selected text on any page";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-crx.url = "github:rivavolt/nix-crx";
  };

  outputs = { self, nixpkgs, nix-crx }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          manifest = builtins.fromJSON (builtins.readFile ./manifest.json);
          geckoId = manifest.browser_specific_settings.gecko.id;

          # The WebExtension is plain MV3 with no build step; one manifest serves
          # both browsers (Chrome reads background.service_worker, Firefox reads
          # background.scripts).
          extension = pkgs.stdenv.mkDerivation {
            pname = "highlight-extension";
            version = manifest.version;
            src = self;
            dontBuild = true;
            installPhase = ''
              mkdir -p $out/share/chromium-extension
              cp manifest.json background.js content.js styles.css $out/share/chromium-extension/
            '';
          };

          # Chrome: pack a signed CRX and an external-extension manifest so
          # the browser installs it persistently.
          crxPkg = nix-crx.lib.mkCrxPackage {
            inherit pkgs extension;
            key = ./keys/signing.pem;
            name = "highlight";
            version = manifest.version;
          };

          extDir = "share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";

          # Firefox: zip the extension into an unsigned XPI. sign-extension.sh
          # in the nixos-config repo signs this via AMO's unlisted channel.
          firefoxXpi = pkgs.stdenv.mkDerivation {
            pname = "highlight-firefox-xpi";
            version = manifest.version;
            dontUnpack = true;
            nativeBuildInputs = [ pkgs.zip ];
            buildPhase = ''
              cd ${extension}/share/chromium-extension
              zip -r $TMPDIR/extension.xpi .
            '';
            installPhase = ''
              mkdir -p $out/${extDir}
              cp $TMPDIR/extension.xpi $out/${extDir}/${geckoId}.xpi
            '';
          };
        in {
          chrome = crxPkg.package;
          firefox = firefoxXpi;

          default = pkgs.symlinkJoin {
            name = "highlight";
            paths = [
              crxPkg.package
              firefoxXpi
            ];
          };
        }
      );
    };
}
