{ pkgs, ... }:

let
  # Network XML is kept in the Nix store so the firewall backend='none' setting
  # (which prevents libvirt from inserting its own FORWARD REJECT rules) survives
  # reboots. The haos-vm service redefines it on every boot before starting the VM.
  networkXml = pkgs.writeText "haos-libvirt-network.xml" ''
    <network>
      <name>default</name>
      <uuid>fe148658-2d07-4a50-95c1-44b8bf799c29</uuid>
      <forward mode='nat'>
        <nat><port start='1024' end='65535'/></nat>
      </forward>
      <bridge name='virbr0' stp='on' delay='0'/>
      <mac address='52:54:00:e2:9e:e0'/>
      <firewall backend='none'/>
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

  # Disable libvirt's own firewall management globally so it doesn't insert
  # FORWARD REJECT rules that block our NixOS-managed port forwarding.
  environment.etc."libvirt/network.conf".text = ''
    firewall_backend = "none"
  '';

  services.glances.enable = true;

  networking.firewall.allowedTCPPorts = [
    8123   # HAOS web UI
    61208  # Glances REST API
  ];

  # NixOS owns all forwarding rules for virbr0 (libvirt firewall is disabled above).
  # internalInterfaces handles VM internet access; forwardPorts handles inbound to HAOS.
  # 192.168.122.71 is pinned via the static DHCP reservation in networkXml above.
  networking.nat.internalInterfaces = [ "virbr0" ];
  networking.nat.forwardPorts = [
    { proto = "tcp"; sourcePort = 8123; destination = "192.168.122.71:8123"; }
  ];

  # Configures the libvirt network and starts the HAOS VM on every boot.
  # Replaces libvirt's own autostart so the network firewall config is always correct.
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

      # net-define only updates the persisted XML; the running network keeps its old
      # firewall rules. Restart it so firewall backend=none actually takes effect.
      if virsh -c "$uri" net-info default 2>/dev/null | grep -q "Active:.*yes"; then
        # Gracefully shut down the VM before destroying the network
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
