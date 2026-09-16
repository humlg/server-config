{ pkgs, ... }:

{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/mnt/data/minecraft";

    servers.main = {
      enable = true;
      # Verify the exact attribute name after `nix flake update`:
      #   nix eval .#nixosConfigurations.HomeLab.pkgs.fabricServers --apply builtins.attrNames
      package = pkgs.fabricServers."fabric-26_2";

      serverProperties = {
        server-port = 25565;
        online-mode = true;
        difficulty = "normal";
        max-players = 20;
      };

      # Mods are added via symlinks into the server directory, e.g.:
      #
      #   symlinks."mods/distant-horizons.jar" = pkgs.fetchurl {
      #     url = "https://cdn.modrinth.com/data/<id>/versions/<ver>/distant-horizons-<ver>.jar";
      #     sha256 = "sha256-<hash>=";
      #   };
      #
      # Mods needed: Distant Horizons (server-side), Xaero's Minimap, Xaero's World Map.
    };
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
