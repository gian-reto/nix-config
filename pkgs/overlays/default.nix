final: prev:
{
  "apple-color-emoji" = prev.callPackage ./apple-color-emoji {};
  "apple-fonts" = prev.callPackage ./apple-fonts {};
  "blink-mac-system-fonts" = prev.callPackage ./blink-mac-system-fonts {};
  # Pin to the last release before `z-async` to avoid the prompt redraw
  # regression. See:
  # https://github.com/marlonrichert/zsh-autocomplete/issues/891.
  zsh-autocomplete = prev.callPackage ./zsh-autocomplete {};
}
// (import ./opencode final prev)
