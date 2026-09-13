{ ... }:

{
  services.minecraft-server = {
    enable = true;
    eula = true;
    openFirewall = true;
    dataDir = "/mnt/data/minecraft";
  };
}
