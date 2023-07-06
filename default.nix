{ pkgs, lib, vimUtils, vim-full, vimPlugins,
  settings ? [],
... }:
let
  lstToString = lib.lists.foldr (a: b: a + "\n" + b) "";
  settingsDefaults = { plugins = []; rc = ""; };
  getsettingsRC = settings: (settingsDefaults // settings).rc;
  getsettingsPlugins = settings: (settingsDefaults // settings).plugins;
  settingsRC = lstToString (map getsettingsRC settings);
  settingsPlugins = lib.lists.concatMap getsettingsPlugins settings;
in vim-full.customize {
  vimrcConfig.customRC = settingsRC;
  vimrcConfig.packages.myVimPackage.start = settingsPlugins;
}
