{
  description = "A module for standardizing flake updates";

  outputs = _: {
    flakeModules.default = ./flake-module.nix;
  };
}
