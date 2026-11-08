_final: prev: {
  pi-coding-agent = prev.pi-coding-agent.overrideAttrs (previous: {
    # Remove once the fix from Nixpkgs PR #582756 is available.
    postInstall =
      (previous.postInstall or "")
      + ''
        if [ ! -e "$out/lib/node_modules/pi-monorepo/node_modules/@earendil-works/pi-schema" ]; then
          cp -r packages/schema "$out/lib/node_modules/pi-monorepo/node_modules/@earendil-works/pi-schema"
        fi
      '';
  });
}
