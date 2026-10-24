{ ... }:

{
  services.miniflux = {
    enable = true;
    # File must contain ADMIN_USERNAME and ADMIN_PASSWORD, e.g.:
    #   ADMIN_USERNAME=admin
    #   ADMIN_PASSWORD=yourpassword
    # Deploy out-of-band to /etc/miniflux/credentials — not committed to git.
    adminCredentialsFile = "/etc/miniflux/credentials";
    config = {
      LISTEN_ADDR = "0.0.0.0:8080";
      BASE_URL = "http://homelab:8080/";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
