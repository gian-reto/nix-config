import { clamp } from "./number";

/**
 * Returns an array of items from `a` that are not present in `b`.
 */
export const difference = <T>(a: Array<T>, b: Array<T>): Array<T> => {
  return a.filter((v) => !b.includes(v));
};

/**
 * Returns an array containing cunks of `size` items from `array`. Note: The
 * last chunk may contain less than `size` items.
 */
export const chunk = <T>(array: Array<T>, size: number): Array<Array<T>> => {
  return Array.from({ length: Math.ceil(array.length / size) }, (_, i) =>
    array.slice(i * size, clamp(i * size + size, 0, array.length))
  );
};
