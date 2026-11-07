{lib, ...}: {
  config = {
    wrapperImplementation = lib.mkForce "nix";
    argv0type = command: ''
      if command -v op >/dev/null 2>&1; then
        exec op run -- ${command}
      fi
      exec ${command}
    '';
  };
}
