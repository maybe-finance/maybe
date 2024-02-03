{
  description = "virtual environments";

  inputs.devshell.url = "github:numtide/devshell";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, flake-utils, devshell, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default =
        let
          pkgs = import nixpkgs {
            inherit system;

            overlays = [ devshell.overlays.default ];

            config.permittedInsecurePackages = [];
          };
          openssl = pkgs.openssl_3_2.dev;
        in
        pkgs.devshell.mkShell {
          imports = [ (pkgs.devshell.importTOML ./devshell.toml) ];
          packages = [ pkgs.readline pkgs.ruby_3_3 pkgs.pkg-config pkgs.libtool pkgs.shared-mime-info ];
          env = [
            {
              name = "PKG_CONFIG_PATH";
              value = "${pkgs.pkg-config}";
            }
            {
              name = "FREEDESKTOP_MIME_TYPES_PATH";
              value = "${pkgs.shared-mime-info}/share/mime/packages/freedesktop.org.xml";
            }
            {
              name = "LIBTOOL";
              value = "${pkgs.libtool}";
            }
            {
              name = "OPENSSL_DIR";
              value = "${openssl}";
            }
            {
              name = "OPENSSL_LIB_DIR";
              value = "${openssl}/lib";
            }
            {
              name = "OPENSSL_INCLUDE_DIR";
              value = "${openssl}/include";
            }
          ];
        };
    });
}
