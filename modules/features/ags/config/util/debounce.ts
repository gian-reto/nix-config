import { AstalIO, timeout } from "astal";

/**
 * Returns a debounced version of the given function `fn`.
 */
export const debounce = <
  F extends (
    ...args: Parameters<F>
  ) => Exclude<ReturnType<F>, PromiseLike<unknown>>
>(
  fn: F,
  options: {
    /**
     * The number of milliseconds to wait between executions of `fn`, if it's
     * called again during cooldown.
     */
    readonly waitForMs: number;
    /**
     * Whether to execute `fn` immediately when it's called for the first time.
     * Defaults to `true`.
     */
    readonly immediate?: boolean;
  }
): ((...args: Parameters<F>) => void) => {
  const { waitForMs, immediate = true } = options;

  let timer: AstalIO.Time | undefined = undefined;

  return (...args: Parameters<F>): void => {
    const later = () => {
      timer = undefined;
      if (!immediate) {
        fn(...args);
      }
    };

    const callNow = immediate && timer === undefined;

    timer?.cancel();
    timer = timeout(waitForMs, later);

    if (callNow) {
      fn(...args);
    }
  };
};
