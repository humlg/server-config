{ pkgs, ... }:

{
  # rtl_tcp exposes the RTL-SDR dongle over TCP so SDR++ (and other clients)
  # can connect from other devices on the LAN using the "RTL-SDR Server" source.
  # Default port 1234; SDR++ connects to <this-host>:1234.
  environment.systemPackages = [ pkgs.rtl-sdr ];

  # Allow the kernel driver to be used by non-root via udev rules.
  # If the dongle was already plugged in before first deploy, the rules won't
  # apply automatically — run: sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=usb --action=add
  hardware.rtl-sdr.enable = true;

  systemd.services.rtl-tcp = {
    description = "RTL-SDR TCP server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.rtl-sdr}/bin/rtl_tcp -a 0.0.0.0 -p 1234";
      Restart = "on-failure";
      RestartSec = "5s";
      # Run as a dedicated user so the service doesn't need root.
      # The rtl-sdr udev rules grant access to the `plugdev` group.
      User = "rtlsdr";
      Group = "plugdev";
    };
  };

  users.users.rtlsdr = {
    isSystemUser = true;
    group = "plugdev";
    description = "rtl_tcp service user";
  };

  networking.firewall.allowedTCPPorts = [ 1234 ];
}
