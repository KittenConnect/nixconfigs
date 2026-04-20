args@{
  lib,
  pkgs,
  sources,
  config,
  options,
  ...
}:
let
  inherit (lib.options) mkEnableOption;

  mkEnabledOption =
    desc:
    lib.mkEnableOption desc
    // {
      example = false;
      default = true;
    };

  cfg = config.kittenHome.zsh;
in
{
  options.kittenHome.zsh = {
    enable = mkEnabledOption "common kitten packages installation";
  };

  config = lib.mkIf (cfg.enable) {
    # starship - an customizable prompt for any shell
    programs.starship = {
      enable = true;
      # custom settings
      settings = {
        add_newline = false;
        aws.disabled = true;
        gcloud.disabled = true;
        username.show_always = true;
        # line_break.disabled = true;
      };
    };

    programs.pay-respects.enable = true;
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;

      defaultKeymap = "emacs";

      autocd = true;

      initContent = lib.mkMerge ([
        "unsetopt complete_aliases"

        ''export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin:$HOME/.krew/bin"''

        ''
          function nixtory() {
            local ARG=history
            if [[ "$1" == "--clean" ]]; then
              ARG=wipe-history
            fi

            local SUDO=()
            if [[ "$ARG" == "wipe-history" ]]; then
              SUDO=sudo;
            fi

            ''${SUDO:-} nix profile $ARG --profile /nix/var/nix/profiles/system;
            if [[ "$ARG" == "wipe-history" ]]; then
              ''${SUDO:-} nix-collect-garbage -d
            fi
          }

        ''

        ''
          sshKillall() { for f in ~/.ssh/*; do [ -S $f ] || continue; ssh -o ControlPath=$f -O exit _; done; }
        ''

        ''
          # pveversion for nix
          function nixversion(){ printf "# System Packages\n"; cat /etc/current-system-packages ; printf "\n\n# Home Packages\n"; cat "$HOME/current-home-packages"; echo; }
        ''
      ]);

      syntaxHighlighting.enable = true;
      autosuggestion.enable = true;

      oh-my-zsh = {
        enable = true;

        plugins = [
          "git"
          "thefuck"
        ];
        theme = "";
      };

      historySubstringSearch.enable = true;
      history = {
        ignoreAllDups = true;
        ignoreSpace = true;

        ignorePatterns = [
          "rm *"
          "pkill *"

          # "[.]+" # Cd ....

          # "ccccc[:alnum:]+" # YubiKey fail
        ];

        extended = true;
      };

      # set some aliases, feel free to add more or remove some
      shellAliases = {
        rl = "exec $SHELL"; # Reload

        mv = "mv -vi"; # ask confirmation on dangerous operations
        rm = "rm -vI"; # ask confirmation on dangerous operations
        svim = "sudo vim";
        passh = "ssh -o PreferredAuthentications=password,keyboard-interactive";

        #urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
        #urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
      };

      plugins = [
        {
          name = "jq";
          # file = "init.sh";
          src = pkgs.fetchFromGitHub {
            owner = "reegnz";
            repo = "jq-zsh-plugin";
            rev = "48befbcd91229e48171d4aac5215da205c1f497e";

            sha256 = if true then "q/xQZ850kifmd8rCMW+aAEhuA43vB9ZAW22sss9e4SE=" else lib.fakeSha256;
          };
        }
        {
          name = "zsh-fzf-tab";
          file = "fzf-tab.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "v1.1.2";
            sha256 = if true then "0ymp9ky0jlkx9b63jajvpac5g3ll8snkf8q081g0yw42b9hwpiid" else lib.fakeSha256;
          };
        }
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.8.0";
            sha256 = if true then "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7" else lib.fakeSha256;
          };
        }
        {
          name = "clip";
          file = "clipboard.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "zpm-zsh";
            repo = "clipboard";
            rev = "546752e48b8c776d19a1ac42b34b1cb5c206397c";
            sha256 = "sha256-FMwQza1WjMShV30uRR6rqmQtoRcwzZ7FwyniatvTGXQ=";
          };
        }
        {
          name = "hacker-quotes";
          file = "hacker-quotes.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "oldratlee";
            repo = "hacker-quotes";
            rev = "3533d29d294c83a42625c46aaac9f8caa646d2d5";
            sha256 = "sha256-cJ7JSADc9QzZaL86qJ4vqB2N1Qwm9rSFL5g/KEyLnyM=";
          };
        }
      ];
    };

    # home.sessionVariables = {  };
  };
}
