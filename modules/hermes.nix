{ ... }:

{
  virtualisation.oci-containers.containers.hermes = {
    image = "nousresearch/hermes-agent:latest";
    autoStart = true;
    cmd = [ "gateway" "run" ];
    # Host networking so the container sits on the LAN (br0) and can send
    # Wake-on-LAN broadcasts to the Ollama host. Ports bind directly on the host.
    extraOptions = [ "--network=host" ];
    volumes = [ "/mnt/data/hermes:/opt/data" ];
    environment = {
      HERMES_DASHBOARD = "1";
    };
  };

  # Dashboard (9119) and gateway API (8642) on the LAN interface only.
  # WireGuard clients already reach all ports via trustedInterfaces in vpn.nix.
  networking.firewall.interfaces."br0".allowedTCPPorts = [ 8642 9119 ];

  systemd.tmpfiles.rules = [
    "d /mnt/data/hermes 0755 root root -"
  ];

  # Seed initial config on first deploy; does not overwrite.
  system.activationScripts.hermes-initial-config.text = ''
    mkdir -p /mnt/data/hermes
    if [ ! -f /mnt/data/hermes/config.yaml ]; then
      cat > /mnt/data/hermes/config.yaml << 'YAML'
    model:
      provider: custom
      base_url: "http://192.168.4.133:11434/v1"
      default: "huihui_ai/qwen3-abliterated:14b"
      context_length: 64000
    dashboard:
      basic_auth:
        username: david
        password_hash: "scrypt$16384$8$1$PnulUQY7jhtoNNckj1Tgtw==$caEJeXt0DCmNK6kpMiLt9x6fEiiAhL337mMcUaXO+Mw="
    YAML
    fi
  '';
}
