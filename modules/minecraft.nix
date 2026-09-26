{ pkgs, ... }:

{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/mnt/data/minecraft";

    servers.main = {
      enable = true;
      jvmOpts = "-Xms8G -Xmx8G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+UseStringDeduplication";
      # Minecraft 26.x requires Java 25; override the default jdk21 that nix-minecraft ships with.
      package = pkgs.fabricServers."fabric-26_3".override {
        jre_headless = pkgs.jdk25_headless;
      };

      serverProperties = {
        server-port = 25565;
        online-mode = true;
        difficulty = "normal";
        max-players = 20;
      };

      symlinks = {
        "mods/distant-horizons.jar" = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/uCdwusMi/versions/gfi11b05/DistantHorizons-3.3.2-26.3-fabric-neoforge.jar";
          sha256 = "sha256-JK2PT0D9QaZiM5zNHAFAWndiDy90SAgZlGegzHaSefQ=";
        };
        "mods/journeymap.jar" = pkgs.fetchurl {
          url = "https://cdn.modrinth.com/data/lfHFW1mp/versions/FTYEzxSQ/journeymap-fabric-26.3-6.0.9.jar";
          sha256 = "sha256-3PPp6IAtq/tqyeF+9Dxcv7mJgI2TIcZWwSAfJhsTAew=";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
