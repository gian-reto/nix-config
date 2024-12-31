type Argument = string[] | string | boolean | null | undefined;

/**
 * Merge class names and filter out falsy and duplicate values. Note: If an
 * argument contains spaces, it will be split into separate class names in the
 * resulting array.
 *
 * @example
 * ```ts
 * cx("foo", "bar", false && "baz", null, undefined); // ["foo", "bar"]
 * ```
 *
 * @param args The expressions to evaluate.
 *
 * @returns The cleaned class names.
 */
function cx(...args: Argument[]): string[];
function cx(): string[] {
  let classes = [];

  for (let i = 0; i < arguments.length; ) {
    const arg: unknown = arguments[i++];
    if (!arg) {
      continue;
    }
    if (Array.isArray(arg)) {
      classes.push(...cx(...arg));
    }
    if (typeof arg === "string") {
      classes.push(...arg.split(" "));
    }
  }

  return classes;
}

export { cx };
