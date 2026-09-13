{ ... }:

{
  services.jellyfin = {
    enable = true;
    group = "media";
    openFirewall = true;
  };

  # Torrent traffic is confined to the "egress" netns (see modules/vpn.nix)
  # so it only ever leaves through the VPN provider's tunnel — if that
  # tunnel is down, the confinement's kill switch drops the traffic instead
  # of falling back to the LAN uplink.
  services.transmission = {
    enable = true;
    group = "media";
    settings = {
      download-dir = "/mnt/data/downloads/complete";
      incomplete-dir = "/mnt/data/downloads/incomplete";
      incomplete-dir-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
    };
  };

  systemd.services.transmission.vpnConfinement = {
    enable = true;
    vpnNamespace = "egress";
  };

  services.sonarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };

  # No native nixpkgs module; DynamicUser and doesn't touch media files
  # directly (it only feeds indexer results to Sonarr/Transmission), so it
  # doesn't need the shared "media" group.
  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  # Homarr has no nixpkgs module — run it as a container.
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.homarr = {
    image = "ghcr.io/homarr-labs/homarr:latest";
    autoStart = true;
    ports = [ "7575:7575" ];
    volumes = [
      "/mnt/data/homarr:/appdata"
    ];
    environment = {
      TZ = "Europe/Prague";
    };
    # Contains SECRET_ENCRYPTION_KEY (64 hex chars, `openssl rand -hex 32`),
    # deployed out-of-band — not committed to git.
    environmentFiles = [ "/etc/homarr/env" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/data/homarr 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 7575 ];
}
