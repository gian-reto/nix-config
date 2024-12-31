/**
 * Returns the clamped value of `value` between `min` and `max`. If `min` or
 * `max` is not provided, the value is not clamped on that side.
 */
export const clamp = (value: number, min?: number, max?: number): number => {
  if (min !== undefined && value < min) return min;
  if (max !== undefined && value > max) return max;

  return value;
};
