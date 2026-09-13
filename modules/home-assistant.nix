{ ... }:

{
  services.home-assistant = {
    enable = true;
    configDir = "/mnt/data/home-assistant";
    extraComponents = [
      "default_config"
      "esphome"
      "met"
    ];
    config = {
      default_config = { };
      http = {
        server_host = "0.0.0.0";
      };
    };
    openFirewall = true;
  };
}
