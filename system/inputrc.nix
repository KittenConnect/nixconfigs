{ lib, ... }:

{
  environment.etc."inputrc".target = lib.mkForce "inputrc.orig"; # Important to re-use nixpkgs orig file
  environment.etc."inputrc.modified" = {
    target = "inputrc"; # Relative to /etc
    text = ''
      $include /etc/inputrc.orig # Import the Orig File
      # Additional stuff
      set completion-ignore-case On
      set completion-map-case On
      set completion-prefix-display-length 3
      set mark-symlinked-directories On
      set show-all-if-ambiguous On
      set show-all-if-unmodified On
      set visible-stats On

      $if mode=emacs
          "\e\e[C": forward-word
          "\e\e[D": backward-word
      $endif
    '';
  };
}
