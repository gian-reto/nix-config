{
  fetchurl,
  gzip,
  gnutar,
  lib,
  stdenvNoCC,
}: let
  version = "40.1.1";
  source = fetchurl {
    url = "https://registry.npmjs.org/@gotgenes/pi-permission-system/-/pi-permission-system-${version}.tgz";
    hash = "sha512-ySm2TUjWR3/Nowcb2inhhDBMmwvaEaBSquQiPEJaULLlBkLj6LJ+qx2ceSPyflfzABgW3osq7Ze3hVLQh5eGlw==";
  };
  dependencies = [
    {
      name = "node-addon-api";
      source = fetchurl {
        url = "https://registry.npmjs.org/node-addon-api/-/node-addon-api-8.7.0.tgz";
        hash = "sha512-9MdFxmkKaOYVTV+XVRG8ArDwwQ77XIgIPyKASB1k3JPq3M8fGQQQE3YpMOrKm6g//Ktx8ivZr8xo1Qmtqub+GA==";
      };
    }
    {
      name = "node-gyp-build";
      source = fetchurl {
        url = "https://registry.npmjs.org/node-gyp-build/-/node-gyp-build-4.8.4.tgz";
        hash = "sha512-LA4ZjwlnUblHVgq0oBF3Jl/6h/Nvs5fzBLwdEF4nuxnFdsfajde4WfxtJr3CaiH+F6ewcIB/q4jQ4UzPyid+CQ==";
      };
    }
    {
      name = "tree-sitter-bash";
      source = fetchurl {
        url = "https://registry.npmjs.org/tree-sitter-bash/-/tree-sitter-bash-0.25.1.tgz";
        hash = "sha512-7hMytuYIMoXOq24yRulgIxthE9YmggZIOHCyPTTuJcu6EU54tYD+4G39cUb28kxC6jMf/AbPfWGLQtgPTdh3xw==";
      };
    }
    {
      name = "web-tree-sitter";
      source = fetchurl {
        url = "https://registry.npmjs.org/web-tree-sitter/-/web-tree-sitter-0.26.9.tgz";
        hash = "sha512-YJwSHANl6XFgeEjB8nitgj0qZYt5gkIesJ4w2srS2wcLB4GUa4xcOkM0YaMsU6WNR53YVIkDSY7Ej4pf3IXtCA==";
      };
    }
    {
      name = "zod";
      source = fetchurl {
        url = "https://registry.npmjs.org/zod/-/zod-4.4.3.tgz";
        hash = "sha512-ytENFjIJFl2UwYglde2jchW2Hwm4GJFLDiSXWdTrJQBIN9Fcyp7n4DhxJEiWNAJMV1/BqWfW/kkg71UDcHJyTQ==";
      };
    }
  ];
in
  stdenvNoCC.mkDerivation {
    pname = "pi-permission-system";
    inherit version;

    dontUnpack = true;
    strictDeps = true;
    nativeBuildInputs = [
      gzip
      gnutar
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      tar --extract --gzip --file='${source}' --directory="$out" --strip-components=1

      ${lib.concatMapStringsSep "\n" (dependency: ''
          mkdir -p "$out/node_modules/${dependency.name}"
          tar --extract --gzip --file='${dependency.source}' \
            --directory="$out/node_modules/${dependency.name}" \
            --strip-components=1
        '')
        dependencies}

      runHook postInstall
    '';

    meta = {
      description = "Permission enforcement extension for the Pi coding agent";
      homepage = "https://github.com/gotgenes/pi-packages/tree/main/packages/pi-permission-system";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
