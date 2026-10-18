{ ... }:

{
  services.hermes-agent = {
    enable = true;
    stateDir = "/mnt/data/hermes";
    # API keys (ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.) — deployed out-of-band to /etc/hermes-env
    environmentFiles = [ "/etc/hermes-env" ];
  };

  # Dashboard (9119) and gateway API (8642) on the LAN interface only.
  # WireGuard clients (wg0) already reach all ports via trustedInterfaces in vpn.nix.
  networking.firewall.interfaces."br0".allowedTCPPorts = [ 8642 9119 ];

  systemd.tmpfiles.rules = [
    "d /mnt/data/hermes 0750 hermes hermes -"
  ];
}
