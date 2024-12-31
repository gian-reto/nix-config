import { GLib } from "astal";
import GdkPixbuf from "gi://GdkPixbuf";

/**
 * Normalize a home-relative (i.e., `~/...`) file path to the absolute
 * representation of the path (i.e., `/home/user/...`).
 *
 * Note: This will only expand '~' if present. All paths not starting with '~'
 * will be returned as is.
 *
 * Source: https://github.com/Jas-SinghFSU/HyprPanel.
 *
 * @param path The path to normalize.
 *
 * @returns The normalized path.
 */
export const expandRelativeHomePathToAbsolute = (path: string): string => {
  if (path.charAt(0) == "~") {
    // Replace will only replace the first match, in this case, the first character.
    return path.replace("~", GLib.get_home_dir());
  }

  return path;
};

/**
 * Checks if the provided file path points to a valid image.
 *
 * This function attempts to load an image from the specified filepath using
 * GdkPixbuf. If the image is successfully loaded, it returns true. Otherwise,
 * it logs an error and returns false.
 *
 * Note: Unlike GdkPixbuf, this function will normalize the given path.
 *
 * Source: https://github.com/Jas-SinghFSU/HyprPanel.
 *
 * @param imgFilePath The path to the image file.
 *
 * @returns True if the filepath is a valid image, false otherwise.
 */
export const isPathOfValidImage = (imgFilePath: string): boolean => {
  try {
    GdkPixbuf.Pixbuf.new_from_file(
      expandRelativeHomePathToAbsolute(imgFilePath)
    );
    return true;
  } catch (error) {
    console.info(error);
    return false;
  }
};
