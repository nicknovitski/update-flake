{
  config,
  flake-parts-lib,
  lib,
  ...
}: {
  options.perSystem =
    flake-parts-lib.mkPerSystemOption
    ({
      config,
      pkgs,
      self',
      ...
    }: let
      inherit (lib.types) any attrsOf submodule lines listOf nonEmptyStr package nullOr;
      inherit (lib) mkEnableOption mkOption mkIf;
      cfg = config.update;
      updatePhaseOption = beforeOrAfter:
        mkOption {
          default = {};
          type = submodule {
            options = {
              bash = mkOption {
                default = "";
                description = "Run these commands in the bash script ${beforeOrAfter} updating flake inputs.";
                type = lines;
              };
            };
          };
        };
    in {
      options.update = {
        enable = mkEnableOption "Add update flake package";
        name = mkOption {
          default = "update-flake";
          example = "update-flake-lock";
          description = "Name of the update flake script's package and app attribute";
          type = nonEmptyStr;
        };
        # TODO:
        # commit-lockfile = mkEnableOption "committing any changes";
        # commit-lockfile message?
        #nvd.devShells = mkOption {
        #  default = [];
        #  description = "devShell outputs which the updater script will print diffs for after updating.";
        #  example = ["default"];
        #  type = listOf nonEmptyStr;
        #};
        inputs = mkOption {
          default = null;
          defaultText = "All flake inputs";
          type = nullOr (listOf nonEmptyStr);
          description = "Flake inputs which the updater script will update.";
        };
        before = updatePhaseOption "before";
        after = updatePhaseOption "after";
        program = mkOption {
          description = "Updater script package.";
          type = package;
          internal = true;
          readOnly = true;
          default = pkgs.writeShellApplication {
            name = cfg.name;
            text =
              cfg.before.bash
              + ''
                nix flake ${
                  if cfg.inputs == null
                  then "update"
                  else (lib.foldl' (command: input: command + " --update-input " + input) "lock ")
                } "$@"
              ''
              + cfg.after.bash;
          };
        };
      };
      config.apps.${cfg.name} = {
        type = "app";
        inherit (cfg) program;
      };
    });
}
