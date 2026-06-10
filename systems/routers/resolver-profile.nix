# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  kittenLib,
  pkgs,
  ...
}:
{
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  services.resolved.enable = false; # Causes issues

  # Resolver
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [
          "127.0.0.1"
          "1010:cafe:ffff:fefe::53"
        ];
        verbosity = 3;

        access-control = [
          "127.0.0.0/8 allow"
          "::1/128 allow"

          "1010:cafe::/32 allow"
        ];

        domain-insecure = [
          "kitten"
          "dn42"
        ]; # TODO: DNSSec
      };
      forward-zone = [
        {
          name = "kitten.";
          forward-addr = [
            "1010:cafe:ffff:fefe::12:10"
            "1010:cafe:ffff:fefe::b48d"
          ];
        }
        {
          name = "dn42.";
          forward-addr = [
            "fd42:d42:d42:53::1"
            "fd42:d42:d42:54::1"
          ];
        }

        # {
        #   name = "kittenconnect.net.";
        #   forward-addr = [
        #     "ns1.kittenconnect.net"
        #     "ns2.kittenconnect.net"
        #   ];
        # }
        {
          name = ".";
          forward-addr = [
            "2620:fe::fe"
            "9.9.9.9"
          ];
        }
      ];
      remote-control.control-enable = true;

    };
  };
}
