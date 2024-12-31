/**
 * Denotes an unreachable code path, e.g., in a `switch` statement.
 *
 * @throws {Error} Always throws an error.
 */
export const unreachable = (
  value: never,
  messageOrError?: string | Error
): never => {
  const error =
    messageOrError instanceof Error
      ? messageOrError
      : new Error(messageOrError ?? "Unreachable code path reached");

  console.error(error);
  throw error;
};
