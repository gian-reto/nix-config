{
  config,
  lib,
  pkgs,
  hmConfig,
  ...
}: {
  options.features.gpg.enable = lib.mkOption {
    description = ''
      Whether to enable the GPG feature.
    '';
    type = lib.types.bool;
    default = false;
    example = true;
  };

  config.hm = lib.mkIf config.features.gpg.enable {
    services.gpg-agent = {
      enable = true;

      enableSshSupport = true;
      # GPG authentication subkey fingerprint.
      sshKeys = ["5F96D8F3B7279399B379E442BAA4C7E744431D44"];
      enableExtraSocket = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    home.packages = lib.optional hmConfig.gtk.enable pkgs.gcr;

    programs = let
      fixGpg = ''
        gpgconf --launch gpg-agent
      '';
    in {
      # Start `gpg-agent` if it's not running or tunneled in. SSH does not start
      # it automatically, so this is needed to avoid having to use a gpg command
      # at startup (https://www.gnupg.org/faq/whats-new-in-2.1.html#autostart).
      bash.profileExtra = fixGpg;
      zsh.loginExtra = fixGpg;

      gpg = {
        enable = true;

        settings = {
          # https://github.com/drduh/config/blob/master/gpg.conf
          # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
          # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html
          # Experimental trust model that combines TOFU (Trust On First Use) and Web of Trust.
          trust-model = "tofu+pgp";
          # Use AES256, 192, or 128 as cipher.
          personal-cipher-preferences = "AES256 AES192 AES";
          # Use SHA512, 384, or 256 as digest.
          personal-digest-preferences = "SHA512 SHA384 SHA256";
          # Use ZLIB, BZIP2, ZIP, or no compression.
          personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
          # Default preferences for new keys.
          default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
          # SHA512 as digest to sign keys.
          cert-digest-algo = "SHA512";
          # SHA512 as digest for symmetric ops.
          s2k-digest-algo = "SHA512";
          # AES256 as cipher for symmetric ops.
          s2k-cipher-algo = "AES256";
          # UTF-8 support for compatibility.
          charset = "utf-8";
          # Show Unix timestamps.
          fixed-list-mode = "";
          # No comments in signature.
          no-comments = "";
          # No version in signature.
          no-emit-version = "";
          # Disable banner.
          no-greeting = "";
          # Long hexidecimal key format.
          keyid-format = "0xlong";
          # Display UID validity.
          list-options = "show-uid-validity";
          verify-options = "show-uid-validity";
          # Display all keys and their fingerprints.
          with-fingerprint = "";
          # Cross-certify subkeys are present and valid.
          require-cross-certification = "";
          # Disable caching of passphrase for symmetrical ops.
          no-symkey-cache = "";
          # Enable smartcard.
          use-agent = "";
        };
        publicKeys = [
          {
            source = ../../files/pgp.asc;
            trust = 5;
          }
        ];
      };
    };

    systemd.user.services = {
      # Link `/run/user/$UID/gnupg` to `~/.gnupg-sockets` so that SSH config does
      # not have to know the UID.
      link-gnupg-sockets = {
        Unit = {
          Description = "Link gnupg sockets from /run to /home";
        };
        Install.WantedBy = ["default.target"];
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/ln -Tfs /run/user/%U/gnupg %h/.gnupg-sockets";
          ExecStop = "${pkgs.coreutils}/bin/rm $HOME/.gnupg-sockets";
          RemainAfterExit = true;
        };
      };
    };
  };
}