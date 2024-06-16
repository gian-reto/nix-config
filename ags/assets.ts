const ASSETS_PATH = `${App.configDir}/assets`;

const assetPathFor = (base: "icons") => {
  return `${ASSETS_PATH}/${base}`;
};

export const assetPaths = {
  icons: {
    "nix-snowflake-symbolic": `${assetPathFor(
      "icons"
    )}/nix-snowflake-symbolic.svg`,
  },
};
