{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.hedgedoc;
in {

  options.pinpox.services.hedgedoc = {
    enable = mkEnableOption "Hedgodoc server";
  };
  config = mkIf cfg.enable {

    # Create system user and group
    services.hedgedoc = {
      enable = true;
      environmentFile = /var/src/secrets/hedgedoc/envfile;
      configuration = {

        protocolUseSSL = true; # Use https when loading assets
        allowEmailRegister = false; # Disable registration

        domain = "pads.0cx.de";
        # host = "127.0.0.1"; # Default
        # port = 3000; # Default
        allowOrigin = [ "localhost" ]; # TODO not sure if neeeded

        db = {
          dialect = "sqlite";
          storage = "/var/lib/hedgedoc/db.sqlite";
        };

        useCDN = true;

        # TODO check out github integration
        # github = {}

        # TODO check out oauth2 integration
        # oauth2 = {};

      };
    };
  };
}
