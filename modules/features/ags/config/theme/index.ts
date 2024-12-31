import { exec } from "astal/process";

/**
 * Returns the raw CSS stylesheet content for the given theme name. This
 * includes utility classes similar to TailwindCSS.
 */
export const getStylesheet = (theme: "adwaita-dark"): string => {
  const base = exec(`sass ${SRC}/theme/base/${theme}.scss`);
  const utils = exec(`sass ${SRC}/theme/utils/index.scss`);

  return `${base}\n${utils}`;
};
