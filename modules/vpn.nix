{ pkgs, ... }:

{
  # --- Road-warrior server: lets a phone/laptop VPN in from outside and
  # reach both HomeLab and the rest of the home LAN. ---
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/wg0-server.key";

    peers = [
      # david-phone (added 2026-09-19)
      {
        publicKey = "PtYWTzI5vDdJpnm7HPKGsY12vs4xxzIHrc55dZOeHyY=";
        allowedIPs = [ "10.100.0.2/32" ];
      }
      # saruman (added 2026-09-19)
      {
        publicKey = "6GnexhHqRdmRk9YPWxttwjOdHjYqu8hw/uf/W4OoMgc=";
        allowedIPs = [ "10.100.0.3/32" ];
      }
    ];
  };

  # Lets wg0 peers reach the rest of 192.168.4.0/23 through HomeLab, not
  # just HomeLab itself.
  networking.nat = {
    enable = true;
    internalInterfaces = [ "wg0" ];
    externalInterface = "br0";
  };

  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
    trustedInterfaces = [ "wg0" ];
  };

  # --- Egress confinement: forces Transmission's traffic through the VPN
  # provider's tunnel, with a kill switch if the tunnel drops. See
  # modules/media.nix for the systemd.services.transmission.vpnConfinement
  # wiring. ---
  systemd.services.egress-heartbeat = {
    description = "Uptime Kuma heartbeat for egress VPN tunnel";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "egress-heartbeat" ''
        if systemctl is-active --quiet egress.service && \
           ${pkgs.iproute2}/bin/ip netns exec egress \
             ${pkgs.curl}/bin/curl -sf --max-time 5 http://detectportal.firefox.com/success.txt > /dev/null 2>&1; then
          status=up msg=OK
        else
          status=down msg=tunnel-down
        fi
        ${pkgs.curl}/bin/curl -sf \
          "http://192.168.4.151:3001/api/push/tk5AK9rCmUhcRRt5HRWDpKfCZYUCKffU?status=$status&msg=$msg&ping=" \
          || true
      '';
    };
  };

  systemd.timers.egress-heartbeat = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "50s";
    };
  };

  vpnNamespaces.egress = {
    enable = true;
    wireguardConfigFile = "/etc/wireguard/egress.conf";

    # Who's allowed to reach Transmission's RPC/web UI (port-mapped below):
    # the LAN and the host itself. Two addresses depending on the caller:
    #   LAN devices / laptop : 192.168.5.1:9091  (HomeLab's LAN IP; DNAT forwards into namespace)
    #   Host services (Sonarr, Radarr): 192.168.15.1:9091  (veth IP directly into namespace)
    # localhost:9091 won't work from the host — the DNAT rule is PREROUTING-only.
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
