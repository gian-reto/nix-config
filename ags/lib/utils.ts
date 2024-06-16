/**
 * Clamps the given `value` between `min` and `max`.
 */
export const clamp = (value: number, min: number, max: number) => {
  return Math.min(Math.max(value, min), max);
};

/**
 * @returns The result of `execAsync(cmd)`.
 */
export async function sh(cmd: string | string[]) {
  return Utils.execAsync(cmd).catch((err) => {
    console.error(typeof cmd === "string" ? cmd : cmd.join(" "), err);

    return "";
  });
}

/**
 * @returns `true` if all of the given `bins` are found.
 */
export function dependencies(...bins: string[]) {
  const missing = bins.filter((bin) =>
    Utils.exec({
      cmd: `which ${bin}`,
      out: () => false,
      err: () => true,
    })
  );

  if (missing.length > 0) {
    console.warn(Error(`Missing dependencies: ${missing.join(", ")}`));
    Utils.notify(`Missing dependencies: ${missing.join(", ")}`);
  }

  return missing.length === 0;
}
