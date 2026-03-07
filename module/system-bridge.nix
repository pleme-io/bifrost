# Bifrost system-level bridge module (NixOS + nix-darwin)
#
# Reads blackmatter.networkTopology at the system level and projects it
# into home-manager users' services.bifrost options via sharedModules.
#
# Usage in a flake consumer:
#   # System-level (NixOS or darwin):
#   modules = [ inputs.bifrost.nixosModules.default ... ];
#   # HM-level (in sharedModules):
#   home-manager.sharedModules = [ inputs.bifrost.homeManagerModules.default ... ];
#
# The system module auto-enables bifrost with topology data from
# blackmatter.networkTopology. Any user can override:
#   services.bifrost.enable = false;
{ config, lib, ... }: let
  topo = config.blackmatter.networkTopology;

  bifrostNodes = lib.mapAttrs (_: node: {
    ipv4 = node.ipv4;
    tailscaleIpv4 = node.tailscaleIpv4 or null;
    domains = node.domains;
  }) topo.nodes;

  bifrostServices = lib.mapAttrs (_: svc: {
    ipv4 = svc.ipv4;
    domains = svc.domains;
  }) topo.services;
in {
  home-manager.sharedModules = [
    ({ lib, ... }: {
      services.bifrost = {
        enable = lib.mkDefault true;
        nodes = lib.mkDefault bifrostNodes;
        services = lib.mkDefault bifrostServices;
      };
    })
  ];
}
