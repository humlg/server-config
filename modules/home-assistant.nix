{ ... }:

{
  services.home-assistant = {
    enable = true;
    configDir = "/mnt/data/home-assistant";
    extraComponents = [
      "default_config"
      "esphome"
      "met"
      "zha"
    ];
    # Let HA manage configuration.yaml directly; config = null prevents Nix from
    # generating a read-only symlink. openFirewall can't be used when config is null
    # because the module unconditionally dereferences cfg.config.http.server_port.
    config = null;
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  users.users.hass.extraGroups = [ "dialout" ];

  # The HA module sets DevicePolicy=closed, which blocks all char devices unless
  # explicitly listed — group membership alone isn't enough.
  systemd.services.home-assistant.serviceConfig = {
    DeviceAllow = [ "char-tty rw" ];
    SupplementaryGroups = [ "dialout" ];
  };
}
