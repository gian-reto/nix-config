# Common features that should be enabled for all modules.
{
  config,
  ...
}: {
  config.features.bash.enable = true;
  config.features.bat.enable = true;
  config.features.bluetooth.enable = true;
  config.features.btop.enable = true;
  config.features.containers.enable = true;
  config.features.fastfetch.enable = true;
  config.features.git.enable = true;
  config.features.gpg.enable = true;
  config.features.i18n.enable = true;
  config.features.network.enable = true;
  config.features.ssh.enable = true;
  config.features.xdg.enable = true;
  config.features.yubikey.enable = true;
  config.features.zsh.enable = true;
}