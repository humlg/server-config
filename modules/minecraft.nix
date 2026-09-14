{ pkgs, ... }:

{
  services.minecraft-servers = {
    enable = true;
    eula = true;

    servers.main = {
      enable = true;
      # Verify the exact attribute name after `nix flake update`:
      #   nix eval .#nixosConfigurations.HomeLab.pkgs.fabricServers --apply builtins.attrNames
      package = pkgs.fabricServers."fabric-1_26_2";
      dataDir = "/mnt/data/minecraft";

      serverProperties = {
        server-port = 25565;
        online-mode = true;
        difficulty = "normal";
        max-players = 20;
      };

      # Add mods here as fetched derivations, e.g.:
      #
      #   "distant-horizons" = pkgs.fetchurl {
      #     url = "https://cdn.modrinth.com/data/<id>/versions/<ver>/distant-horizons-<ver>.jar";
      #     sha256 = lib.fakeSha256; # run `nix build` once to get the real hash
      #   };
      #
      # Grab the CDN URL from the Modrinth version page → "Download" button → copy link.
      # Mods needed: Distant Horizons (server-side), Xaero's Minimap, Xaero's World Map.
      mods = {};
    };
  };

  networking.firewall.allowedTCPPorts = [ 25565 ];
}
