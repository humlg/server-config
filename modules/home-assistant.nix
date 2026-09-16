{ ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
  };
  users.users.david.extraGroups = [ "libvirtd" ];

  services.glances.enable = true;

  networking.firewall.allowedTCPPorts = [
    8123   # HAOS web UI
    61208  # Glances REST API
  ];

  # Forward host:8123 into the HAOS VM on the libvirt NAT network.
  # 192.168.122.71 is pinned via a static DHCP reservation on the libvirt default network.
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp --dport 8123 -j DNAT --to-destination 192.168.122.71:8123
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -p tcp --dport 8123 -j DNAT --to-destination 192.168.122.71:8123 2>/dev/null || true
  '';
}
