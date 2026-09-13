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
    config = {
      default_config = { };
      http = {
        server_host = "0.0.0.0";
      };
    };
    openFirewall = true;
  };

  users.users.hass.extraGroups = [ "dialout" ];

  # The HA module sets DevicePolicy=closed, which blocks all char devices unless
  # explicitly listed — group membership alone isn't enough.
  systemd.services.home-assistant.serviceConfig = {
    DeviceAllow = [ "char-tty rw" ];
    SupplementaryGroups = [ "dialout" ];
  };
}
