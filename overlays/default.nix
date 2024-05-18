# Defines custom overlays.
{
  outputs,
  inputs
}: {
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs =
      builtins.mapAttrs (
        _: flake: let
          legacyPackages = (flake.legacyPackages or {}).${final.system} or {};
          packages = (flake.packages or {}).${final.system} or {};
        in
          if legacyPackages != {}
          then legacyPackages
          else packages
      )
      inputs;
  };

  # Adds pkgs.stable == inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.
  stable = final: _: {
    stable = inputs.nixpkgs-stable.legacyPackages.${final.system};
  };

  # Adds my custom packages.
  additions = final: prev:
    import ../pkgs { pkgs = final; };

  # Custom modifications to existing packages (https://nixos.wiki/wiki/Overlays).
  # You can change versions, add patches, set compilation flags, anything really.
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    apple-color-emoji = final.stdenv.mkDerivation rec {
      name = "apple-color-emoji";
      version = "17.4";
      src = builtins.fetchurl {
        url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v${version}/AppleColorEmoji.ttf";
        sha256 = "sha256:1wahjmbfm1xgm58madvl21451a04gxham5vz67gqz1cvpi0cjva8";
      };
      dontUnpack = true;
      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/fonts/truetype
        cp $src $out/share/fonts/truetype/AppleColorEmoji.ttf

        runHook postInstall
      '';
    };
  };
}