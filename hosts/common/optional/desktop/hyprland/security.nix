{
  pkgs,
  ...
}: {
  security = {
    polkit.enable = true;
    pam.services = {
      hyprlock = {
        enableGnomeKeyring = true;
      };
    };
  };
}