{ ... }:

{
  # --- Road-warrior server: lets a phone/laptop VPN in from outside and
  # reach both HomeLab and the rest of the home LAN. ---
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/wg0-server.key";

    # Add one entry per device, e.g.:
    # peers = [
    #   {
    #     publicKey = "<device public key>";
    #     allowedIPs = [ "10.100.0.2/32" ];
    #   }
    # ];
    peers = [ ];
  };

  # Lets wg0 peers reach the rest of 192.168.4.0/23 through HomeLab, not
  # just HomeLab itself.
  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg0" ];
    externalInterface = "enp59s0";
  };

  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    trustedInterfaces = [ "wg0" ];
  };

  # --- Egress confinement: forces Transmission's traffic through the VPN
  # provider's tunnel, with a kill switch if the tunnel drops. See
  # modules/media.nix for the systemd.services.transmission.vpnConfinement
  # wiring. ---
  vpnNamespaces.egress = {
    enable = true;
    wireguardConfigFile = "/etc/wireguard/egress.conf";

    # Who's allowed to reach Transmission's RPC/web UI (port-mapped below):
    # localhost (Sonarr, running in the default netns) and the LAN.
    accessibleFrom = [
      "127.0.0.1"
      "192.168.4.0/23"
    ];

    portMappings = [
      {
        from = 9091;
        to = 9091;
        protocol = "tcp";
      }
    ];
  };
}
