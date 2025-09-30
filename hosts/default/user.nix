{
  lib,
  config,
  pkgs,
  ...
}: let
  userName = "tocaro";
  userDescription = "tocaro Jain";
in {
  options = {
  };
  config = {
    users.users.${userName} = {
      isNormalUser = true;
      description = userDescription;
      shell = pkgs.zsh;
      initialPassword = "tocaro";
      extraGroups = ["wheel" "docker" "wireshark" "libvirtd" "kvm"];
    };
    programs.zsh.enable = true;
  };
}
