{ vimPlugins, fetchFromGitHub, vimUtils, ... }:

let
  vim-pets = vimUtils.buildVimPlugin {
    name = "vim-pets";
    src = fetchFromGitHub {
      owner = "MeF0504";
      repo = "vim-pets";
      rev = "1b7a7b69166fe1c4313b95a21b92e881c444425e";
      sha256 = "sha256-Ls4gbywHV4iZrCDlA0WoExcNiksGMkkIGSce6x7lpv8=";
    };
  };
in {
  plugins = [
    vim-pets
  ];
}
