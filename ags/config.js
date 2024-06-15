const out = `/tmp/ags`;

async function setupCss() {
  const scss = `${App.configDir}/style.scss`;
  const css = `${out}/style.css`;

  try {
    await Utils.execAsync(`sass ${scss} ${css}`);
  } catch (error) {
    console.error(error);
  }

  App.applyCss(css, true);
}

await setupCss();
Utils.monitorFile(`${App.configDir}/style`, setupCss);

const entry = `${App.configDir}/main.ts`;
try {
  await Utils.execAsync([
    "bun",
    "build",
    entry,
    "--outdir",
    out,
    "--external",
    "resource://*",
    "--external",
    "gi://*",
    "--external",
    "file://*",
  ]);

  await import(`file://${out}/main.js`);
} catch (error) {
  console.error(error);
  App.quit();
}

export {};
