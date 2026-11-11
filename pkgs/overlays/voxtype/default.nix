final: prev: {
  voxtype = prev.voxtype.overrideAttrs (previous: {
    # Provide SQLite explicitly for the Quickshell launcher's linker.
    buildInputs = (previous.buildInputs or []) ++ [final.sqlite];
  });
}
