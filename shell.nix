#! /usr/bin/env nix-shell
#! nix shell -f
(import ./. {}).outputs.devShells.default
