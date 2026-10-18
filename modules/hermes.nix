{ ... }:

{
  services.hermes-agent = {
    enable = true;
    stateDir = "/mnt/data/hermes";
    settings.model = {
      provider = "custom";
      base_url = "http://192.168.4.133:11434/v1";
      default = "huihui_ai/qwen3-abliterated:14b";
      # Ollama's OpenAI-compatible API doesn't advertise context length; set it explicitly.
      context_length = 64000;
    };
  };

  # Dashboard (9119) and gateway API (8642) on the LAN interface only.
  # WireGuard clients (wg0) already reach all ports via trustedInterfaces in vpn.nix.
  networking.firewall.interfaces."br0".allowedTCPPorts = [ 8642 9119 ];

  systemd.tmpfiles.rules = [
    "d /mnt/data/hermes 0750 hermes hermes -"
  ];
}
