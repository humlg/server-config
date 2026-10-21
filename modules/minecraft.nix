{ pkgs, ... }:

{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/mnt/data/minecraft";

    servers.main = {
      enable = true;
      # ZGC: concurrent, near-zero pause GC — much better than G1 for avoiding multi-second freezes.
      # Small Xms and no AlwaysPreTouch so the JVM does not hold the full heap while idle;
      # ZGC returns unused heap to the OS when the server is empty.
      jvmOpts = "-Xms2G -Xmx6G -XX:+UseZGC -XX:+DisableExplicitGC -XX:+UseStringDeduplication";
      # Minecraft 26.x requires Java 25; override the default jdk21 that nix-minecraft ships with.
      package = pkgs.fabricServers."fabric-26_3".override {
        jre_headless = pkgs.jdk25_headless;
      };

      serverProperties = {
        server-port = 25565;
        online-mode = true;
        difficulty = "normal";
        max-players = 20;
        "pause-when-empty-seconds" = 60;
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
