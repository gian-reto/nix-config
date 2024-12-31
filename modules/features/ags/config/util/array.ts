/**
 * Returns an array of items from `a` that are not present in `b`.
 */
export const difference = <T>(a: Array<T>, b: Array<T>): Array<T> => {
  return a.filter((v) => !b.includes(v));
};
