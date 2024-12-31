import { exec } from "astal/process";

/**
 * Returns the raw CSS stylesheet content for the given theme name. This
 * includes utility classes similar to TailwindCSS.
 */
export const getStylesheet = (theme: "adwaita-dark"): string => {
  const base = exec(`sass ${SRC}/theme/base/${theme}.scss`);
  // Styles for built-in GTK widgets. Note: This should not be used if possible,
  // and utility classes should be preferred for styling custom components.
  const widgets = exec(`sass ${SRC}/theme/widgets/${theme}/index.scss`);
  const utils = exec(`sass ${SRC}/theme/utils/index.scss`);
  // Styles for custom components. Note: This should not be used if possible,
  // and utility classes should be preferred for styling custom components.
  const components = exec(`sass ${SRC}/theme/components/index.scss`);

  return `${base}\n${widgets}\n${components}\n${utils}`;
};
