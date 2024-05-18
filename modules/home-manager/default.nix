# Gathers the custom reusable `home-manager` modules (https://nixos.wiki/wiki/Module).
# Note: This should be stuff you would like to share with others, not your personal configurations.
{
  fonts = import ./fonts.nix;
  theme = import ./theme.nix;
}