{pkgs, ...}: {
  imports = [
    ./bash.nix
    ./bat.nix
    ./git.nix
    ./gpg.nix
    ./pfetch.nix
    ./ssh.nix
    ./zsh.nix
  ];
  home.packages = with pkgs; [
    comma # Runs programs without installing them. Example: `, cowsay howdy`.

    btop # System monitor.
    httpie # Better curl.

    nil # Nix LSP.
    alejandra # Nix formatter.
    nh # Nice wrapper for NixOS and HM
  ];
}