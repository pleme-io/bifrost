# Toride system-level bridge module (NixOS + nix-darwin)
#
# Reads blackmatter.networkTopology at the system level and projects it
# into home-manager users' services.toride options via sharedModules.
#
# Usage in a flake consumer:
#   # System-level (NixOS or darwin):
#   modules = [ inputs.toride.nixosModules.default ... ];
#   # HM-level (in sharedModules):
#   home-manager.sharedModules = [ inputs.toride.homeManagerModules.default ... ];
#
# The system module auto-enables toride with topology data from
# blackmatter.networkTopology. Any user can override:
#   services.toride.enable = false;
{ config, lib, ... }: let
  topo = config.blackmatter.networkTopology;

  torideNodes = lib.mapAttrs (_: node: {
    ipv4 = node.ipv4;
    tailscaleIpv4 = node.tailscaleIpv4 or null;
    domains = node.domains;
  }) topo.nodes;

  torideServices = lib.mapAttrs (_: svc: {
    ipv4 = svc.ipv4;
    domains = svc.domains;
  }) topo.services;
in {
  home-manager.sharedModules = [
    ({ lib, ... }: {
      services.toride = {
        enable = lib.mkDefault true;
        nodes = lib.mkDefault torideNodes;
        services = lib.mkDefault torideServices;
      };
    })
  ];
}
