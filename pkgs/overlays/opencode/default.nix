final: prev: {
  opencode = prev.opencode.overrideAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [final.makeWrapper];
    postFixup =
      (oldAttrs.postFixup or "")
      + ''
        wrapProgram $out/bin/opencode \
          --set LD_LIBRARY_PATH "${final.lib.makeLibraryPath [final.stdenv.cc.cc.lib]}"
      '';
  });
}
