{
  lib,
  config,
  pkgs,
  ...
}: let
  userName = "taylor";
  userDescription = "taylor Jain";
in {
  options = {
  };
  config = {
    users.users.${userName} = {
      isNormalUser = true;
      description = userDescription;
      shell = pkgs.zsh;
      initialPassword = "taylor";
      extraGroups = ["wheel" "docker" "wireshark" "libvirtd" "kvm"];
    };
    programs.zsh.enable = true;
  };
}
