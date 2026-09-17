{ pkgs, ... }:

let
  networkXml = pkgs.writeText "haos-libvirt-network.xml" ''
    <network>
      <name>default</name>
      <uuid>fe148658-2d07-4a50-95c1-44b8bf799c29</uuid>
      <forward mode='nat'>
        <nat><port start='1024' end='65535'/></nat>
      </forward>
      <bridge name='virbr0' stp='on' delay='0'/>
      <mac address='52:54:00:e2:9e:e0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.122.2' end='192.168.122.254'/>
          <host mac='52:54:00:4f:8e:56' ip='192.168.122.71'/>
        </dhcp>
      </ip>
    </network>
  '';
in
{
  virtualisation.libvirtd = {
    enable = true;
    qemu.runAsRoot = false;
  };
  users.users.david.extraGroups = [ "libvirtd" ];

  services.glances.enable = true;

  # nginx proxies port 8123 on the host's LAN IP to the HAOS VM over the
  # libvirt NAT network. Simpler and more reliable than iptables DNAT, which
  # conflicts with libvirt's own FORWARD rules regardless of firewall backend
  # settings. 192.168.122.71 is pinned via the static DHCP reservation above.
  services.nginx = {
    enable = true;
    virtualHosts."haos" = {
      listen = [{ addr = "0.0.0.0"; port = 8123; }];
      locations."/" = {
        proxyPass = "http://192.168.122.71:8123";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_set_header Host $host:$server_port;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_redirect http://192.168.122.71/ http://$host:$server_port/;
          proxy_redirect ~^http://[^/]+/(.*)$ http://$host:$server_port/$1;
        '';
      };
    };
  };
  # VM internet access: libvirt's NAT handles this internally via its own
  # MASQUERADE; no internalInterfaces entry needed here.
  networking.nat.internalInterfaces = [ "virbr0" ];

  networking.firewall.allowedTCPPorts = [
    8123   # HAOS (nginx proxy)
    61208  # Glances REST API
  ];

  # Manages the libvirt network and HAOS VM on every boot.
  systemd.services.haos-vm = {
    description = "Home Assistant OS VM";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.libvirt ];
    script = ''
      uri="qemu:///system"

      virsh -c "$uri" net-define ${networkXml}
      virsh -c "$uri" net-autostart default --disable 2>/dev/null || true
      virsh -c "$uri" autostart homeassistant --disable 2>/dev/null || true

      if virsh -c "$uri" net-info default 2>/dev/null | grep -q "Active:.*yes"; then
        vm_state=$(virsh -c "$uri" domstate homeassistant 2>/dev/null || echo "absent")
        if ! echo "$vm_state" | grep -qE "shut off|absent"; then
          virsh -c "$uri" shutdown homeassistant 2>/dev/null || true
          for i in $(seq 30); do
            virsh -c "$uri" domstate homeassistant 2>/dev/null | grep -q "shut off" && break
            sleep 2
          done
          virsh -c "$uri" destroy homeassistant 2>/dev/null || true
        fi
        virsh -c "$uri" net-destroy default
      fi

      virsh -c "$uri" net-start default
      virsh -c "$uri" start homeassistant
    '';
  };
}
